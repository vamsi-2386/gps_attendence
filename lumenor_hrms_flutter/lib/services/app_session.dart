import 'hrms_repository.dart';

/// Holds the currently "logged in" identity for the app.
///
/// Face login is mocked in this build, so we seed a real employee that exists
/// in the live Supabase DB (employee_id 11 "vamsi krishna", company 12) so the
/// screens show genuine data. Replace [signInAs] wiring once real auth lands.
class AppSession {
  AppSession._();
  static final AppSession instance = AppSession._();

  int employeeId = 11;
  int companyId = 12;
  String employeeName = 'vamsi krishna';
  String designation = 'Employee';
  String role = 'Employee';
  String companyName = '';

  /// Primary assigned site (subjects row) — kept for Streamlit project views.
  int? subjectId;
  String siteName = '';

  /// Assigned office (offices row) — the geofence source of truth.
  int? officeId;
  String officeName = '';
  double? officeLat;
  double? officeLng;
  int officeRadius = 200;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  /// Resolve and cache the employee's assigned office geofence.
  Future<void> _loadAssignedOffice() async {
    try {
      final o = await HrmsRepository.instance
          .assignedOffice(employeeId, companyId);
      if (o != null) {
        officeId = (o['id'] as num?)?.toInt();
        officeName = (o['office_name'] ?? '').toString();
        officeLat = (o['latitude'] as num?)?.toDouble();
        officeLng = (o['longitude'] as num?)?.toDouble();
        officeRadius = (o['radius'] as num?)?.toInt() ?? officeRadius;
      }
    } catch (_) {
      // Leave office unset; dashboard will show "geofence not configured".
    }
  }

  /// Switch the active identity to a logged-in employee (from employeeByCode).
  /// Resolves their company name and primary assigned site so attendance,
  /// dashboard, and history all reflect this employee.
  Future<void> signInAs(Map<String, dynamic> emp) async {
    employeeId = emp['employee_id'] as int;
    employeeName = (emp['name'] ?? employeeName).toString();
    designation = (emp['designation'] ?? 'Employee').toString();
    role = (emp['role'] ?? 'Employee').toString();
    companyId = (emp['company_id'] as int?) ?? companyId;
    _loaded = true;
    try {
      final co = await HrmsRepository.instance.company(companyId);
      if (co != null) companyName = (co['name'] ?? '').toString();
      final site =
          await HrmsRepository.instance.primarySite(employeeId, companyId);
      subjectId = site?['subject_id'] as int?;
      siteName = (site?['name'] ?? '').toString();
      await _loadAssignedOffice();
    } catch (_) {
      // Keep whatever resolved; attendance can still insert without a site.
    }
  }

  /// Pull the real employee + company record so the seeded identity reflects
  /// whatever is actually in the database. Safe to call repeatedly.
  Future<void> hydrate() async {
    try {
      final emp = await HrmsRepository.instance.employee(employeeId);
      if (emp != null) {
        employeeName = (emp['name'] ?? employeeName).toString();
        designation = (emp['designation'] ?? designation).toString();
        role = (emp['role'] ?? role).toString();
        companyId = (emp['company_id'] as int?) ?? companyId;
      }
      final co = await HrmsRepository.instance.company(companyId);
      if (co != null) companyName = (co['name'] ?? '').toString();
      await _loadAssignedOffice();
      _loaded = true;
    } catch (_) {
      // Offline / unreachable — keep seeded defaults so the UI still renders.
    }
  }

  String get initials {
    final parts = employeeName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
