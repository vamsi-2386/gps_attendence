import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../services/app_session.dart';
import '../../services/hrms_repository.dart';
import '../../widgets/themed_text.dart';

/// Attendance status for a single calendar day.
enum DayStatus { present, absent, leave, halfDay, future }

/// A single punch event shown in the day-detail timeline.
class _PunchEvent {
  final String label;
  final String time;
  final String site;
  final IconData icon;
  final Color color;

  const _PunchEvent({
    required this.label,
    required this.time,
    required this.site,
    required this.icon,
    required this.color,
  });
}

/// Attendance Calendar Screen
///
/// Month grid (7 columns) with color-coded day cells, a month header with
/// prev/next chevrons, a status legend, and a tap-to-open day-detail
/// bottom sheet showing the punch in/out timeline for that day.
class AttendanceCalendarScreen extends StatefulWidget {
  final String employeeName;
  final String subjectName;

  const AttendanceCalendarScreen({
    super.key,
    this.employeeName = 'Priya Sharma',
    this.subjectName = 'Whitefield Site A',
  });

  @override
  State<AttendanceCalendarScreen> createState() =>
      _AttendanceCalendarScreenState();
}

class _AttendanceCalendarScreenState extends State<AttendanceCalendarScreen> {
  // The month currently displayed (day-of-month is irrelevant; we use the 1st).
  late DateTime _visibleMonth;

  // One-shot load of this employee's attendance logs from Supabase. Kept in a
  // field so month navigation (setState) does not re-fire the network call.
  late Future<List<Map<String, dynamic>>> _logsFuture;

  static const List<String> _weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month, 1);
    _logsFuture =
        HrmsRepository.instance.attendanceLogs(AppSession.instance.employeeId);
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth =
          DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1);
    });
  }

  /// Builds a lookup of the latest attendance log per calendar day, keyed by a
  /// midnight DateTime(y, m, d). Logs arrive newest-first, so the first entry
  /// seen for a given day wins.
  Map<DateTime, Map<String, dynamic>> _logsByDay(
      List<Map<String, dynamic>> rows) {
    final map = <DateTime, Map<String, dynamic>>{};
    for (final row in rows) {
      final ts = DateTime.tryParse('${row['timestamp']}');
      if (ts == null) continue;
      final key = DateTime(ts.year, ts.month, ts.day);
      map.putIfAbsent(key, () => row);
    }
    return map;
  }

  /// Deterministic mock status so the grid renders standalone for testing.
  /// Used as the graceful fallback when live logs are unavailable.
  DayStatus _statusForDay(int day) {
    final candidate = DateTime(_visibleMonth.year, _visibleMonth.month, day);
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);

    if (candidate.isAfter(todayMidnight)) {
      return DayStatus.future;
    }
    // Weekends rendered as "future"/empty (non-working days).
    if (candidate.weekday == DateTime.sunday) {
      return DayStatus.future;
    }
    // Spread a believable mix across the month.
    switch (day % 9) {
      case 0:
        return DayStatus.absent;
      case 3:
        return DayStatus.leave;
      case 6:
        return DayStatus.halfDay;
      default:
        return DayStatus.present;
    }
  }

  /// Real attendance status for [day] from the live logs map. A present log
  /// maps to present; an explicit `is_present == false` maps to absent;
  /// anything else (no log, or future date) is unmarked (rendered as future).
  DayStatus _liveStatusForDay(
      int day, Map<DateTime, Map<String, dynamic>> logsByDay) {
    final candidate = DateTime(_visibleMonth.year, _visibleMonth.month, day);
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);

    if (candidate.isAfter(todayMidnight)) {
      return DayStatus.future;
    }
    final log = logsByDay[candidate];
    if (log == null) {
      // No record for a past day -> leave unmarked.
      return DayStatus.future;
    }
    return log['is_present'] == false ? DayStatus.absent : DayStatus.present;
  }

  Color _colorForStatus(DayStatus status) {
    switch (status) {
      case DayStatus.present:
        return AppTheme.successColor;
      case DayStatus.absent:
        return AppTheme.errorColor;
      case DayStatus.leave:
        return AppTheme.infoColor;
      case DayStatus.halfDay:
        return AppTheme.warningColor;
      case DayStatus.future:
        return AppTheme.darkElements;
    }
  }

  String _labelForStatus(DayStatus status) {
    switch (status) {
      case DayStatus.present:
        return 'Present';
      case DayStatus.absent:
        return 'Absent';
      case DayStatus.leave:
        return 'On Leave';
      case DayStatus.halfDay:
        return 'Half Day';
      case DayStatus.future:
        return 'No Record';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const HeadingMediumText('Attendance'),
      ),
      body: Column(
        children: [
          _buildMonthHeader(),
          _buildWeekdayRow(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _logsFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  );
                }
                // On error or empty, fall back to mock coloring (logsByDay null).
                final rows = snap.data ?? const <Map<String, dynamic>>[];
                final Map<DateTime, Map<String, dynamic>>? logsByDay =
                    (snap.hasError || rows.isEmpty) ? null : _logsByDay(rows);
                return _buildCalendarBody(logsByDay);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// The scrollable grid + legend. When [logsByDay] is null the screen renders
  /// from the deterministic mock data instead of live attendance.
  Widget _buildCalendarBody(Map<DateTime, Map<String, dynamic>>? logsByDay) {
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    // weekday: Mon=1..Sun=7 -> number of blank leading cells.
    final leadingBlanks = _visibleMonth.weekday - 1;
    final totalCells = leadingBlanks + daysInMonth;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMedium,
      ),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: AppTheme.spacingSmall,
              crossAxisSpacing: AppTheme.spacingSmall,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              if (index < leadingBlanks) {
                return const SizedBox.shrink();
              }
              final day = index - leadingBlanks + 1;
              return _buildDayCell(day, logsByDay);
            },
          ),
          const SizedBox(height: AppTheme.spacingLarge),
          _buildLegend(),
          const SizedBox(height: AppTheme.spacingLarge),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    final title =
        '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}';
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingMedium),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSmall,
        vertical: AppTheme.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: AppTheme.darkElements,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.borders, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left, color: AppTheme.textPrimary),
            tooltip: 'Previous month',
          ),
          Column(
            children: [
              HeadingMediumText(title),
              const SizedBox(height: AppTheme.spacingXSmall),
              BodySmallText(widget.subjectName, color: AppTheme.textSecondary),
            ],
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right, color: AppTheme.textPrimary),
            tooltip: 'Next month',
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
      child: Row(
        children: _weekdayLabels
            .map(
              (label) => Expanded(
                child: Center(
                  child: LabelText(
                    label,
                    isSmall: true,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildDayCell(
      int day, Map<DateTime, Map<String, dynamic>>? logsByDay) {
    // Live status when logs are available, otherwise the mock fallback.
    final status = logsByDay == null
        ? _statusForDay(day)
        : _liveStatusForDay(day, logsByDay);
    final color = _colorForStatus(status);
    final isFuture = status == DayStatus.future;
    final now = DateTime.now();
    final isToday = day == now.day &&
        _visibleMonth.month == now.month &&
        _visibleMonth.year == now.year;

    return GestureDetector(
      onTap: () => _showDayDetail(day, status, logsByDay),
      child: Container(
        decoration: BoxDecoration(
          color: isFuture ? AppTheme.darkElements : color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
            color: isToday ? AppTheme.primaryColor : color.withValues(alpha: 0.5),
            width: isToday ? 2 : 1,
          ),
        ),
        child: Center(
          child: BodyMediumText(
            '$day',
            color: isFuture ? AppTheme.textSecondary : color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppTheme.darkElements,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.borders, width: 0.5),
      ),
      child: Wrap(
        spacing: AppTheme.spacingMedium,
        runSpacing: AppTheme.spacingSmall,
        children: [
          _legendItem(AppTheme.successColor, 'Present'),
          _legendItem(AppTheme.errorColor, 'Absent'),
          _legendItem(AppTheme.infoColor, 'Leave'),
          _legendItem(AppTheme.warningColor, 'Half-day'),
          _legendItem(AppTheme.darkElements, 'No record'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall / 2),
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: AppTheme.spacingXSmall),
        BodySmallText(label, color: AppTheme.textSecondary),
      ],
    );
  }

  void _showDayDetail(int day, DayStatus status,
      Map<DateTime, Map<String, dynamic>>? logsByDay) {
    final dateLabel =
        '${_monthNames[_visibleMonth.month - 1]} $day, ${_visibleMonth.year}';

    // Prefer the real log for this day when live data is loaded; otherwise the
    // existing mock timeline keeps the sheet populated as a fallback.
    final candidate = DateTime(_visibleMonth.year, _visibleMonth.month, day);
    final Map<String, dynamic>? log = logsByDay?[candidate];
    final events =
        log != null ? _timelineForLog(log) : _mockTimelineFor(status);
    final statusColor = _colorForStatus(status);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.darkElements,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borders,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  HeadingMediumText(dateLabel),
                  _statusChip(_labelForStatus(status), statusColor),
                ],
              ),
              const SizedBox(height: AppTheme.spacingXSmall),
              BodySmallText(widget.subjectName, color: AppTheme.textSecondary),
              const SizedBox(height: AppTheme.spacingLarge),
              if (events.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingMedium,
                  ),
                  child: BodyMediumText(
                    'No punches recorded for this day.',
                    color: AppTheme.textSecondary,
                  ),
                )
              else
                ...events.map(_timelineRow),
              const SizedBox(height: AppTheme.spacingSmall),
            ],
          ),
        );
      },
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSmall,
        vertical: AppTheme.spacingXSmall,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: color),
      ),
      child: LabelText(label, isSmall: true, color: color),
    );
  }

  Widget _timelineRow(_PunchEvent event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: event.color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(event.icon, color: event.color, size: 20),
          ),
          const SizedBox(width: AppTheme.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BodyMediumText(event.label, fontWeight: FontWeight.w600),
                const SizedBox(height: AppTheme.spacingXSmall),
                BodySmallText(event.site, color: AppTheme.textSecondary),
              ],
            ),
          ),
          BodyMediumText(event.time, color: AppTheme.textPrimary),
        ],
      ),
    );
  }

  /// Builds the day-detail timeline from a real attendance log: clock-in from
  /// `timestamp` and, when present, clock-out from `checkout_time`. Geofence
  /// subtext reflects the stored `location_status`.
  List<_PunchEvent> _timelineForLog(Map<String, dynamic> log) {
    final events = <_PunchEvent>[];
    final timeFmt = DateFormat('hh:mm a');

    // Real GPS coordinates stored with the record.
    final lat = (log['latitude'] as num?)?.toDouble();
    final lng = (log['longitude'] as num?)?.toDouble();
    final gps = (lat != null && lng != null)
        ? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'
        : null;
    final geofence = '${log['geofence_status'] ?? ''}'.trim();
    final status = '${log['attendance_status'] ?? log['location_status'] ?? ''}'.trim();

    String subtitle(String fallback) {
      final parts = <String>[];
      if (geofence.isNotEmpty) parts.add(geofence);
      if (gps != null) parts.add(gps);
      return parts.isEmpty ? fallback : parts.join('  •  ');
    }

    final checkIn =
        DateTime.tryParse('${log['check_in_time'] ?? log['timestamp']}')
            ?.toLocal();
    final isPresent = log['is_present'] != false;
    final flagged = status.toLowerCase() == 'flagged';
    if (checkIn != null) {
      events.add(
        _PunchEvent(
          label: 'Clock In',
          time: timeFmt.format(checkIn),
          site: subtitle(widget.subjectName),
          icon: Icons.login,
          color: flagged
              ? AppTheme.warningColor
              : (isPresent ? AppTheme.successColor : AppTheme.errorColor),
        ),
      );
    } else if (!isPresent) {
      events.add(
        _PunchEvent(
          label: 'No Clock In',
          time: '--:--',
          site: 'Marked absent by system',
          icon: Icons.error_outline,
          color: AppTheme.errorColor,
        ),
      );
    }

    final checkOut =
        DateTime.tryParse('${log['check_out_time'] ?? log['checkout_time']}')
            ?.toLocal();
    if (checkOut != null) {
      events.add(
        _PunchEvent(
          label: 'Clock Out',
          time: timeFmt.format(checkOut),
          site: subtitle(widget.subjectName),
          icon: Icons.logout,
          color: AppTheme.infoColor,
        ),
      );
    }

    // Worked hours summary (stored, else computed from the two punches).
    double? worked = (log['worked_hours'] as num?)?.toDouble();
    if ((worked == null || worked == 0) &&
        checkIn != null &&
        checkOut != null &&
        checkOut.isAfter(checkIn)) {
      worked = checkOut.difference(checkIn).inMinutes / 60.0;
    }
    if (worked != null && worked > 0) {
      final h = worked.floor();
      final m = ((worked - h) * 60).round();
      events.add(
        _PunchEvent(
          label: 'Worked Hours',
          time: '${h}h ${m.toString().padLeft(2, '0')}m',
          site: 'Total time on site',
          icon: Icons.timelapse,
          color: AppTheme.textPrimary,
        ),
      );
    }

    return events;
  }

  List<_PunchEvent> _mockTimelineFor(DayStatus status) {
    switch (status) {
      case DayStatus.present:
        return [
          _PunchEvent(
            label: 'Clock In',
            time: '09:02 AM',
            site: 'Inside geofence (12 m)',
            icon: Icons.login,
            color: AppTheme.successColor,
          ),
          _PunchEvent(
            label: 'Clock Out',
            time: '06:14 PM',
            site: 'Inside geofence (9 m)',
            icon: Icons.logout,
            color: AppTheme.infoColor,
          ),
        ];
      case DayStatus.halfDay:
        return [
          _PunchEvent(
            label: 'Clock In',
            time: '09:10 AM',
            site: 'Inside geofence (18 m)',
            icon: Icons.login,
            color: AppTheme.successColor,
          ),
          _PunchEvent(
            label: 'Clock Out',
            time: '01:05 PM',
            site: 'Early departure approved',
            icon: Icons.logout,
            color: AppTheme.warningColor,
          ),
        ];
      case DayStatus.leave:
        return [
          _PunchEvent(
            label: 'Approved Leave',
            time: 'All day',
            site: 'Casual leave',
            icon: Icons.beach_access,
            color: AppTheme.infoColor,
          ),
        ];
      case DayStatus.absent:
        return [
          _PunchEvent(
            label: 'No Clock In',
            time: '--:--',
            site: 'Marked absent by system',
            icon: Icons.error_outline,
            color: AppTheme.errorColor,
          ),
        ];
      case DayStatus.future:
        return const [];
    }
  }
}
