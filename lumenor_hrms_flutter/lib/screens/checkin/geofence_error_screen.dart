import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../widgets/themed_text.dart';
import '../../widgets/themed_button.dart';

/// Geofence Error Screen
///
/// Shown when an employee tries to check in from outside the office geofence.
/// Surfaces the distance to the boundary and offers a manager-override path.
class GeofenceErrorScreen extends StatelessWidget {
  final double distanceMeters;
  final String officeName;

  const GeofenceErrorScreen({
    super.key,
    this.distanceMeters = 1240,
    this.officeName = 'Lumenor HQ',
  });

  String get _distanceLabel => distanceMeters >= 1000
      ? '${(distanceMeters / 1000).toStringAsFixed(1)} km'
      : '${distanceMeters.toStringAsFixed(0)} m';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(title: const HeadingMediumText('Location Check')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Map placeholder with boundary + user pin
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.darkElements,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(color: AppTheme.borders, width: 0.5),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Geofence circle
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.successColor.withValues(alpha: 0.10),
                          border: Border.all(
                            color: AppTheme.successColor.withValues(alpha: 0.6),
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.business,
                              color: AppTheme.successColor, size: 32),
                        ),
                      ),
                      // User pin, offset outside the circle
                      Positioned(
                        right: 40,
                        top: 40,
                        child: Column(
                          children: [
                            const Icon(Icons.location_on,
                                color: AppTheme.errorColor, size: 40),
                            BodySmallText('You', color: AppTheme.errorColor),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingLarge),
              Row(
                children: [
                  const Icon(Icons.location_off,
                      color: AppTheme.errorColor, size: 28),
                  const SizedBox(width: AppTheme.spacingSmall),
                  Expanded(
                    child: HeadingMediumText(
                      'You are $_distanceLabel outside $officeName',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              BodyMediumText(
                'Check-in is only allowed inside the office geofence. Move closer, '
                'or request a manager override if you are on approved field work.',
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: AppTheme.spacingLarge),
              ThemedButton(
                label: 'Request manager override',
                icon: Icons.shield_outlined,
                backgroundColor: AppTheme.warningColor,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Override request sent to your manager'),
                    ),
                  );
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              ThemedOutlineButton(
                label: 'Retry location',
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
            ],
          ),
        ),
      ),
    );
  }
}
