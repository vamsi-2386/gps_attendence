/// Carries all employee onboarding details collected during registration
/// across the registration → face enrollment → profile confirmation flow.
class EmployeeRegistration {
  EmployeeRegistration({
    required this.inviteCode,
    required this.fullName,
    required this.employeeCode,
    required this.designation,
    required this.companyName,
    required this.dailyRate,
    required this.mobile,
    required this.email,
    this.companyId,
    this.subjectId,
    this.subjectName,
    this.officeId,
    this.officeName,
    this.facePhotoPath,
  });

  final String inviteCode;
  final String fullName;
  final String employeeCode;
  final String designation;
  final String companyName;
  final double dailyRate;
  final String mobile;
  final String email;

  /// Resolved from the invite code.
  int? companyId;

  /// Selected assigned site (subjects row) — optional legacy project link.
  int? subjectId;
  String? subjectName;

  /// Selected assigned office (offices row) — the geofence the employee uses.
  int? officeId;
  String? officeName;

  /// Local file path of the captured enrollment photo.
  String? facePhotoPath;
}
