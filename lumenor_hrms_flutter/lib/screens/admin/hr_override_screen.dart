import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../services/app_session.dart';
import '../../services/hrms_repository.dart';
import '../../widgets/themed_text.dart';
import '../../widgets/themed_button.dart';
import '../../widgets/themed_card.dart';

/// HR Override / Flagged Events Screen
///
/// Live HR-review queue for attendance flagged as outside the geofence. HR/Admin
/// can Approve (marks the record Present) or Reject (keeps it flagged / not
/// present). Both actions sync to Supabase, so the company dashboard and the
/// employee dashboard reflect the decision immediately.
class HROverrideScreen extends StatefulWidget {
  const HROverrideScreen({super.key});

  @override
  State<HROverrideScreen> createState() => _HROverrideScreenState();
}

class _HROverrideScreenState extends State<HROverrideScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _records = const [];
  Map<int, String> _names = const {};
  final Set<int> _busy = {}; // attendance ids currently being resolved

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final companyId = AppSession.instance.companyId;
      final records =
          await HrmsRepository.instance.flaggedAttendance(companyId);
      final names = await HrmsRepository.instance.employeeNames(companyId);
      if (!mounted) return;
      setState(() {
        _records = records;
        _names = names;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load flagged records: $e';
        _loading = false;
      });
    }
  }

  Future<void> _resolve(Map<String, dynamic> rec, bool approved) async {
    final id = rec['id'] as int;
    setState(() => _busy.add(id));
    try {
      await HrmsRepository.instance.reviewFlaggedAttendance(id, approved);
      if (!mounted) return;
      setState(() => _records = _records.where((r) => r['id'] != id).toList());
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor:
                approved ? AppTheme.successColor : AppTheme.errorColor,
            content: Text(approved
                ? 'Approved — marked Present for ${_nameFor(rec)}'
                : 'Rejected — kept flagged for ${_nameFor(rec)}'),
          ),
        );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Action failed: $e'),
            backgroundColor: AppTheme.errorColor),
      );
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  String _nameFor(Map<String, dynamic> rec) {
    final n = (rec['employee_name'] ?? '').toString();
    if (n.isNotEmpty) return n;
    final id = rec['employee_id'] as int?;
    return (id != null ? _names[id] : null) ?? 'Employee #${id ?? '?'}';
  }

  String _timeFor(Map<String, dynamic> rec) {
    final dt = DateTime.tryParse(
            '${rec['check_in_time'] ?? rec['timestamp'] ?? ''}')
        ?.toLocal();
    return dt == null ? '—' : DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const HeadingMediumText('Flagged Events & HR Review'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textPrimary),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _message(_error!, Icons.error_outline)
              : _records.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppTheme.spacingMedium),
                        itemCount: _records.length + 1,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppTheme.spacingMedium),
                        itemBuilder: (context, i) {
                          if (i == 0) {
                            return BodyMediumText(
                              'Found ${_records.length} record(s) outside the '
                              'geofence requiring HR attention.',
                              color: AppTheme.textSecondary,
                            );
                          }
                          return _card(_records[i - 1]);
                        },
                      ),
                    ),
    );
  }

  Widget _card(Map<String, dynamic> rec) {
    final id = rec['id'] as int;
    final lat = (rec['latitude'] as num?)?.toDouble();
    final lng = (rec['longitude'] as num?)?.toDouble();
    final geofence = '${rec['geofence_status'] ?? 'Outside'}';
    final busy = _busy.contains(id);

    return ThemedCard(
      backgroundColor: AppTheme.darkElements,
      borderColor: AppTheme.warningColor.withValues(alpha: 0.4),
      borderWidth: 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag, color: AppTheme.warningColor, size: 20),
              const SizedBox(width: AppTheme.spacingSmall),
              Expanded(child: HeadingMediumText(_nameFor(rec))),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXSmall),
          BodySmallText(_timeFor(rec), color: AppTheme.textSecondary),
          const SizedBox(height: AppTheme.spacingMedium),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingSmall),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_off,
                    color: AppTheme.errorColor, size: 18),
                const SizedBox(width: AppTheme.spacingSmall),
                Expanded(
                  child: BodyMediumText('Geofence: $geofence',
                      color: AppTheme.errorColor),
                ),
              ],
            ),
          ),
          if (lat != null && lng != null) ...[
            const SizedBox(height: AppTheme.spacingSmall),
            Row(
              children: [
                const Icon(Icons.my_location,
                    color: AppTheme.textSecondary, size: 16),
                const SizedBox(width: AppTheme.spacingSmall),
                BodySmallText(
                  '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ],
          const SizedBox(height: AppTheme.spacingMedium),
          Row(
            children: [
              Expanded(
                child: ThemedButton(
                  label: 'Approve',
                  icon: Icons.verified,
                  height: 44,
                  isLoading: busy,
                  backgroundColor: AppTheme.successColor,
                  onPressed: () => _resolve(rec, true),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: ThemedButton(
                  label: 'Reject',
                  icon: Icons.block,
                  height: 44,
                  isEnabled: !busy,
                  backgroundColor: AppTheme.errorColor,
                  onPressed: () => _resolve(rec, false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _message(String text, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 48),
            const SizedBox(height: AppTheme.spacingMedium),
            BodyMediumText(text,
                color: AppTheme.textSecondary, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.spacingLarge),
            SizedBox(
              width: 160,
              child: ThemedOutlineButton(
                label: 'Retry',
                icon: Icons.refresh,
                onPressed: _load,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_user_outlined,
              color: AppTheme.successColor, size: 56),
          const SizedBox(height: AppTheme.spacingMedium),
          const HeadingMediumText('Review queue clear'),
          const SizedBox(height: AppTheme.spacingXSmall),
          const BodyMediumText('No flagged attendance to review',
              color: AppTheme.textSecondary),
          const SizedBox(height: AppTheme.spacingLarge),
          SizedBox(
            width: 220,
            child: ThemedOutlineButton(
              label: 'Back to dashboard',
              icon: Icons.arrow_back,
              borderColor: AppTheme.infoColor,
              textColor: AppTheme.infoColor,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
