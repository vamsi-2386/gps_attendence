import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_theme.dart';
import '../../services/app_session.dart';
import '../../services/geofence_service.dart';
import '../../services/hrms_repository.dart';
import '../../widgets/themed_button.dart';
import '../../widgets/themed_card.dart';
import '../../widgets/themed_text.dart';

/// Admin Site Management
///
/// Create and manage company **offices** (geofenced work sites) — name,
/// latitude, longitude, radius (m). Persists to Supabase `offices` (the same
/// table employees are geofenced against). "Use current location" fills
/// coordinates from real device GPS.
class SiteManagementScreen extends StatefulWidget {
  const SiteManagementScreen({super.key});

  @override
  State<SiteManagementScreen> createState() => _SiteManagementScreenState();
}

class _SiteManagementScreenState extends State<SiteManagementScreen> {
  late Future<List<Map<String, dynamic>>> _officesFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _officesFuture =
        HrmsRepository.instance.offices(AppSession.instance.companyId);
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _officesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(title: const HeadingMediumText('Site Management')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_location_alt, color: AppTheme.white),
        label: const Text('Add Office', style: TextStyle(color: AppTheme.white)),
        onPressed: () => _openEditor(),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _officesFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return _message(
                  'Could not load offices: ${snap.error}', Icons.error_outline);
            }
            final offices = snap.data ?? const [];
            if (offices.isEmpty) {
              return _message('No offices yet. Tap "Add Office" to create one.',
                  Icons.location_off_outlined);
            }
            return ListView(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              children: offices.map(_officeCard).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _message(String text, IconData icon) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(icon, size: 56, color: AppTheme.textSecondary),
        const SizedBox(height: AppTheme.spacingMedium),
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          child: BodyMediumText(text,
              color: AppTheme.textSecondary, textAlign: TextAlign.center),
        ),
      ],
    );
  }

  Widget _officeCard(Map<String, dynamic> office) {
    final lat = (office['latitude'] as num?)?.toDouble();
    final lng = (office['longitude'] as num?)?.toDouble();
    final radius = (office['radius'] as num?)?.toInt();
    final bool configured = lat != null && lng != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
      child: ThemedCard(
        backgroundColor: AppTheme.darkElements,
        borderColor: AppTheme.borders,
        borderWidth: 0.5,
        shadow: const [],
        onTap: () => _openEditor(office: office),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (configured ? AppTheme.successColor : AppTheme.warningColor)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(Icons.place,
                  color:
                      configured ? AppTheme.successColor : AppTheme.warningColor),
            ),
            const SizedBox(width: AppTheme.spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BodyLargeText((office['office_name'] ?? '').toString(),
                      fontWeight: FontWeight.w600),
                  const SizedBox(height: 2),
                  BodySmallText(
                    configured
                        ? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}  •  ${radius ?? 200} m'
                        : 'Geofence not set — tap to configure',
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_outlined, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor({Map<String, dynamic>? office}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkBackground,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      ),
      builder: (_) => _OfficeEditor(office: office),
    );
    if (saved == true) await _refresh();
  }
}

/// Add/edit form for a single office, shown as a bottom sheet.
class _OfficeEditor extends StatefulWidget {
  const _OfficeEditor({this.office});
  final Map<String, dynamic>? office;

  @override
  State<_OfficeEditor> createState() => _OfficeEditorState();
}

class _OfficeEditorState extends State<_OfficeEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  late final TextEditingController _radius;
  bool _saving = false;
  bool _locating = false;

  bool get _isEdit => widget.office != null;

  @override
  void initState() {
    super.initState();
    final o = widget.office;
    _name = TextEditingController(text: (o?['office_name'] ?? '').toString());
    _lat = TextEditingController(
        text: o?['latitude'] != null ? '${o!['latitude']}' : '');
    _lng = TextEditingController(
        text: o?['longitude'] != null ? '${o!['longitude']}' : '');
    _radius =
        TextEditingController(text: '${(o?['radius'] as num?)?.toInt() ?? 100}');
  }

  @override
  void dispose() {
    for (final c in [_name, _lat, _lng, _radius]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final pos = await GeofenceService.currentPosition();
      _lat.text = pos.latitude.toStringAsFixed(6);
      _lng.text = pos.longitude.toStringAsFixed(6);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not read GPS. Enable Location.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = HrmsRepository.instance;
    final lat = double.parse(_lat.text.trim());
    final lng = double.parse(_lng.text.trim());
    final radius = int.parse(_radius.text.trim());
    try {
      if (_isEdit) {
        await repo.updateOffice(
          officeId: widget.office!['id'] as int,
          officeName: _name.text.trim(),
          latitude: lat,
          longitude: lng,
          radius: radius,
        );
      } else {
        await repo.createOffice(
          companyId: AppSession.instance.companyId,
          officeName: _name.text.trim(),
          latitude: lat,
          longitude: lng,
          radius: radius,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingMedium,
        right: AppTheme.spacingMedium,
        top: AppTheme.spacingMedium,
        bottom: bottom + AppTheme.spacingMedium,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: HeadingMediumText(_isEdit ? 'Edit Office' : 'New Office'),
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              _field(_name, 'Office Name', Icons.business_outlined,
                  validator: _required),
              const SizedBox(height: AppTheme.spacingMedium),
              Row(
                children: [
                  Expanded(
                    child: _field(_lat, 'Latitude', Icons.my_location,
                        keyboard: true, validator: _num),
                  ),
                  const SizedBox(width: AppTheme.spacingSmall),
                  Expanded(
                    child: _field(_lng, 'Longitude', Icons.my_location,
                        keyboard: true, validator: _num),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              ThemedOutlineButton(
                label: 'Use current location',
                icon: Icons.gps_fixed,
                onPressed: _locating ? () {} : _useCurrentLocation,
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              _field(_radius, 'Geofence Radius (meters)',
                  Icons.radio_button_checked,
                  keyboard: true, validator: _intVal),
              const SizedBox(height: AppTheme.spacingLarge),
              ThemedButton(
                label: _isEdit ? 'Save Changes' : 'Create Office',
                icon: Icons.check,
                isLoading: _saving,
                backgroundColor: AppTheme.successColor,
                onPressed: _save,
              ),
              const SizedBox(height: AppTheme.spacingSmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {bool keyboard = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      validator: validator,
      style: AppTheme.bodyLarge,
      keyboardType: keyboard
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : TextInputType.text,
      inputFormatters: keyboard
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))]
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary),
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;
  String? _num(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    return double.tryParse(v.trim()) == null ? 'Invalid number' : null;
  }

  String? _intVal(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = int.tryParse(v.trim());
    if (n == null) return 'Invalid';
    if (n < 20) return 'Min 20 m';
    return null;
  }
}
