import 'dart:io';

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/hrms_repository.dart';
import '../../services/local_auth_store.dart';
import '../../widgets/themed_text.dart';
import '../../widgets/themed_button.dart';
import '../admin/admin_overview_screen.dart';
import '../login/face_login_screen.dart';
import 'registration_screen.dart';

/// Role Selection Screen
///
/// Allows users to select their role during onboarding. Acts as the
/// reference screen for the onboarding flow: dark theme, themed widgets,
/// and direct [MaterialPageRoute] navigation.
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? selectedRole;
  bool _checking = false;

  Future<void> _onContinue() async {
    if (selectedRole == null || _checking) return;

    // Manager and HR Admin go to the admin dashboard (team overview, leave
    // approvals, HR review / flagged-events override, site management).
    if (selectedRole != 'employee') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminOverviewScreen()),
      );
      return;
    }

    // Employee: check registration status on this device (and confirm with
    // Supabase when reachable), then route to login or registration.
    setState(() => _checking = true);
    try {
      final code = await LocalAuthStore.registeredEmployeeCode();
      bool registered = code != null;

      if (registered) {
        try {
          final emp = await HrmsRepository.instance.employeeByCode(code);
          if (emp == null) {
            // Record removed server-side → fall back to registration.
            await LocalAuthStore.clear();
            registered = false;
          }
        } on SocketException {
          // Offline but locally registered → allow login.
        } catch (_) {
          // Other backend errors → trust the local marker and proceed to login.
        }
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              registered ? const FaceLoginScreen() : const RegistrationScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not check registration: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const HeadingMediumText('Select Your Role'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                children: [
                  const BodyLargeText(
                    'Choose your role to get started',
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: AppTheme.spacingLarge),
                  _roleCard(
                    role: 'employee',
                    title: 'Employee',
                    description: 'Attendance and leave management',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: AppTheme.spacingMedium),
                  _roleCard(
                    role: 'manager',
                    title: 'Manager',
                    description: 'Team oversight and approvals',
                    icon: Icons.groups_outlined,
                  ),
                  const SizedBox(height: AppTheme.spacingMedium),
                  _roleCard(
                    role: 'hr',
                    title: 'HR Admin',
                    description: 'Payroll and employee management',
                    icon: Icons.admin_panel_settings_outlined,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: ThemedButton(
                label: 'Continue',
                onPressed: _onContinue,
                isEnabled: selectedRole != null && !_checking,
                isLoading: _checking,
                icon: Icons.arrow_forward,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleCard({
    required String role,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = selectedRole == role;

    return GestureDetector(
      onTap: () => setState(() => selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.12)
              : AppTheme.darkElements,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borders,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 28),
            ),
            const SizedBox(width: AppTheme.spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HeadingMediumText(title, color: AppTheme.textPrimary),
                  const SizedBox(height: AppTheme.spacingXSmall),
                  BodySmallText(description, color: AppTheme.textSecondary),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color:
                  isSelected ? AppTheme.successColor : AppTheme.textSecondary,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
