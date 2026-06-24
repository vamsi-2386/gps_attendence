import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../widgets/themed_text.dart';
import '../../widgets/themed_button.dart';
import '../../widgets/themed_card.dart';
import 'employee_home_screen.dart';

/// Check-In Success Screen
///
/// Confirmation screen shown after a successful check-in. Displays a green
/// check, the check-in time, the verified geofence zone, the face-match
/// score and a Done button that returns to the home dashboard.
class CheckInSuccessScreen extends StatelessWidget {
  final String checkInTime;
  final String zoneName;
  final double matchScore;

  const CheckInSuccessScreen({
    super.key,
    this.checkInTime = '9:04 AM',
    this.zoneName = 'HQ - Skyline Tower',
    this.matchScore = 98.0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppTheme.successColor,
                  size: 80,
                ),
              ),
              const SizedBox(height: AppTheme.spacingLarge),
              const HeadingLargeText('Checked In', textAlign: TextAlign.center),
              const SizedBox(height: AppTheme.spacingXSmall),
              BodyLargeText(
                'Checked in at $checkInTime',
                color: AppTheme.textSecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingLarge),
              _detailCard(),
              const Spacer(),
              ThemedButton(
                label: 'Done',
                icon: Icons.home_outlined,
                height: 56,
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EmployeeHomeScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailCard() {
    return ThemedCard(
      backgroundColor: AppTheme.darkElements,
      borderColor: AppTheme.borders,
      borderWidth: 0.5,
      shadow: const [],
      child: Column(
        children: [
          _detailRow(
            icon: Icons.access_time,
            label: 'Time',
            value: checkInTime,
            valueColor: AppTheme.textPrimary,
          ),
          const Divider(height: AppTheme.spacingLarge, color: AppTheme.borders),
          _detailRow(
            icon: Icons.location_on,
            label: 'Zone',
            value: zoneName,
            valueColor: AppTheme.successColor,
          ),
          const Divider(height: AppTheme.spacingLarge, color: AppTheme.borders),
          _detailRow(
            icon: Icons.verified_user,
            label: 'Face Match',
            value: '${matchScore.toStringAsFixed(0)}%',
            valueColor: AppTheme.successColor,
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: AppTheme.spacingMedium),
        Expanded(
          child: BodyMediumText(label, color: AppTheme.textSecondary),
        ),
        BodyMediumText(value, color: valueColor, fontWeight: FontWeight.w600),
      ],
    );
  }
}
