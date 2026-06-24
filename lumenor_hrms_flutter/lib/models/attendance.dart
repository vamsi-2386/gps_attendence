/// Attendance Model
///
/// Represents an attendance record for an employee
class Attendance {
  final String id;
  final String employeeId;
  final String companyId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String checkInLocation;
  final String? checkOutLocation;
  final double checkInLatitude;
  final double checkInLongitude;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final bool isInsideGeofence;
  final String status; // 'checked_in', 'checked_out', 'absent', 'late'
  final String? notes;
  final bool isFaceVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  Attendance({
    required this.id,
    required this.employeeId,
    required this.companyId,
    required this.checkInTime,
    this.checkOutTime,
    required this.checkInLocation,
    this.checkOutLocation,
    required this.checkInLatitude,
    required this.checkInLongitude,
    this.checkOutLatitude,
    this.checkOutLongitude,
    required this.isInsideGeofence,
    required this.status,
    this.notes,
    required this.isFaceVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate working hours
  Duration get workingHours {
    if (checkOutTime == null) {
      return Duration.zero;
    }
    return checkOutTime!.difference(checkInTime);
  }

  /// Get working hours as string (HH:MM format)
  String get workingHoursString {
    final hours = workingHours.inHours;
    final minutes = workingHours.inMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  /// Create Attendance from JSON
  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      companyId: json['company_id'] as String,
      checkInTime: DateTime.parse(json['check_in_time'] as String),
      checkOutTime: json['check_out_time'] != null
          ? DateTime.parse(json['check_out_time'] as String)
          : null,
      checkInLocation: json['check_in_location'] as String,
      checkOutLocation: json['check_out_location'] as String?,
      checkInLatitude: (json['check_in_latitude'] as num).toDouble(),
      checkInLongitude: (json['check_in_longitude'] as num).toDouble(),
      checkOutLatitude: json['check_out_latitude'] != null
          ? (json['check_out_latitude'] as num).toDouble()
          : null,
      checkOutLongitude: json['check_out_longitude'] != null
          ? (json['check_out_longitude'] as num).toDouble()
          : null,
      isInsideGeofence: json['is_inside_geofence'] as bool? ?? true,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      isFaceVerified: json['is_face_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert Attendance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'company_id': companyId,
      'check_in_time': checkInTime.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'check_in_location': checkInLocation,
      'check_out_location': checkOutLocation,
      'check_in_latitude': checkInLatitude,
      'check_in_longitude': checkInLongitude,
      'check_out_latitude': checkOutLatitude,
      'check_out_longitude': checkOutLongitude,
      'is_inside_geofence': isInsideGeofence,
      'status': status,
      'notes': notes,
      'is_face_verified': isFaceVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with modifications
  Attendance copyWith({
    String? id,
    String? employeeId,
    String? companyId,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? checkInLocation,
    String? checkOutLocation,
    double? checkInLatitude,
    double? checkInLongitude,
    double? checkOutLatitude,
    double? checkOutLongitude,
    bool? isInsideGeofence,
    String? status,
    String? notes,
    bool? isFaceVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Attendance(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      companyId: companyId ?? this.companyId,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkInLocation: checkInLocation ?? this.checkInLocation,
      checkOutLocation: checkOutLocation ?? this.checkOutLocation,
      checkInLatitude: checkInLatitude ?? this.checkInLatitude,
      checkInLongitude: checkInLongitude ?? this.checkInLongitude,
      checkOutLatitude: checkOutLatitude ?? this.checkOutLatitude,
      checkOutLongitude: checkOutLongitude ?? this.checkOutLongitude,
      isInsideGeofence: isInsideGeofence ?? this.isInsideGeofence,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      isFaceVerified: isFaceVerified ?? this.isFaceVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
