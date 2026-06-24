import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../widgets/themed_text.dart';
import 'login_success_screen.dart';
import 'login_failure_screen.dart';

/// Scanning State Screen
///
/// Shows an animated circular progress ring with a live "match %" counter that
/// ticks up from 0% to ~94%, then auto-navigates to success (or failure when
/// [shouldFail] is true).
class ScanningStateScreen extends StatefulWidget {
  const ScanningStateScreen({super.key, this.shouldFail = false});

  /// When true, routes to [LoginFailureScreen] instead of success.
  final bool shouldFail;

  @override
  State<ScanningStateScreen> createState() => _ScanningStateScreenState();
}

class _ScanningStateScreenState extends State<ScanningStateScreen>
    with SingleTickerProviderStateMixin {
  static const int _targetMatch = 94;
  static const Duration _scanDuration = Duration(milliseconds: 2500);

  late final AnimationController _controller;
  Timer? _navTimer;
  int _matchPercent = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _scanDuration)
      ..addListener(() {
        final next = (_controller.value * _targetMatch).round();
        if (next != _matchPercent) {
          setState(() => _matchPercent = next);
        }
      })
      ..forward();

    _navTimer = Timer(_scanDuration, _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => widget.shouldFail
            ? const LoginFailureScreen()
            : const LoginSuccessScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        return SizedBox(
                          width: 200,
                          height: 200,
                          child: CircularProgressIndicator(
                            value: _controller.value,
                            strokeWidth: 8,
                            backgroundColor: AppTheme.darkElements,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor,
                            ),
                          ),
                        );
                      },
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DisplayLargeText(
                          '$_matchPercent%',
                          color: AppTheme.textPrimary,
                        ),
                        const SizedBox(height: AppTheme.spacingXSmall),
                        const LabelText(
                          'MATCH',
                          color: AppTheme.textSecondary,
                          isSmall: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingXLarge),
              const HeadingMediumText('Comparing biometrics...'),
              const SizedBox(height: AppTheme.spacingSmall),
              const BodyMediumText(
                'Matching your face against the secure template',
                color: AppTheme.textSecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: AppTheme.spacingXSmall),
                  BodySmallText(
                    'Encrypted on-device',
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
