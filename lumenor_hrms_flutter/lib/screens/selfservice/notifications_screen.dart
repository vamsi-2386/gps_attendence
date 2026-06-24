import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../widgets/themed_text.dart';

/// A single notification item (mock model shaped like a real feed entry).
class _Notif {
  final String id;
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String time;
  bool unread;

  _Notif({
    required this.id,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.time,
    this.unread = true,
  });
}

/// Notifications Screen
///
/// Realtime-style feed: geofence entry, leave approvals, missed clock-outs,
/// HR overrides and payslips. Supports swipe-to-dismiss and mark-all-read.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<_Notif> _items = [
    _Notif(
      id: 'n1',
      icon: Icons.my_location,
      color: AppTheme.successColor,
      title: 'Entered HQ geofence',
      body: 'You can now clock in for your shift.',
      time: '2m ago',
    ),
    _Notif(
      id: 'n2',
      icon: Icons.event_available,
      color: AppTheme.infoColor,
      title: 'Leave approved',
      body: 'Your casual leave for Jun 28 was approved by R. Mehta.',
      time: '2h ago',
    ),
    _Notif(
      id: 'n3',
      icon: Icons.timer_off,
      color: AppTheme.warningColor,
      title: 'Missed clock-out',
      body: 'You did not clock out yesterday. Tap to submit a correction.',
      time: '1d ago',
    ),
    _Notif(
      id: 'n4',
      icon: Icons.verified_user,
      color: AppTheme.primaryColor,
      title: 'HR override applied',
      body: 'A flagged check-in on Jun 20 was approved by HR.',
      time: '3d ago',
      unread: false,
    ),
    _Notif(
      id: 'n5',
      icon: Icons.receipt_long,
      color: AppTheme.textSecondary,
      title: 'Payslip ready',
      body: 'Your May payslip is available to download.',
      time: '5d ago',
      unread: false,
    ),
  ];

  void _markAllRead() {
    setState(() {
      for (final n in _items) {
        n.unread = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _items.where((n) => n.unread).length;
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const HeadingMediumText('Notifications'),
        actions: [
          TextButton(
            onPressed: unreadCount == 0 ? null : _markAllRead,
            child: Text(
              'Mark all read',
              style: TextStyle(
                color: unreadCount == 0
                    ? AppTheme.textSecondary
                    : AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
      body: _items.isEmpty
          ? const Center(
              child: BodyLargeText('You are all caught up',
                  color: AppTheme.textSecondary),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final n = _items[i];
                return Dismissible(
                  key: ValueKey(n.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppTheme.spacingLarge),
                    margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: AppTheme.errorColor),
                  ),
                  onDismissed: (_) => setState(() => _items.removeAt(i)),
                  child: _tile(n),
                );
              },
            ),
    );
  }

  Widget _tile(_Notif n) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppTheme.darkElements,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: n.unread
              ? n.color.withValues(alpha: 0.5)
              : AppTheme.borders.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: n.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(n.icon, color: n.color, size: 22),
          ),
          const SizedBox(width: AppTheme.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: HeadingMediumText(n.title, fontSize: 15)),
                    if (n.unread)
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXSmall),
                BodySmallText(n.body, color: AppTheme.textSecondary),
                const SizedBox(height: AppTheme.spacingXSmall),
                BodySmallText(n.time, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
