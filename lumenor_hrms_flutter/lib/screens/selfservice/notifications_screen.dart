import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../services/app_session.dart';
import '../../services/hrms_repository.dart';
import '../../widgets/themed_text.dart';

/// A single notification item, built from real Supabase rows (leave + attendance).
class _Notif {
  final String id;
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final DateTime when;
  bool unread;

  _Notif({
    required this.id,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.when,
    this.unread = true,
  });
}

/// Notifications Screen
///
/// A REAL, per-employee activity feed derived from the signed-in employee's own
/// leave requests and recent attendance — no mock/placeholder data, so nothing
/// from another person can ever appear here. Supports swipe-to-dismiss and
/// mark-all-read (local view state; there is no notifications table to persist).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static final DateFormat _dayFmt = DateFormat('dd MMM yyyy');

  List<_Notif> _items = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    final empId = AppSession.instance.employeeId;
    try {
      final repo = HrmsRepository.instance;
      final leaves = await repo.employeeLeaves(empId);
      final attendance = await repo.attendanceLogs(empId);
      final now = DateTime.now();
      final items = <_Notif>[];

      for (final l in leaves) {
        final created = DateTime.tryParse('${l['created_at']}')?.toLocal();
        if (created == null) continue;
        final status = (l['status'] ?? 'Pending').toString();
        final span =
            '${_fmtDate(l['start_date'])} – ${_fmtDate(l['end_date'])}';
        late IconData icon;
        late Color color;
        late String title;
        switch (status) {
          case 'Approved':
            icon = Icons.event_available;
            color = AppTheme.successColor;
            title = 'Leave approved';
            break;
          case 'Rejected':
            icon = Icons.event_busy;
            color = AppTheme.errorColor;
            title = 'Leave rejected';
            break;
          default:
            icon = Icons.hourglass_top;
            color = AppTheme.warningColor;
            title = 'Leave request submitted';
        }
        items.add(_Notif(
          id: 'leave-${l['id']}',
          icon: icon,
          color: color,
          title: title,
          body: '$span — ${(l['reason'] ?? '').toString()}',
          when: created,
          unread: now.difference(created).inHours < 24,
        ));
      }

      // Most recent check-ins (cap so the feed stays readable).
      for (final a in attendance.take(8)) {
        final t = DateTime.tryParse(
                '${a['check_in_time'] ?? a['timestamp']}')
            ?.toLocal();
        if (t == null) continue;
        final st = (a['attendance_status'] ?? a['location_status'] ?? '')
            .toString();
        late IconData icon;
        late Color color;
        late String title;
        late String body;
        switch (st) {
          case 'Flagged':
            icon = Icons.gpp_maybe;
            color = AppTheme.warningColor;
            title = 'Check-in flagged';
            body = 'Outside the geofence — pending HR review.';
            break;
          case 'Rejected':
            icon = Icons.cancel;
            color = AppTheme.errorColor;
            title = 'Check-in rejected';
            body = 'HR did not approve this out-of-area check-in.';
            break;
          case 'Present':
          default:
            icon = Icons.my_location;
            color = AppTheme.successColor;
            title = 'Checked in — Present';
            body = 'Clock-in recorded at your assigned site.';
        }
        items.add(_Notif(
          id: 'att-${a['id']}',
          icon: icon,
          color: color,
          title: title,
          body: '$body  (${DateFormat('dd MMM, hh:mm a').format(t)})',
          when: t,
          unread: now.difference(t).inHours < 24,
        ));
      }

      items.sort((a, b) => b.when.compareTo(a.when));
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  String _fmtDate(dynamic raw) {
    final d = DateTime.tryParse('$raw');
    return d != null ? _dayFmt.format(d) : '$raw';
  }

  String _relative(DateTime when) {
    final d = DateTime.now().difference(when);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return _dayFmt.format(when);
  }

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
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }
    if (_error) {
      return _centered(Icons.cloud_off, 'Couldn’t load notifications',
          'Pull down to retry.');
    }
    if (_items.isEmpty) {
      return _centered(Icons.notifications_none, 'You’re all caught up',
          'Leave and attendance updates will appear here.');
    }
    return ListView.builder(
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
            child: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
          ),
          onDismissed: (_) => setState(() => _items.removeAt(i)),
          child: _tile(n),
        );
      },
    );
  }

  Widget _centered(IconData icon, String title, String subtitle) {
    // ListView so RefreshIndicator still works when there is no content.
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(icon, size: 64, color: AppTheme.textSecondary),
        const SizedBox(height: AppTheme.spacingMedium),
        Center(child: BodyLargeText(title)),
        const SizedBox(height: AppTheme.spacingXSmall),
        Center(
          child: BodySmallText(subtitle, color: AppTheme.textSecondary),
        ),
      ],
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
                BodySmallText(_relative(n.when), color: AppTheme.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
