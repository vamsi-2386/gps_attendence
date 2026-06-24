/// Leave Request Model
///
/// Represents a leave request in the HRMS system
class LeaveRequest {
  final String id;
  final String employeeId;
  final String companyId;
  final DateTime startDate;
  final DateTime endDate;
  final String leaveType; // 'casual', 'sick', 'earned', 'unpaid', 'maternity'
  final String status; // 'pending', 'approved', 'rejected', 'cancelled'
  final String reason;
  final String? attachmentUrl;
  final String? approverComments;
  final String? approvedByEmployeeId;
  final DateTime? approvalDate;
  final int numberOfDays;
  final DateTime createdAt;
  final DateTime updatedAt;

  LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.companyId,
    required this.startDate,
    required this.endDate,
    required this.leaveType,
    required this.status,
    required this.reason,
    this.attachmentUrl,
    this.approverComments,
    this.approvedByEmployeeId,
    this.approvalDate,
    required this.numberOfDays,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if leave is approved
  bool get isApproved => status == 'approved';

  /// Check if leave is pending
  bool get isPending => status == 'pending';

  /// Check if leave is rejected
  bool get isRejected => status == 'rejected';

  /// Get leave type display name
  String get leaveTypeDisplay {
    switch (leaveType) {
      case 'casual':
        return 'Casual Leave';
      case 'sick':
        return 'Sick Leave';
      case 'earned':
        return 'Earned Leave';
      case 'unpaid':
        return 'Unpaid Leave';
      case 'maternity':
        return 'Maternity Leave';
      default:
        return leaveType;
    }
  }

  /// Get status display name with color hint
  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending Approval';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  /// Create LeaveRequest from JSON
  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      companyId: json['company_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      leaveType: json['leave_type'] as String,
      status: json['status'] as String,
      reason: json['reason'] as String,
      attachmentUrl: json['attachment_url'] as String?,
      approverComments: json['approver_comments'] as String?,
      approvedByEmployeeId: json['approved_by_employee_id'] as String?,
      approvalDate: json['approval_date'] != null
          ? DateTime.parse(json['approval_date'] as String)
          : null,
      numberOfDays: json['number_of_days'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert LeaveRequest to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'company_id': companyId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'leave_type': leaveType,
      'status': status,
      'reason': reason,
      'attachment_url': attachmentUrl,
      'approver_comments': approverComments,
      'approved_by_employee_id': approvedByEmployeeId,
      'approval_date': approvalDate?.toIso8601String(),
      'number_of_days': numberOfDays,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with modifications
  LeaveRequest copyWith({
    String? id,
    String? employeeId,
    String? companyId,
    DateTime? startDate,
    DateTime? endDate,
    String? leaveType,
    String? status,
    String? reason,
    String? attachmentUrl,
    String? approverComments,
    String? approvedByEmployeeId,
    DateTime? approvalDate,
    int? numberOfDays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LeaveRequest(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      companyId: companyId ?? this.companyId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      leaveType: leaveType ?? this.leaveType,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      approverComments: approverComments ?? this.approverComments,
      approvedByEmployeeId: approvedByEmployeeId ?? this.approvedByEmployeeId,
      approvalDate: approvalDate ?? this.approvalDate,
      numberOfDays: numberOfDays ?? this.numberOfDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
