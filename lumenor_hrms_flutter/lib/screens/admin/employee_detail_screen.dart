import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../widgets/themed_text.dart';
import '../../widgets/themed_button.dart';
import '../../widgets/themed_card.dart';

/// Employee Detail Screen
///
/// Admin-facing employee profile showing biometric health, quick stats and
/// re-enrollment actions. Self-contained with mock HRMS data so it renders
/// standalone for testing.
class EmployeeDetailScreen extends StatelessWidget {
  final String name;
  final String designation;
  final String employeeCode;
  final double avgFaceScore;
  final int totalFailures;
  final String lastEnrollment;
  final double attendanceRate;
  final int leavesTaken;

  const EmployeeDetailScreen({
    super.key,
    this.name = 'Priya Sharma',
    this.designation = 'Senior Site Engineer',
    this.employeeCode = 'EMP-0481',
    this.avgFaceScore = 0.89,
    this.totalFailures = 3,
    this.lastEnrollment = '12 Mar 2026',
    this.attendanceRate = 0.94,
    this.leavesTaken = 6,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const HeadingMediumText('Employee Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        children: [
          _profileHeader(),
          const SizedBox(height: AppTheme.spacingLarge),
          _biometricHealthCard(),
          const SizedBox(height: AppTheme.spacingMedium),
          _quickStats(),
          const SizedBox(height: AppTheme.spacingLarge),
          ThemedButton(
            label: 'Generate re-enrollment link',
            icon: Icons.link,
            backgroundColor: AppTheme.infoColor,
            onPressed: () => _showReenrollLink(context),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          ThemedOutlineButton(
            label: 'Back to dashboard',
            icon: Icons.arrow_back,
            borderColor: AppTheme.infoColor,
            textColor: AppTheme.infoColor,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: AppTheme.spacingLarge),
        ],
      ),
    );
  }

  Widget _profileHeader() {
    return ThemedCard(
      backgroundColor: AppTheme.darkElements,
      borderColor: AppTheme.borders,
      borderWidth: 0.5,
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.infoColor, width: 2),
            ),
            alignment: Alignment.center,
            child: HeadingLargeText(_initials, color: AppTheme.infoColor),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          HeadingLargeText(name, textAlign: TextAlign.center),
          const SizedBox(height: AppTheme.spacingXSmall),
          BodyMediumText(designation, color: AppTheme.textSecondary),
          const SizedBox(height: AppTheme.spacingSmall),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMedium,
              vertical: AppTheme.spacingXSmall,
            ),
            decoration: BoxDecoration(
              color: AppTheme.darkBackground,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(color: AppTheme.borders, width: 0.5),
            ),
            child: LabelText(employeeCode, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _biometricHealthCard() {
    return ThemedCard(
      backgroundColor: AppTheme.darkElements,
      borderColor: AppTheme.borders,
      borderWidth: 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.face_retouching_natural,
                  color: AppTheme.infoColor, size: 20),
              SizedBox(width: AppTheme.spacingSmall),
              HeadingMediumText('Biometric Health'),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const BodyMediumText('Average face match score'),
              BodyLargeText(
                avgFaceScore.toStringAsFixed(2),
                color: _scoreColor(avgFaceScore),
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            child: LinearProgressIndicator(
              value: avgFaceScore.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppTheme.darkBackground,
              valueColor:
                  AlwaysStoppedAnimation<Color>(_scoreColor(avgFaceScore)),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          const Divider(color: AppTheme.borders, height: 1),
          const SizedBox(height: AppTheme.spacingMedium),
          _detailRow(
            icon: Icons.error_outline,
            iconColor: totalFailures > 0
                ? AppTheme.warningColor
                : AppTheme.successColor,
            label: 'Total verification failures',
            value: '$totalFailures',
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          _detailRow(
            icon: Icons.event_available,
            iconColor: AppTheme.infoColor,
            label: 'Last enrollment',
            value: lastEnrollment,
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: AppTheme.spacingSmall),
        Expanded(child: BodyMediumText(label, color: AppTheme.textSecondary)),
        BodyMediumText(value, fontWeight: FontWeight.w600),
      ],
    );
  }

  Widget _quickStats() {
    return Row(
      children: [
        Expanded(
          child: _statTile(
            icon: Icons.check_circle_outline,
            accent: AppTheme.successColor,
            value: '${(attendanceRate * 100).round()}%',
            label: 'Attendance rate',
          ),
        ),
        const SizedBox(width: AppTheme.spacingMedium),
        Expanded(
          child: _statTile(
            icon: Icons.beach_access,
            accent: AppTheme.infoColor,
            value: '$leavesTaken',
            label: 'Leaves taken',
          ),
        ),
      ],
    );
  }

  Widget _statTile({
    required IconData icon,
    required Color accent,
    required String value,
    required String label,
  }) {
    return ThemedCard(
      backgroundColor: AppTheme.darkElements,
      borderColor: AppTheme.borders,
      borderWidth: 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(height: AppTheme.spacingSmall),
          DisplayMediumText(value, color: accent),
          const SizedBox(height: AppTheme.spacingXSmall),
          BodySmallText(label, color: AppTheme.textSecondary),
        ],
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 0.75) return AppTheme.successColor;
    if (score >= 0.5) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  void _showReenrollLink(BuildContext context) {
    final link =
        'https://hrms.lumenor.in/reenroll/$employeeCode?t=a1b2c3d4';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.darkElements,
          duration: const Duration(seconds: 4),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BodyMediumText(
                'Re-enrollment link generated',
                color: AppTheme.successColor,
              ),
              const SizedBox(height: AppTheme.spacingXSmall),
              BodySmallText(link, color: AppTheme.textPrimary),
            ],
          ),
        ),
      );
  }
}
