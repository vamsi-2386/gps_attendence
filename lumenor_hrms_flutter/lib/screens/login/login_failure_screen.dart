import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../widgets/themed_text.dart';
import '../../widgets/themed_button.dart';

/// Login Failure Screen
///
/// Shown when biometric verification fails. Offers a retry path back to the
/// face scan and a PIN fallback.
class LoginFailureScreen extends StatelessWidget {
  const LoginFailureScreen({
    super.key,
    this.failureReason = 'Face not recognized',
  });

  /// Human-readable explanation of why verification failed.
  final String failureReason;

  void _tryAgain(BuildContext context) {
    // Return to the face scan screen to attempt verification again.
    Navigator.pop(context);
  }

  void _usePinInstead(BuildContext context) {
    // Drop back to the previous auth route so the user can enter a PIN.
    Navigator.pop(context);
  }

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
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.errorColor.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppTheme.errorColor.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: AppTheme.errorColor,
                  size: 88,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXLarge),
              const HeadingLargeText(
                'Verification failed',
                color: AppTheme.textPrimary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              BodyMediumText(
                failureReason,
                color: AppTheme.textSecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingLarge),
              _buildTipCard(),
              const Spacer(),
              ThemedButton(
                label: 'Try Again',
                icon: Icons.refresh,
                onPressed: () => _tryAgain(context),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              ThemedTextButton(
                label: 'Use PIN instead',
                icon: Icons.dialpad,
                onPressed: () => _usePinInstead(context),
                textColor: AppTheme.textSecondary,
              ),
              const SizedBox(height: AppTheme.spacingSmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppTheme.darkElements,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.borders, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: AppTheme.warningColor,
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacingSmall),
          const Expanded(
            child: BodySmallText(
              'Find a well-lit spot, remove glasses or masks, and keep your '
              'face centred in the frame.',
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
