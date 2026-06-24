import 'dart:io';

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/employee_registration.dart';
import '../../services/hrms_repository.dart';
import '../../services/local_auth_store.dart';
import '../../widgets/themed_text.dart';
import '../../widgets/themed_button.dart';
import '../../widgets/themed_card.dart';
import '../login/face_login_screen.dart';

/// Profile Confirmation Screen
///
/// Shows every registered detail (plus the captured face photo) for review.
/// Confirm creates the employee in Supabase — persisting all fields and the
/// site assignment — then sends the user to the login screen, where they sign
/// in with Employee Code + Face Verification.
///
/// When [registration] is null (e.g. opened standalone) it falls back to demo
/// values and skips the DB write.
class ProfileConfirmationScreen extends StatefulWidget {
  const ProfileConfirmationScreen({super.key, this.registration});

  final EmployeeRegistration? registration;

  @override
  State<ProfileConfirmationScreen> createState() =>
      _ProfileConfirmationScreenState();
}

class _ProfileConfirmationScreenState extends State<ProfileConfirmationScreen> {
  bool _isLoading = false;

  EmployeeRegistration get _reg =>
      widget.registration ??
      EmployeeRegistration(
        inviteCode: 'LUMN24',
        fullName: 'Priya Sharma',
        employeeCode: 'EMP-1042',
        designation: 'Site Supervisor',
        companyName: 'Lumenor Constructions',
        dailyRate: 1850,
        mobile: '+91 98765 43210',
        email: 'priya@lumenor.in',
        subjectName: 'Whitefield Tower - Block A',
      );

  Future<void> _confirm() async {
    setState(() => _isLoading = true);
    final reg = _reg;
    try {
      // Only write to the DB when we have a real, company-linked registration.
      if (widget.registration != null && reg.companyId != null) {
        final employeeId = await HrmsRepository.instance.createEmployee(
          employeeCode: reg.employeeCode,
          name: reg.fullName,
          companyId: reg.companyId!,
          designation: reg.designation,
          dailyRate: reg.dailyRate,
          mobile: reg.mobile,
          email: reg.email,
          officeId: reg.officeId,
        );
        // Mark this device as registered so Role Selection can route returning
        // employees straight to login next time.
        await LocalAuthStore.setRegisteredEmployee(
          employeeCode: reg.employeeCode,
          employeeId: employeeId,
          name: reg.fullName,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Employee created (#$employeeId). You can now log in '
                'with ${reg.employeeCode} + face.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        await Future.delayed(const Duration(milliseconds: 600));
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FaceLoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create employee: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reg = _reg;
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(title: const HeadingMediumText('Confirm Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppTheme.spacingSmall),
              Center(
                child: Column(
                  children: [
                    _avatar(reg.facePhotoPath),
                    const SizedBox(height: AppTheme.spacingMedium),
                    HeadingLargeText(reg.fullName, color: AppTheme.textPrimary),
                    const SizedBox(height: AppTheme.spacingXSmall),
                    BodyMediumText(reg.designation,
                        color: AppTheme.textSecondary),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingLarge),
              const BodyLargeText(
                'Review the registration details before creating the employee.',
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              ThemedCard(
                backgroundColor: AppTheme.darkElements,
                borderColor: AppTheme.borders,
                borderWidth: 1,
                shadow: const [],
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field('Full Name', reg.fullName, Icons.badge_outlined),
                    _divider(),
                    _field('Employee Code', reg.employeeCode, Icons.tag),
                    _divider(),
                    _field('Designation', reg.designation, Icons.work_outline),
                    _divider(),
                    _field('Company', reg.companyName, Icons.apartment_outlined),
                    _divider(),
                    _field('Assigned Site', reg.officeName ?? reg.subjectName ?? '—',
                        Icons.location_on_outlined),
                    _divider(),
                    _field('Daily Rate', '₹${reg.dailyRate.toStringAsFixed(0)}',
                        Icons.payments_outlined),
                    _divider(),
                    _field('Mobile Number', reg.mobile, Icons.phone_outlined),
                    _divider(),
                    _field('Email', reg.email, Icons.email_outlined),
                    _divider(),
                    _field(
                      'Face Enrollment',
                      reg.facePhotoPath != null ? 'Captured ✓' : 'Pending',
                      Icons.face_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingLarge),
              ThemedButton(
                label: 'Confirm & Create Employee',
                onPressed: _confirm,
                isLoading: _isLoading,
                icon: Icons.check,
                backgroundColor: AppTheme.successColor,
              ),
              const SizedBox(height: AppTheme.spacingLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(String? photoPath) {
    if (photoPath != null && File(photoPath).existsSync()) {
      return Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.successColor, width: 2),
          image: DecorationImage(
            image: FileImage(File(photoPath)),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primaryColor, width: 2),
      ),
      child: const Icon(Icons.person, color: AppTheme.primaryColor, size: 44),
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
        child: Divider(color: AppTheme.borders, height: 1),
      );

  Widget _field(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: AppTheme.textSecondary, size: 22),
        const SizedBox(width: AppTheme.spacingMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabelText(label, isSmall: true, color: AppTheme.textSecondary),
              const SizedBox(height: AppTheme.spacingXSmall),
              BodyMediumText(value, color: AppTheme.textPrimary),
            ],
          ),
        ),
      ],
    );
  }
}
