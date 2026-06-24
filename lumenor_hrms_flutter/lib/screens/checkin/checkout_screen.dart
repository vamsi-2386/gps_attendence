import 'dart:async';

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../widgets/themed_text.dart';
import '../../widgets/themed_button.dart';

/// Check-Out Screen
///
/// Shows a live shift duration timer counting up from the check-in time,
/// the day's punch timeline, and a red Clock Out action.
class CheckOutScreen extends StatefulWidget {
  /// Time the employee checked in. Defaults to ~7h ago for a realistic demo.
  final DateTime? checkInTime;

  const CheckOutScreen({super.key, this.checkInTime});

  @override
  State<CheckOutScreen> createState() => _CheckOutScreenState();
}

class _CheckOutScreenState extends State<CheckOutScreen> {
  late final DateTime _checkInTime;
  late Timer _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _checkInTime = widget.checkInTime ??
        DateTime.now().subtract(const Duration(hours: 7, minutes: 22));
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    setState(() => _elapsed = DateTime.now().difference(_checkInTime));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String get _durationLabel {
    final h = _elapsed.inHours;
    final m = _elapsed.inMinutes.remainder(60);
    final s = _elapsed.inSeconds.remainder(60);
    return '${_two(h)}:${_two(m)}:${_two(s)}';
  }

  String _clock(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final ampm = t.hour < 12 ? 'AM' : 'PM';
    return '$hour:${_two(t.minute)} $ampm';
  }

  void _confirmClockOut() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.darkElements,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.logout, color: AppTheme.errorColor, size: 48),
            const SizedBox(height: AppTheme.spacingMedium),
            const HeadingMediumText('Clock out now?'),
            const SizedBox(height: AppTheme.spacingSmall),
            BodyMediumText(
              'Your shift of $_durationLabel will be recorded.',
              color: AppTheme.textSecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            ThemedButton(
              label: 'Confirm Clock Out',
              backgroundColor: AppTheme.errorColor,
              icon: Icons.logout,
              onPressed: () {
                Navigator.pop(sheetCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.successColor,
                    content: Text('Clocked out at ${_clock(DateTime.now())}'),
                  ),
                );
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            ThemedTextButton(
              label: 'Stay clocked in',
              onPressed: () => Navigator.pop(sheetCtx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(title: const HeadingMediumText('Clock Out')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTheme.spacingMedium),
              // Live duration ring
              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingLarge),
                  decoration: BoxDecoration(
                    color: AppTheme.darkElements,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.successColor, width: 3),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LabelText('ON THE CLOCK', color: AppTheme.successColor),
                      const SizedBox(height: AppTheme.spacingSmall),
                      DisplayLargeText(_durationLabel, color: AppTheme.textPrimary),
                      const SizedBox(height: AppTheme.spacingXSmall),
                      BodySmallText(
                        'since ${_clock(_checkInTime)}',
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingLarge),
              const HeadingMediumText("Today's punches"),
              const SizedBox(height: AppTheme.spacingSmall),
              Expanded(
                child: ListView(
                  children: [
                    _punchRow(Icons.login, 'Checked in', _clock(_checkInTime),
                        'HQ — Main Gate', AppTheme.successColor),
                    _punchRow(Icons.free_breakfast, 'Break start', '11:30 AM',
                        'Cafeteria', AppTheme.warningColor),
                    _punchRow(Icons.work_history, 'Break end', '12:05 PM',
                        'HQ — Floor 3', AppTheme.infoColor),
                  ],
                ),
              ),
              ThemedButton(
                label: 'Clock Out',
                backgroundColor: AppTheme.errorColor,
                icon: Icons.logout,
                onPressed: _confirmClockOut,
              ),
              const SizedBox(height: AppTheme.spacingSmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _punchRow(
      IconData icon, String title, String time, String place, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppTheme.darkElements,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.borders, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppTheme.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeadingMediumText(title, fontSize: 15),
                BodySmallText(place, color: AppTheme.textSecondary),
              ],
            ),
          ),
          BodyMediumText(time, color: AppTheme.textPrimary),
        ],
      ),
    );
  }
}
