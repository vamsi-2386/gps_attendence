import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/app_session.dart';
import '../../services/hrms_repository.dart';
import '../../widgets/themed_text.dart';
import '../../widgets/themed_button.dart';
import '../../widgets/themed_card.dart';
import 'leave_approvals_screen.dart';
import 'hr_override_screen.dart';
import 'employee_detail_screen.dart';
import 'site_management_screen.dart';

/// Attendance status for a team member shown on the dashboard.
enum _Status { present, absent, leave }

/// In-memory model for a team member row.
class _TeamMember {
  final int id;
  final String name;
  final String designation;
  final String code;
  final _Status status;

  const _TeamMember({
    required this.id,
    required this.name,
    required this.designation,
    required this.code,
    required this.status,
  });
}

/// Admin Overview Screen
///
/// Admin dashboard: top-line attendance stats, a live team roster with status
/// dots, and entry points into the leave-approval and HR-override queues.
///
/// Wired to live Supabase data only — no mock roster. The team comes from
/// [HrmsRepository.companyEmployees], pending approvals from
/// [HrmsRepository.companyLeaves] (status 'Pending'), and Present/Absent is
/// computed from real attendance today ([HrmsRepository.companyAttendanceRecent]).
class AdminOverviewScreen extends StatelessWidget {
  const AdminOverviewScreen({super.key});

  /// Loads the live roster, pending-leave queue, and recent attendance in
  /// parallel. Each degrades to an empty list on error so one failed query
  /// can't blank the whole dashboard.
  Future<List<List<Map<String, dynamic>>>> _load() {
    final companyId = AppSession.instance.companyId;
    return Future.wait([
      HrmsRepository.instance
          .companyEmployees(companyId)
          .catchError((_) => <Map<String, dynamic>>[]),
      HrmsRepository.instance
          .companyLeaves(companyId, status: 'Pending')
          .catchError((_) => <Map<String, dynamic>>[]),
      HrmsRepository.instance
          .companyAttendanceRecent(companyId)
          .catchError((_) => <Map<String, dynamic>>[]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const HeadingMediumText('Admin Dashboard'),
      ),
      body: FutureBuilder<List<List<Map<String, dynamic>>>>(
        future: _load(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final employees = (snap.hasError || snap.data == null)
              ? const <Map<String, dynamic>>[]
              : snap.data![0];
          final pendingLeaves = (snap.hasError || snap.data == null)
              ? const <Map<String, dynamic>>[]
              : snap.data![1];
          final attendance = (snap.hasError || snap.data == null)
              ? const <Map<String, dynamic>>[]
              : snap.data![2];

          // No fabricated roster: if there are genuinely no employees, say so.
          if (employees.isEmpty) {
            return _buildEmptyTeam(snap.hasError);
          }

          // Employee ids currently on a pending leave request.
          final onLeaveIds = <int>{
            for (final l in pendingLeaves)
              if (l['employee_id'] is int) l['employee_id'] as int,
          };

          // Employee ids actually marked present TODAY (local date), from real
          // attendance rows — Present/approved only.
          final presentTodayIds = _presentTodayIds(attendance);

          final rows = _toRows(employees, onLeaveIds, presentTodayIds);

          final total = employees.length;
          final pending = pendingLeaves.length;
          final present = rows.where((m) => m.status == _Status.present).length;
          final absent = rows.where((m) => m.status == _Status.absent).length;
          final onLeave = rows.where((m) => m.status == _Status.leave).length;

          return ListView(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            children: [
              Row(
                children: [
                  const HeadingMediumText('Today at a glance'),
                  const SizedBox(width: AppTheme.spacingSmall),
                  _livePill(),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      value: '$total',
                      label: 'Total employees',
                      accent: AppTheme.primaryColor,
                      icon: Icons.groups,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMedium),
                  Expanded(
                    child: _statCard(
                      value: '$pending',
                      label: 'Pending approvals',
                      accent: AppTheme.warningColor,
                      icon: Icons.pending_actions,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      value: '$present',
                      label: 'Present today',
                      accent: AppTheme.successColor,
                      icon: Icons.how_to_reg,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMedium),
                  Expanded(
                    child: _statCard(
                      value: '$absent',
                      label: 'Absent today',
                      accent: AppTheme.errorColor,
                      icon: Icons.person_off,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      value: '$onLeave',
                      label: 'On leave',
                      accent: AppTheme.infoColor,
                      icon: Icons.beach_access,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMedium),
                  const Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(height: AppTheme.spacingLarge),
              Row(
                children: [
                  Expanded(
                    child: ThemedButton(
                      label: 'Leave approvals',
                      icon: Icons.fact_check,
                      height: 46,
                      backgroundColor: AppTheme.infoColor,
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.white,
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LeaveApprovalsScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMedium),
                  Expanded(
                    child: ThemedOutlineButton(
                      label: 'HR override',
                      icon: Icons.gpp_maybe,
                      height: 46,
                      borderColor: AppTheme.infoColor,
                      textColor: AppTheme.infoColor,
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.infoColor,
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HROverrideScreen()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              ThemedButton(
                label: 'Manage Sites & Geofences',
                icon: Icons.add_location_alt_outlined,
                height: 46,
                backgroundColor: AppTheme.primaryColor,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SiteManagementScreen()),
                ),
              ),
              const SizedBox(height: AppTheme.spacingLarge),
              const HeadingMediumText('Team'),
              const SizedBox(height: AppTheme.spacingMedium),
              ...rows.map((m) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppTheme.spacingMedium),
                    child: _teamRow(context, m),
                  )),
              const SizedBox(height: AppTheme.spacingLarge),
            ],
          );
        },
      ),
    );
  }

  /// Maps live employee rows onto the [_TeamMember] view model with a REAL
  /// status: on a pending leave -> leave; checked in present today -> present;
  /// otherwise absent.
  List<_TeamMember> _toRows(
    List<Map<String, dynamic>> employees,
    Set<int> onLeaveIds,
    Set<int> presentTodayIds,
  ) {
    return employees.map((e) {
      final id = e['employee_id'];
      final intId = id is int ? id : int.tryParse('$id');
      final onLeave = intId != null && onLeaveIds.contains(intId);
      final present = intId != null && presentTodayIds.contains(intId);
      final role = (e['role'] ?? '').toString().trim();
      final designation = (e['designation'] ?? '').toString().trim();
      // Prefer designation; fall back to role so the subtitle is never empty.
      final subtitle = designation.isNotEmpty
          ? designation
          : (role.isNotEmpty ? role : 'Employee');
      return _TeamMember(
        id: intId ?? 0,
        name: (e['name'] ?? 'Unknown').toString(),
        designation: subtitle,
        code: (e['employee_code'] ?? '').toString(),
        status: onLeave
            ? _Status.leave
            : (present ? _Status.present : _Status.absent),
      );
    }).toList();
  }

  /// Employee ids with a real Present (counted) check-in dated today in local
  /// time. Timestamps are stored UTC, so convert before comparing the day.
  Set<int> _presentTodayIds(List<Map<String, dynamic>> attendance) {
    final now = DateTime.now();
    final ids = <int>{};
    for (final a in attendance) {
      final present = a['is_present'] == true ||
          (a['attendance_status'] ?? '').toString() == 'Present';
      if (!present) continue;
      final t = DateTime.tryParse('${a['check_in_time'] ?? a['timestamp']}')
          ?.toLocal();
      if (t == null) continue;
      if (t.year == now.year && t.month == now.month && t.day == now.day) {
        final id = a['employee_id'];
        final intId = id is int ? id : int.tryParse('$id');
        if (intId != null) ids.add(intId);
      }
    }
    return ids;
  }

  Widget _buildEmptyTeam(bool hasError) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(hasError ? Icons.cloud_off : Icons.groups_outlined,
                size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: AppTheme.spacingMedium),
            BodyLargeText(hasError
                ? 'Couldn’t load your team'
                : 'No employees registered yet'),
            const SizedBox(height: AppTheme.spacingXSmall),
            BodySmallText(
              hasError
                  ? 'Check your connection and reopen this screen.'
                  : 'Employees appear here once they register on the mobile app.',
              color: AppTheme.textSecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _livePill() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSmall,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.successColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppTheme.spacingXSmall),
          const LabelText('Live', color: AppTheme.successColor, isSmall: true),
        ],
      ),
    );
  }

  Widget _statCard({
    required String value,
    required String label,
    required Color accent,
    required IconData icon,
  }) {
    return ThemedCard(
      backgroundColor: AppTheme.darkElements,
      borderColor: AppTheme.borders,
      borderWidth: 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DisplayMediumText(value, color: accent),
              Icon(icon, color: accent, size: 22),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXSmall),
          BodySmallText(label, color: AppTheme.textSecondary),
        ],
      ),
    );
  }

  Widget _teamRow(BuildContext context, _TeamMember member) {
    return ThemedCard(
      backgroundColor: AppTheme.darkElements,
      borderColor: AppTheme.borders,
      borderWidth: 0.5,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EmployeeDetailScreen(
            employeeId: member.id,
            name: member.name,
            designation: member.designation,
            employeeCode: member.code,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: BodyLargeText(
              _initials(member.name),
              color: AppTheme.infoColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BodyLargeText(member.name, fontWeight: FontWeight.w600),
                const SizedBox(height: 2),
                BodySmallText(member.designation,
                    color: AppTheme.textSecondary),
              ],
            ),
          ),
          _statusDot(member.status),
          const SizedBox(width: AppTheme.spacingSmall),
          const Icon(Icons.chevron_right,
              color: AppTheme.textSecondary, size: 20),
        ],
      ),
    );
  }

  Widget _statusDot(_Status status) {
    final color = switch (status) {
      _Status.present => AppTheme.successColor,
      _Status.absent => AppTheme.errorColor,
      _Status.leave => AppTheme.infoColor,
    };
    final label = switch (status) {
      _Status.present => 'Present',
      _Status.absent => 'Absent',
      _Status.leave => 'Leave',
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppTheme.spacingXSmall),
        BodySmallText(label, color: color),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}
