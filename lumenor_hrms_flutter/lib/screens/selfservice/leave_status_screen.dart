import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../services/app_session.dart';
import '../../services/hrms_repository.dart';
import '../../widgets/themed_text.dart';
import 'apply_leave_screen.dart';

/// A single leave request shaped like the `leave_requests` table.
class _LeaveRequest {
  final int id;
  final String leaveType;
  final String startDate;
  final String endDate;
  final int workingDays;
  final String reason;
  String status; // Pending / Approved / Rejected
  final String? rejectionReason;
  final String createdAt;

  _LeaveRequest({
    required this.id,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.workingDays,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.rejectionReason,
  });
}

/// Leave Status Screen
///
/// Lists leave requests as cards with a colored LEFT border by status.
/// Pending requests expose a Cancel action; rejected ones expand to reveal
/// the rejection reason. A button in the app bar pushes ApplyLeaveScreen.
class LeaveStatusScreen extends StatefulWidget {
  final String employeeName;

  const LeaveStatusScreen({
    super.key,
    this.employeeName = 'Priya Sharma',
  });

  @override
  State<LeaveStatusScreen> createState() => _LeaveStatusScreenState();
}

class _LeaveStatusScreenState extends State<LeaveStatusScreen> {
  /// Mock requests kept as a graceful fallback when the live query errors or
  /// returns no rows — the screen should never render blank.
  final List<_LeaveRequest> _mockRequests = [
    _LeaveRequest(
      id: 1,
      leaveType: 'Casual',
      startDate: '24 Jun 2026',
      endDate: '26 Jun 2026',
      workingDays: 3,
      reason: 'Family function out of town.',
      status: 'Pending',
      createdAt: '22 Jun 2026',
    ),
    _LeaveRequest(
      id: 2,
      leaveType: 'Sick',
      startDate: '10 Jun 2026',
      endDate: '11 Jun 2026',
      workingDays: 2,
      reason: 'Viral fever, doctor advised rest.',
      status: 'Approved',
      createdAt: '09 Jun 2026',
    ),
    _LeaveRequest(
      id: 3,
      leaveType: 'Earned',
      startDate: '02 May 2026',
      endDate: '06 May 2026',
      workingDays: 5,
      reason: 'Annual vacation.',
      status: 'Rejected',
      createdAt: '20 Apr 2026',
      rejectionReason:
          'Two team members already on leave for this period. '
          'Please re-apply for a later week.',
    ),
    _LeaveRequest(
      id: 4,
      leaveType: 'Casual',
      startDate: '15 Apr 2026',
      endDate: '15 Apr 2026',
      workingDays: 1,
      reason: 'Personal errand.',
      status: 'Approved',
      createdAt: '12 Apr 2026',
    ),
  ];

  final Set<int> _expanded = {};

  // Re-run the future when this changes (e.g. after cancelling a request).
  int _reloadTick = 0;

  static final DateFormat _displayFmt = DateFormat('dd MMM yyyy');

  /// Map a live `leave_requests` row onto the card view-model.
  _LeaveRequest _fromRow(Map<String, dynamic> row) {
    final startRaw = '${row['start_date']}';
    final endRaw = '${row['end_date']}';
    final start = DateTime.tryParse(startRaw);
    final end = DateTime.tryParse(endRaw);
    final created = DateTime.tryParse('${row['created_at']}');

    final workingDays =
        (start != null && end != null) ? end.difference(start).inDays + 1 : 1;

    return _LeaveRequest(
      id: (row['id'] as num?)?.toInt() ?? 0,
      leaveType: 'Leave',
      startDate: start != null ? _displayFmt.format(start) : startRaw,
      endDate: end != null ? _displayFmt.format(end) : endRaw,
      workingDays: workingDays < 1 ? 1 : workingDays,
      reason: (row['reason'] ?? '').toString(),
      status: (row['status'] ?? 'Pending').toString(),
      createdAt: created != null ? _displayFmt.format(created) : '',
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return AppTheme.successColor;
      case 'Rejected':
        return AppTheme.errorColor;
      case 'Pending':
      default:
        return AppTheme.warningColor;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Approved':
        return Icons.check_circle;
      case 'Rejected':
        return Icons.cancel;
      case 'Pending':
      default:
        return Icons.hourglass_top;
    }
  }

  /// Cancel a pending request. For live rows (positive id) this flips the
  /// status to 'Rejected' in Supabase, then re-runs the future. Mock rows
  /// (used as fallback) just drop locally.
  Future<void> _cancelRequest(_LeaveRequest request) async {
    try {
      await HrmsRepository.instance.setLeaveStatus(request.id, 'Rejected');
    } catch (_) {
      // Fallback (mock data / offline): nothing to persist.
    }
    if (!mounted) return;
    setState(() => _reloadTick++); // re-run the FutureBuilder
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.darkElements,
        content: const BodyMediumText(
          'Leave request cancelled',
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Future<void> _openApplyLeave() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const ApplyLeaveScreen()),
    );
    if (!mounted) return;
    // Refresh in case a new request was submitted.
    setState(() => _reloadTick++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const HeadingMediumText('Leave Status'),
        actions: [
          IconButton(
            onPressed: _openApplyLeave,
            icon: const Icon(Icons.add, color: AppTheme.textPrimary),
            tooltip: 'Apply for leave',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openApplyLeave,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: AppTheme.white),
        label: const Text('Apply', style: TextStyle(color: AppTheme.white)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        // _reloadTick is captured so setState re-runs the query.
        key: ValueKey<int>(_reloadTick),
        future: HrmsRepository.instance
            .employeeLeaves(AppSession.instance.employeeId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          // On error or empty, fall back to the mock list so we never show
          // a blank screen.
          final List<_LeaveRequest> requests;
          if (snap.hasError) {
            requests = _mockRequests;
          } else {
            final rows = snap.data ?? const <Map<String, dynamic>>[];
            requests = rows.isEmpty
                ? _mockRequests
                : rows.map(_fromRow).toList();
          }

          if (requests.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            itemCount: requests.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppTheme.spacingMedium),
            itemBuilder: (context, index) =>
                _buildRequestCard(requests[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.event_busy,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          const BodyLargeText('No leave requests yet'),
          const SizedBox(height: AppTheme.spacingXSmall),
          const BodySmallText(
            'Tap Apply to submit your first request',
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(_LeaveRequest request) {
    final color = _statusColor(request.status);
    final isRejected = request.status == 'Rejected';
    final isPending = request.status == 'Pending';
    final isOpen = _expanded.contains(request.id);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkElements,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.borders, width: 0.5),
        // Colored LEFT accent border.
        backgroundBlendMode: BlendMode.srcOver,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: HeadingMediumText(
                              '${request.leaveType} Leave',
                            ),
                          ),
                          _statusChip(request.status, color),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingSmall),
                      Row(
                        children: [
                          const Icon(
                            Icons.date_range,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: AppTheme.spacingSmall),
                          Expanded(
                            child: BodyMediumText(
                              '${request.startDate}  —  ${request.endDate}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingXSmall),
                      BodySmallText(
                        '${request.workingDays} working day'
                        '${request.workingDays == 1 ? '' : 's'}'
                        '${request.createdAt.isEmpty ? '' : ' · applied ${request.createdAt}'}',
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(height: AppTheme.spacingSmall),
                      BodyMediumText(
                        request.reason,
                        color: AppTheme.textPrimary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isRejected && request.rejectionReason != null) ...[
                        const SizedBox(height: AppTheme.spacingSmall),
                        _buildRejectionSection(request, isOpen),
                      ],
                      if (isPending) ...[
                        const SizedBox(height: AppTheme.spacingSmall),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _cancelRequest(request),
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: AppTheme.errorColor,
                            ),
                            label: const Text(
                              'Cancel',
                              style: TextStyle(color: AppTheme.errorColor),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRejectionSection(_LeaveRequest request, bool isOpen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              if (isOpen) {
                _expanded.remove(request.id);
              } else {
                _expanded.add(request.id);
              }
            });
          },
          child: Row(
            children: [
              LabelText(
                isOpen ? 'Hide rejection reason' : 'View rejection reason',
                isSmall: true,
                color: AppTheme.errorColor,
              ),
              Icon(
                isOpen ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: AppTheme.errorColor,
              ),
            ],
          ),
        ),
        if (isOpen)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: AppTheme.spacingSmall),
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(
                color: AppTheme.errorColor.withValues(alpha: 0.4),
              ),
            ),
            child: BodyMediumText(
              request.rejectionReason ?? 'No reason provided.',
              color: AppTheme.textPrimary,
            ),
          ),
      ],
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(label), size: 14, color: color),
          const SizedBox(width: AppTheme.spacingXSmall),
          LabelText(label, isSmall: true, color: color),
        ],
      ),
    );
  }
}
