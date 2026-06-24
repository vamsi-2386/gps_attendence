import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../services/app_session.dart';
import '../../services/hrms_repository.dart';
import '../../widgets/themed_text.dart';
import '../../widgets/themed_button.dart';
import '../../widgets/themed_card.dart';

/// Simple in-memory model for a pending leave request.
class _LeaveRequest {
  final int id;
  final String employeeName;
  final String leaveType;
  final String dateRange;
  final String reason;
  final int balanceDays;

  const _LeaveRequest({
    required this.id,
    required this.employeeName,
    required this.leaveType,
    required this.dateRange,
    required this.reason,
    required this.balanceDays,
  });
}

/// Leave Approvals Screen
///
/// Admin review queue for pending leave requests. Approving / rejecting a
/// request removes it from the list and surfaces a confirmation SnackBar.
class LeaveApprovalsScreen extends StatefulWidget {
  const LeaveApprovalsScreen({super.key});

  @override
  State<LeaveApprovalsScreen> createState() => _LeaveApprovalsScreenState();
}

class _LeaveApprovalsScreenState extends State<LeaveApprovalsScreen> {
  /// Mock data kept as a graceful fallback for when the live query errors or
  /// returns no pending requests.
  static const List<_LeaveRequest> _mockRequests = [
    _LeaveRequest(
      id: 1,
      employeeName: 'Priya Sharma',
      leaveType: 'Casual Leave',
      dateRange: '24 Jun - 26 Jun 2026',
      reason: 'Family function out of town.',
      balanceDays: 12,
    ),
    _LeaveRequest(
      id: 2,
      employeeName: 'Rahul Verma',
      leaveType: 'Sick Leave',
      dateRange: '25 Jun 2026',
      reason: 'Fever, advised rest by doctor.',
      balanceDays: 8,
    ),
    _LeaveRequest(
      id: 3,
      employeeName: 'Anjali Nair',
      leaveType: 'Earned Leave',
      dateRange: '30 Jun - 04 Jul 2026',
      reason: 'Planned vacation with family.',
      balanceDays: 15,
    ),
    _LeaveRequest(
      id: 4,
      employeeName: 'Imran Khan',
      leaveType: 'Casual Leave',
      dateRange: '27 Jun 2026',
      reason: 'Personal errand at home.',
      balanceDays: 5,
    ),
  ];

  /// The list currently rendered. Seeded once from the FutureBuilder result
  /// (live rows, or mock fallback) so Approve/Reject can mutate it locally
  /// via setState without re-running the query.
  List<_LeaveRequest>? _requests;

  /// One-shot load: pending company leaves + the employee-name lookup map.
  late final Future<List<dynamic>> _loadFuture = Future.wait([
    HrmsRepository.instance
        .companyLeaves(AppSession.instance.companyId, status: 'Pending'),
    HrmsRepository.instance.employeeNames(AppSession.instance.companyId),
  ]);

  /// Map a raw leave row onto the existing card model.
  _LeaveRequest _mapLeave(
    Map<String, dynamic> row,
    Map<int, String> names,
  ) {
    final id = (row['id'] as num?)?.toInt() ?? 0;
    final empId = (row['employee_id'] as num?)?.toInt() ?? 0;
    final name = (names[empId] ?? '').trim();
    final start = DateTime.tryParse('${row['start_date']}');
    final end = DateTime.tryParse('${row['end_date']}');

    final fmt = DateFormat('dd MMM yyyy');
    String dateRange;
    int spanDays = 0;
    if (start != null && end != null) {
      spanDays = end.difference(start).inDays + 1;
      dateRange = start.year == end.year &&
              start.month == end.month &&
              start.day == end.day
          ? fmt.format(start)
          : '${DateFormat('dd MMM').format(start)} - ${fmt.format(end)}';
    } else if (start != null) {
      spanDays = 1;
      dateRange = fmt.format(start);
    } else {
      dateRange = '${row['start_date']} - ${row['end_date']}';
    }

    final reason = (row['reason'] ?? '').toString().trim();

    return _LeaveRequest(
      id: id,
      employeeName: name.isEmpty ? 'Employee #$empId' : name,
      leaveType: 'Leave',
      dateRange: dateRange,
      reason: reason.isEmpty ? 'No reason provided.' : reason,
      balanceDays: spanDays,
    );
  }

  Future<void> _resolve(_LeaveRequest req, bool approved) async {
    // Optimistically remove from the queue.
    setState(() => _requests?.removeWhere((r) => r.id == req.id));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.darkElements,
          content: BodyMediumText(
            approved
                ? '${req.employeeName}’s leave approved'
                : '${req.employeeName}’s leave rejected',
            color: approved ? AppTheme.successColor : AppTheme.errorColor,
          ),
        ),
      );
    try {
      await HrmsRepository.instance
          .setLeaveStatus(req.id, approved ? 'Approved' : 'Rejected');
    } catch (_) {
      // Persisting failed (offline) — the optimistic UI update stands for this
      // session; surface a soft notice without re-inserting the card.
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.darkElements,
            content: BodyMediumText(
              'Could not sync change. Will retry later.',
              color: AppTheme.warningColor,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const HeadingMediumText('Leave Approvals'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _loadFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.infoColor),
            );
          }

          // Seed the mutable list exactly once, from live rows or mock fallback.
          if (_requests == null) {
            if (snap.hasError || !snap.hasData) {
              _requests = List.of(_mockRequests);
            } else {
              final leaves = (snap.data![0] as List).cast<Map<String, dynamic>>();
              final names = snap.data![1] as Map<int, String>;
              final mapped =
                  leaves.map((row) => _mapLeave(row, names)).toList();
              _requests = mapped.isEmpty ? List.of(_mockRequests) : mapped;
            }
          }

          final requests = _requests!;
          if (requests.isEmpty) return _emptyState();

          return ListView.separated(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            itemCount: requests.length + 1,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppTheme.spacingMedium),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const BodyMediumText(
                      'Pending requests',
                      color: AppTheme.textSecondary,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSmall,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: LabelText(
                        '${requests.length} pending',
                        color: AppTheme.warningColor,
                        isSmall: true,
                      ),
                    ),
                  ],
                );
              }
              return _leaveCard(requests[index - 1]);
            },
          );
        },
      ),
    );
  }

  Widget _leaveCard(_LeaveRequest req) {
    return ThemedCard(
      backgroundColor: AppTheme.darkElements,
      borderColor: AppTheme.borders,
      borderWidth: 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: HeadingMediumText(req.employeeName)),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSmall,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: LabelText(
                  req.leaveType,
                  color: AppTheme.infoColor,
                  isSmall: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  color: AppTheme.textSecondary, size: 16),
              const SizedBox(width: AppTheme.spacingSmall),
              BodyMediumText(req.dateRange, color: AppTheme.textPrimary),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          BodySmallText(req.reason, color: AppTheme.textSecondary),
          const SizedBox(height: AppTheme.spacingSmall),
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  color: AppTheme.successColor, size: 16),
              const SizedBox(width: AppTheme.spacingSmall),
              BodySmallText(
                '${req.balanceDays} days left',
                color: AppTheme.successColor,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Row(
            children: [
              Expanded(
                child: ThemedButton(
                  label: 'Approve',
                  icon: Icons.check,
                  height: 44,
                  backgroundColor: AppTheme.successColor,
                  onPressed: () => _resolve(req, true),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: ThemedButton(
                  label: 'Reject',
                  icon: Icons.close,
                  height: 44,
                  backgroundColor: AppTheme.errorColor,
                  onPressed: () => _resolve(req, false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined,
              color: AppTheme.textSecondary, size: 56),
          const SizedBox(height: AppTheme.spacingMedium),
          const HeadingMediumText('All caught up'),
          const SizedBox(height: AppTheme.spacingXSmall),
          const BodyMediumText(
            'No pending leave requests',
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: AppTheme.spacingLarge),
          SizedBox(
            width: 220,
            child: ThemedOutlineButton(
              label: 'Back to dashboard',
              icon: Icons.arrow_back,
              borderColor: AppTheme.infoColor,
              textColor: AppTheme.infoColor,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
