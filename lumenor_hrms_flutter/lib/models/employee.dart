/// Employee Model
///
/// Represents an employee in the Lumenor HRMS system
class Employee {
  final String id;
  final String companyId;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String employeeId;
  final String designation;
  final String department;
  final String profileImageUrl;
  final String faceEmbeddingId;
  final bool isFaceEnrolled;
  final DateTime dateOfJoining;
  final DateTime? dateOfBirth;
  final String role; // 'employee', 'manager', 'hr', 'admin'
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Employee({
    required this.id,
    required this.companyId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.employeeId,
    required this.designation,
    required this.department,
    required this.profileImageUrl,
    required this.faceEmbeddingId,
    required this.isFaceEnrolled,
    required this.dateOfJoining,
    this.dateOfBirth,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get full name
  String get fullName => '$firstName $lastName';

  /// Create Employee from JSON (from Supabase)
  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      phoneNumber: json['phone_number'] as String,
      employeeId: json['employee_id'] as String,
      designation: json['designation'] as String,
      department: json['department'] as String,
      profileImageUrl: json['profile_image_url'] as String? ?? '',
      faceEmbeddingId: json['face_embedding_id'] as String? ?? '',
      isFaceEnrolled: json['is_face_enrolled'] as bool? ?? false,
      dateOfJoining: DateTime.parse(json['date_of_joining'] as String),
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      role: json['role'] as String? ?? 'employee',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert Employee to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'employee_id': employeeId,
      'designation': designation,
      'department': department,
      'profile_image_url': profileImageUrl,
      'face_embedding_id': faceEmbeddingId,
      'is_face_enrolled': isFaceEnrolled,
      'date_of_joining': dateOfJoining.toIso8601String(),
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'role': role,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with modifications
  Employee copyWith({
    String? id,
    String? companyId,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? employeeId,
    String? designation,
    String? department,
    String? profileImageUrl,
    String? faceEmbeddingId,
    bool? isFaceEnrolled,
    DateTime? dateOfJoining,
    DateTime? dateOfBirth,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Employee(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      employeeId: employeeId ?? this.employeeId,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      faceEmbeddingId: faceEmbeddingId ?? this.faceEmbeddingId,
      isFaceEnrolled: isFaceEnrolled ?? this.isFaceEnrolled,
      dateOfJoining: dateOfJoining ?? this.dateOfJoining,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
