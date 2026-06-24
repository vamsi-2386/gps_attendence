import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../widgets/themed_text.dart';
import '../../widgets/themed_button.dart';
import '../../widgets/themed_card.dart';
import 'checkin_success_screen.dart';

/// Check-In Screen
///
/// Shows a map miniature with the office pin, the live GPS coordinate
/// readout, a compact face-verification prompt and a confirm button that
/// replaces the route with the success screen.
class CheckInScreen extends StatefulWidget {
  final String siteName;
  final double latitude;
  final double longitude;

  const CheckInScreen({
    super.key,
    this.siteName = 'Skyline Tower',
    this.latitude = 17.385044,
    this.longitude = 78.486671,
  });

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  bool _faceVerified = false;
  bool _verifying = false;

  void _runFaceVerify() async {
    setState(() => _verifying = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _verifying = false;
      _faceVerified = true;
    });
  }

  void _confirmCheckIn() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CheckInSuccessScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkElements,
        elevation: 0,
        title: const HeadingMediumText('Check In'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        children: [
          _mapMiniature(),
          const SizedBox(height: AppTheme.spacingMedium),
          _coordsCard(),
          const SizedBox(height: AppTheme.spacingMedium),
          _faceVerifyCard(),
          const SizedBox(height: AppTheme.spacingLarge),
          ThemedButton(
            label: 'Confirm Check-In',
            icon: Icons.check,
            height: 56,
            backgroundColor: AppTheme.successColor,
            isEnabled: _faceVerified,
            onPressed: _confirmCheckIn,
          ),
          if (!_faceVerified) ...[
            const SizedBox(height: AppTheme.spacingSmall),
            BodySmallText(
              'Complete face verification to continue.',
              color: AppTheme.textSecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _mapMiniature() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.darkElements,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.borders, width: 0.5),
      ),
      child: Stack(
        children: [
          // Faux map grid lines.
          Positioned.fill(
            child: CustomPaint(painter: _MapGridPainter()),
          ),
          // Geofence radius ring.
          Center(
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.successColor.withValues(alpha: 0.08),
                border: Border.all(
                  color: AppTheme.successColor.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
            ),
          ),
          // Center pin.
          const Center(
            child: Icon(Icons.location_on, color: AppTheme.errorColor, size: 40),
          ),
          Positioned(
            left: AppTheme.spacingMedium,
            bottom: AppTheme.spacingMedium,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSmall,
                vertical: AppTheme.spacingXSmall,
              ),
              decoration: BoxDecoration(
                color: AppTheme.darkBackground.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: BodySmallText(widget.siteName, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coordsCard() {
    return ThemedCard(
      backgroundColor: AppTheme.darkElements,
      borderColor: AppTheme.borders,
      borderWidth: 0.5,
      shadow: const [],
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: const Icon(Icons.gps_fixed, color: AppTheme.infoColor),
          ),
          const SizedBox(width: AppTheme.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BodySmallText('GPS Coordinates',
                    color: AppTheme.textSecondary),
                const SizedBox(height: 2),
                BodyMediumText(
                  '${widget.latitude.toStringAsFixed(6)}, '
                  '${widget.longitude.toStringAsFixed(6)}',
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.check_circle,
                  color: AppTheme.successColor, size: 18),
              const SizedBox(width: AppTheme.spacingXSmall),
              BodySmallText('±8m', color: AppTheme.successColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _faceVerifyCard() {
    final Color color =
        _faceVerified ? AppTheme.successColor : AppTheme.warningColor;
    return ThemedCard(
      backgroundColor: AppTheme.darkElements,
      borderColor: AppTheme.borders,
      borderWidth: 0.5,
      shadow: const [],
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(
              _faceVerified ? Icons.verified_user : Icons.face_retouching_natural,
              color: color,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BodyMediumText('Face verification',
                    fontWeight: FontWeight.w600),
                const SizedBox(height: 2),
                BodySmallText(
                  _faceVerified ? 'Verified • 98% match' : 'Required before check-in',
                  color: _faceVerified
                      ? AppTheme.successColor
                      : AppTheme.textSecondary,
                ),
              ],
            ),
          ),
          if (!_faceVerified)
            SizedBox(
              width: 96,
              child: ThemedButton(
                label: 'Verify',
                height: 40,
                isLoading: _verifying,
                onPressed: _runFaceVerify,
              ),
            )
          else
            const Icon(Icons.check_circle, color: AppTheme.successColor),
        ],
      ),
    );
  }
}

/// Lightweight grid painter so the map placeholder reads as a map.
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.borders.withValues(alpha: 0.25)
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
