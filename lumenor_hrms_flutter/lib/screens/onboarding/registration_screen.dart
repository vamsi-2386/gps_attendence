import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_theme.dart';
import '../../models/employee_registration.dart';
import '../../services/hrms_repository.dart';
import '../../utils/validators.dart';
import '../../widgets/themed_button.dart';
import '../../widgets/themed_text.dart';
import 'face_enrollment_screen.dart';

/// Employee Registration Screen
///
/// Collects every onboarding detail up front. The invite code resolves the
/// company (and its assignable sites) from Supabase; the rest are entered by
/// the admin/company portal. Continue proceeds to face enrollment, carrying an
/// [EmployeeRegistration] forward to the confirmation + create step.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _inviteCode = TextEditingController();
  final _fullName = TextEditingController();
  final _employeeCode = TextEditingController();
  final _designation = TextEditingController();
  final _companyName = TextEditingController();
  final _dailyRate = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();

  // Resolved from the invite code.
  int? _companyId;
  bool _resolvingCompany = false;
  String? _companyError;
  List<Map<String, dynamic>> _sites = [];
  int? _selectedSiteId;

  @override
  void dispose() {
    for (final c in [
      _inviteCode,
      _fullName,
      _employeeCode,
      _designation,
      _companyName,
      _dailyRate,
      _mobile,
      _email,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _resolveCompany() async {
    final code = _inviteCode.text.trim().toUpperCase();
    if (Validators.validateInviteCode(code) != null) {
      setState(() => _companyError = 'Enter a valid invite code first.');
      return;
    }
    setState(() {
      _resolvingCompany = true;
      _companyError = null;
    });
    try {
      final company = await HrmsRepository.instance.companyByInviteCode(code);
      if (company == null) {
        setState(() {
          _companyError = 'No company found for that invite code.';
          _companyId = null;
          _sites = [];
          _selectedSiteId = null;
        });
        return;
      }
      final companyId = company['id'] as int;
      // Assigned site = a company office (the geofence the employee will use).
      final sites = await HrmsRepository.instance.offices(companyId);
      if (!mounted) return;
      setState(() {
        _companyId = companyId;
        _companyName.text = (company['name'] ?? '').toString();
        _sites = sites;
        _selectedSiteId = sites.isNotEmpty ? sites.first['id'] as int : null;
      });
    } on SocketException {
      if (!mounted) return;
      setState(() => _companyError =
          'No internet connection. Check your network and try again.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _companyError = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _resolvingCompany = false);
    }
  }

  /// Map common backend/network failures to a readable message.
  String _friendlyError(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('failed host lookup') ||
        s.contains('socketexception') ||
        s.contains('network is unreachable') ||
        s.contains('connection refused') ||
        s.contains('timed out')) {
      return 'Cannot reach the server. Check your internet connection.';
    }
    return 'Lookup failed: $e';
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    if (_companyId == null) {
      setState(() => _companyError = 'Validate the invite code first.');
      return;
    }
    if (_selectedSiteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an assigned site (office).')),
      );
      return;
    }

    final site = _sites.firstWhere((s) => s['id'] == _selectedSiteId);
    final reg = EmployeeRegistration(
      inviteCode: _inviteCode.text.trim().toUpperCase(),
      fullName: _fullName.text.trim(),
      employeeCode: _employeeCode.text.trim(),
      designation: _designation.text.trim(),
      companyName: _companyName.text.trim(),
      dailyRate: double.tryParse(_dailyRate.text.trim()) ?? 0,
      mobile: _mobile.text.trim(),
      email: _email.text.trim(),
      companyId: _companyId,
      officeId: _selectedSiteId,
      officeName: (site['office_name'] ?? '').toString(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FaceEnrollmentScreen(registration: reg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(title: const HeadingMediumText('Employee Registration')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BodyLargeText(
                  'Enter the employee details to register. The invite code links '
                  'this profile to your company and its sites.',
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(height: AppTheme.spacingLarge),

                // Invite code + validate.
                _field(
                  controller: _inviteCode,
                  label: 'Company Invite Code',
                  hint: 'e.g., LUMN24',
                  icon: Icons.vpn_key_outlined,
                  capsUpper: true,
                  validator: Validators.validateInviteCode,
                ),
                const SizedBox(height: AppTheme.spacingSmall),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 160,
                    child: ThemedButton(
                      label: _companyId != null ? 'Validated' : 'Validate code',
                      onPressed: _resolveCompany,
                      isLoading: _resolvingCompany,
                      height: 42,
                      icon: _companyId != null
                          ? Icons.check_circle
                          : Icons.search,
                      backgroundColor: _companyId != null
                          ? AppTheme.successColor
                          : AppTheme.primaryColor,
                    ),
                  ),
                ),
                if (_companyError != null) ...[
                  const SizedBox(height: AppTheme.spacingXSmall),
                  BodySmallText(_companyError!, color: AppTheme.errorColor),
                ],
                const SizedBox(height: AppTheme.spacingMedium),

                _field(
                  controller: _fullName,
                  label: 'Full Name',
                  hint: 'e.g., Priya Sharma',
                  icon: Icons.badge_outlined,
                  validator: Validators.validateName,
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                _field(
                  controller: _employeeCode,
                  label: 'Employee Code',
                  hint: 'e.g., EMP-1042',
                  icon: Icons.tag,
                  capsUpper: true,
                  validator: Validators.validateEmployeeId,
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                _field(
                  controller: _designation,
                  label: 'Designation',
                  hint: 'e.g., Site Supervisor',
                  icon: Icons.work_outline,
                  validator: Validators.validateRequired,
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                _field(
                  controller: _companyName,
                  label: 'Company Name',
                  hint: 'Auto-filled from invite code',
                  icon: Icons.apartment_outlined,
                  validator: Validators.validateRequired,
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                _siteDropdown(),
                const SizedBox(height: AppTheme.spacingMedium),
                _field(
                  controller: _dailyRate,
                  label: 'Daily Rate (₹)',
                  hint: 'e.g., 1850',
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  validator: Validators.validateNumeric,
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                _field(
                  controller: _mobile,
                  label: 'Mobile Number',
                  hint: 'e.g., +91 98765 43210',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhoneNumber,
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                _field(
                  controller: _email,
                  label: 'Email',
                  hint: 'e.g., priya@company.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: AppTheme.spacingLarge),
                ThemedButton(
                  label: 'Continue to Face Enrollment',
                  onPressed: _continue,
                  icon: Icons.camera_alt_outlined,
                ),
                const SizedBox(height: AppTheme.spacingLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool capsUpper = false,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization:
          capsUpper ? TextCapitalization.characters : TextCapitalization.words,
      style: AppTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _siteDropdown() {
    return DropdownButtonFormField<int>(
      initialValue: _selectedSiteId,
      isExpanded: true,
      style: AppTheme.bodyLarge,
      dropdownColor: AppTheme.darkElements,
      decoration: const InputDecoration(
        labelText: 'Assigned Site',
        prefixIcon:
            Icon(Icons.location_on_outlined, color: AppTheme.textSecondary),
      ),
      hint: BodyMediumText(
        _companyId == null ? 'Validate invite code first' : 'Select a site',
        color: AppTheme.textSecondary,
      ),
      items: _sites
          .map(
            (s) => DropdownMenuItem<int>(
              value: s['id'] as int,
              child: Text(
                (s['office_name'] ?? '').toString(),
                style: AppTheme.bodyLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: _sites.isEmpty
          ? null
          : (v) => setState(() => _selectedSiteId = v),
      validator: (v) => v == null ? 'Select an assigned site' : null,
    );
  }
}
