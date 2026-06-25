import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../widgets/themed_button.dart';
import '../../widgets/themed_text.dart';

/// Shown instead of the app when Android "Developer options" is enabled.
///
/// Responsive by construction: a centered, width-capped, scrollable column so
/// it renders cleanly from small phones up to tablets without overflow.
class SecurityBlockedScreen extends StatelessWidget {
  const SecurityBlockedScreen({super.key, required this.onRetry});

  /// Re-runs the developer-options check (e.g. after the user disables it).
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.gpp_maybe_outlined,
                      color: AppTheme.errorColor,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLarge),
                  const HeadingMediumText(
                    'Developer Options Detected',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingMedium),
                  const BodyLargeText(
                    'For attendance integrity, this app cannot run while '
                    'Developer options are enabled on your device.',
                    color: AppTheme.textSecondary,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingMedium),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMedium),
                    decoration: BoxDecoration(
                      color: AppTheme.darkElements,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BodyMediumText(
                          'To continue:',
                          color: AppTheme.textPrimary,
                        ),
                        SizedBox(height: AppTheme.spacingSmall),
                        BodyMediumText(
                          '1.  Open Settings → System → Developer options\n'
                          '2.  Turn the toggle OFF\n'
                          '3.  Return here and tap "I\'ve disabled it"',
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLarge),
                  ThemedButton(
                    label: "I've disabled it — Re-check",
                    onPressed: () => onRetry(),
                    icon: Icons.refresh,
                    textColor: AppTheme.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
