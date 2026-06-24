import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_theme.dart';
import '../../services/app_session.dart';
import '../../widgets/themed_text.dart';
import '../checkin/employee_home_screen.dart';

/// Login Success Screen
///
/// Confirms a successful biometric match, then routes into the employee
/// dashboard. Attendance is no longer marked here — clock-in/out happens on the
/// dashboard with full GPS geofencing.
class LoginSuccessScreen extends StatefulWidget {
  const LoginSuccessScreen({super.key, this.employeeName});

  /// Optional override; defaults to the signed-in session employee.
  final String? employeeName;

  @override
  State<LoginSuccessScreen> createState() => _LoginSuccessScreenState();
}

class _LoginSuccessScreenState extends State<LoginSuccessScreen> {
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _navTimer = Timer(const Duration(milliseconds: 1600), _goHome);
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const EmployeeHomeScreen()),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.employeeName ?? AppSession.instance.employeeName;
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.successColor.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppTheme.successColor.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.check_circle,
                      color: AppTheme.successColor, size: 88),
                ),
                const SizedBox(height: AppTheme.spacingXLarge),
                const HeadingLargeText(
                  'Welcome back,',
                  color: AppTheme.textSecondary,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingXSmall),
                DisplayMediumText(
                  name,
                  color: AppTheme.textPrimary,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                const BodyMediumText(
                  'Identity verified successfully',
                  color: AppTheme.textSecondary,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
