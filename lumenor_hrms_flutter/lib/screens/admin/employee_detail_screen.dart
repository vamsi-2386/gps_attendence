import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../services/hrms_repository.dart';
import '../../widgets/themed_text.dart';
import '../../widgets/themed_button.dart';
import '../../widgets/themed_card.dart';

/// Employee Detail Screen
///
/// Admin-facing employee profile. All figures are REAL — derived from the
/// employee's own attendance and leave rows in Supabase (no fabricated
/// biometric/attendance defaults).
class EmployeeDetailScreen extends StatefulWidget {
  final int employeeId;
  final String name;
  final String designation;
  final String employeeCode;

  const EmployeeDetailScreen({
    super.key,
    required this.employeeId,
    required this.name,
    required this.designation,
    required this.employeeCode,
  });

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  static final DateFormat _dayFmt = DateFormat('dd MMM yyyy');

  late Future<_EmployeeStats> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadStats();
  }

  Future<_EmployeeStats> _loadStats() async {
    final repo = HrmsRepository.instance;
    final attendance = await repo.attendanceLogs(widget.employeeId);
    final leaves = await repo.employeeLeaves(widget.employeeId);

    var present = 0, flagged = 0, pendingLeaves = 0, approvedLeaveDays = 0;
    DateTime? lastCheckIn;

    for (final a in attendance) {
      final status = (a['attendance_status'] ?? a['location_status'] ?? '')
          .toString();
      final isPresent = a['is_present'] == true || status == 'Present';
      if (isPresent) present++;
      if (status == 'Flagged') flagged++;
      final t = DateTime.tryParse('${a['check_in_time'] ?? a['timestamp']}')
          ?.toLocal();
      if (t != null && (lastCheckIn == null || t.isAfter(lastCheckIn))) {
        lastCheckIn = t;
      }
    }

    for (final l in leaves) {
      final st = (l['status'] ?? '').toString();
      if (st == 'Pending') pendingLeaves++;
      if (st == 'Approved') {
        final s = DateTime.tryParse('${l['start_date']}');
        final e = DateTime.tryParse('${l['end_date']}');
        if (s != null && e != null) approvedLeaveDays += e.difference(s).inDays + 1;
      }
    }

    final totalCheckIns = attendance.length;
    final rate = totalCheckIns == 0 ? 0.0 : present / totalCheckIns;

    return _EmployeeStats(
      totalCheckIns: totalCheckIns,
      present: present,
      flagged: flagged,
      attendanceRate: rate,
      pendingLeaves: pendingLeaves,
      approvedLeaveDays: approvedLeaveDays,
      lastCheckIn: lastCheckIn,
    );
  }

  String get _initials {
    final parts = widget.name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(title: const HeadingMediumText('Employee Details')),
      body: FutureBuilder<_EmployeeStats>(
        future: _future,
        builder: (context, snap) {
          final stats = snap.data;
          return ListView(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            children: [
              _profileHeader(),
              const SizedBox(height: AppTheme.spacingLarge),
              if (snap.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(AppTheme.spacingLarge),
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryColor),
                  ),
                )
              else if (snap.hasError || stats == null)
                _errorCard()
              else ...[
                _attendanceCard(stats),
                const SizedBox(height: AppTheme.spacingMedium),
                _quickStats(stats),
              ],
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
          );
        },
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
          HeadingLargeText(widget.name, textAlign: TextAlign.center),
          const SizedBox(height: AppTheme.spacingXSmall),
          BodyMediumText(widget.designation, color: AppTheme.textSecondary),
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
            child: LabelText(widget.employeeCode, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _attendanceCard(_EmployeeStats s) {
    return ThemedCard(
      backgroundColor: AppTheme.darkElements,
      borderColor: AppTheme.borders,
      borderWidth: 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.fact_check_outlined,
                  color: AppTheme.infoColor, size: 20),
              SizedBox(width: AppTheme.spacingSmall),
              HeadingMediumText('Attendance Record'),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const BodyMediumText('Present rate'),
              BodyLargeText(
                '${(s.attendanceRate * 100).round()}%',
                color: _scoreColor(s.attendanceRate),
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            child: LinearProgressIndicator(
              value: s.attendanceRate.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppTheme.darkBackground,
              valueColor:
                  AlwaysStoppedAnimation<Color>(_scoreColor(s.attendanceRate)),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          const Divider(color: AppTheme.borders, height: 1),
          const SizedBox(height: AppTheme.spacingMedium),
          _detailRow(
            icon: Icons.how_to_reg,
            iconColor: AppTheme.successColor,
            label: 'Present check-ins',
            value: '${s.present} / ${s.totalCheckIns}',
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          _detailRow(
            icon: Icons.gpp_maybe,
            iconColor:
                s.flagged > 0 ? AppTheme.warningColor : AppTheme.successColor,
            label: 'Flagged (pending review)',
            value: '${s.flagged}',
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          _detailRow(
            icon: Icons.schedule,
            iconColor: AppTheme.infoColor,
            label: 'Last check-in',
            value: s.lastCheckIn != null
                ? _dayFmt.format(s.lastCheckIn!)
                : 'No check-ins yet',
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

  Widget _quickStats(_EmployeeStats s) {
    return Row(
      children: [
        Expanded(
          child: _statTile(
            icon: Icons.beach_access,
            accent: AppTheme.infoColor,
            value: '${s.approvedLeaveDays}',
            label: 'Approved leave days',
          ),
        ),
        const SizedBox(width: AppTheme.spacingMedium),
        Expanded(
          child: _statTile(
            icon: Icons.hourglass_top,
            accent: AppTheme.warningColor,
            value: '${s.pendingLeaves}',
            label: 'Pending leave requests',
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

  Widget _errorCard() {
    return ThemedCard(
      backgroundColor: AppTheme.darkElements,
      borderColor: AppTheme.borders,
      borderWidth: 0.5,
      child: const Row(
        children: [
          Icon(Icons.cloud_off, color: AppTheme.textSecondary),
          SizedBox(width: AppTheme.spacingSmall),
          Expanded(
            child: BodyMediumText(
              'Couldn’t load this employee’s records. Check your connection.',
              color: AppTheme.textSecondary,
            ),
          ),
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
    final link = 'https://hrms.lumenor.in/reenroll/${widget.employeeCode}';
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

/// Real, computed stats for one employee.
class _EmployeeStats {
  final int totalCheckIns;
  final int present;
  final int flagged;
  final double attendanceRate;
  final int pendingLeaves;
  final int approvedLeaveDays;
  final DateTime? lastCheckIn;

  const _EmployeeStats({
    required this.totalCheckIns,
    required this.present,
    required this.flagged,
    required this.attendanceRate,
    required this.pendingLeaves,
    required this.approvedLeaveDays,
    required this.lastCheckIn,
  });
}
