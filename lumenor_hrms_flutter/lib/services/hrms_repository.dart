import 'package:bcrypt/bcrypt.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Schema-correct data access for the live Supabase DB shared with the
/// Streamlit admin portal.
///
/// Returns plain maps/records (not the generic models) so the UI is decoupled
/// from model drift. Column names and the `companys` table spelling match the
/// real database exactly. All ids are ints.
class HrmsRepository {
  HrmsRepository._();
  static final HrmsRepository instance = HrmsRepository._();

  SupabaseClient get _db => SupabaseConfig.client;

  // ---- Employees -----------------------------------------------------------

  Future<Map<String, dynamic>?> employee(int employeeId) async {
    final rows = await _db
        .from('employees')
        .select('employee_id, employee_code, name, company_id, designation, daily_rate, role, office_id')
        .eq('employee_id', employeeId)
        .limit(1);
    final list = rows as List;
    return list.isEmpty ? null : list.first as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> companyEmployees(int companyId) async {
    final rows = await _db
        .from('employees')
        .select('employee_id, employee_code, name, designation, role, daily_rate')
        .eq('company_id', companyId)
        .order('name');
    return (rows as List).cast<Map<String, dynamic>>();
  }

  /// Look up an employee by their employee_code (used for code + face login).
  ///
  /// Orders by employee_id so the result is deterministic even if the DB ever
  /// holds two rows with the same code (it shouldn't — there is a UNIQUE
  /// constraint on employee_code — but a non-deterministic `limit(1)` was the
  /// root cause of "logged in but attendance not reflecting": login could
  /// resolve to a different id than the one that owned the records).
  Future<Map<String, dynamic>?> employeeByCode(String employeeCode) async {
    final rows = await _db
        .from('employees')
        .select(
            'employee_id, employee_code, name, company_id, designation, daily_rate, role, office_id')
        .eq('employee_code', employeeCode)
        .order('employee_id')
        .limit(1);
    final list = rows as List;
    return list.isEmpty ? null : list.first as Map<String, dynamic>;
  }

  // ---- Offices (admin work sites / geofences) ------------------------------

  /// All offices (geofenced work sites) for a company.
  Future<List<Map<String, dynamic>>> offices(int companyId) async {
    final rows = await _db
        .from('offices')
        .select('id, company_id, office_name, latitude, longitude, radius')
        .eq('company_id', companyId)
        .order('office_name');
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> office(int officeId) async {
    final rows = await _db
        .from('offices')
        .select('id, company_id, office_name, latitude, longitude, radius')
        .eq('id', officeId)
        .limit(1);
    final list = rows as List;
    return list.isEmpty ? null : list.first as Map<String, dynamic>;
  }

  /// The office assigned to an employee (employees.office_id). Falls back to the
  /// company's first office so the geofence still resolves if unassigned.
  Future<Map<String, dynamic>?> assignedOffice(
      int employeeId, int companyId) async {
    final emp = await employee(employeeId);
    final officeId = (emp?['office_id'] as num?)?.toInt();
    if (officeId != null) {
      final o = await office(officeId);
      if (o != null) return o;
    }
    final all = await offices(companyId);
    return all.isEmpty ? null : all.first;
  }

  Future<Map<String, dynamic>> createOffice({
    required int companyId,
    required String officeName,
    required double latitude,
    required double longitude,
    required int radius,
  }) async {
    final inserted = await _db.from('offices').insert({
      'company_id': companyId,
      'office_name': officeName,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
    }).select('id, company_id, office_name, latitude, longitude, radius');
    return (inserted as List).first as Map<String, dynamic>;
  }

  Future<void> updateOffice({
    required int officeId,
    required String officeName,
    required double latitude,
    required double longitude,
    required int radius,
  }) async {
    await _db.from('offices').update({
      'office_name': officeName,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
    }).eq('id', officeId);
  }

  /// Assign (or change) the office an employee belongs to.
  Future<void> setEmployeeOffice(int employeeId, int officeId) async {
    await _db
        .from('employees')
        .update({'office_id': officeId}).eq('employee_id', employeeId);
  }

  /// Create a new employee from the registration flow and assign them to the
  /// chosen site. Persists every collected field; `mobile`/`email` require the
  /// columns added via the registration SQL. Returns the new employee_id.
  Future<int> createEmployee({
    required String employeeCode,
    required String name,
    required int companyId,
    required String designation,
    required double dailyRate,
    String? mobile,
    String? email,
    int? subjectId,
    int? officeId,
    List<double>? faceEmbedding,
  }) async {
    // Guard against duplicate employee codes at the app layer (in addition to
    // the DB UNIQUE constraint). Two rows sharing a code make login resolve
    // non-deterministically and split one person's attendance across ids.
    final existing = await employeeByCode(employeeCode);
    if (existing != null) {
      throw Exception(
          'Employee code "$employeeCode" is already registered. Use a unique code.');
    }

    final payload = <String, dynamic>{
      'employee_code': employeeCode,
      'name': name,
      'company_id': companyId,
      'designation': designation,
      'daily_rate': dailyRate,
      'role': 'employee',
      if (mobile != null && mobile.isNotEmpty) 'mobile': mobile,
      if (email != null && email.isNotEmpty) 'email': email,
      if (officeId != null) 'office_id': officeId,
      if (faceEmbedding != null) 'face_embedding': faceEmbedding,
    };

    final inserted = await _db.from('employees').insert(payload).select(
        'employee_id, employee_code, name, company_id, designation, daily_rate, role');
    final row = (inserted as List).first as Map<String, dynamic>;
    final employeeId = row['employee_id'] as int;

    if (subjectId != null) {
      await assignToSite(employeeId, subjectId);
    }
    return employeeId;
  }

  /// Link an employee to a site (subjects row) via project_employees.
  Future<void> assignToSite(int employeeId, int subjectId) async {
    final existing = await _db
        .from('project_employees')
        .select('employee_id')
        .eq('employee_id', employeeId)
        .eq('subject_id', subjectId)
        .limit(1);
    if ((existing as List).isEmpty) {
      await _db.from('project_employees').insert({
        'employee_id': employeeId,
        'subject_id': subjectId,
      });
    }
  }

  // ---- Company -------------------------------------------------------------

  /// Resolve a company by its invite code (case-insensitive on the stored
  /// uppercase value). Returns null if no company matches.
  Future<Map<String, dynamic>?> companyByInviteCode(String code) async {
    final rows = await _db
        .from('companys')
        .select('id, name, company_invite_code, office_lat, office_lng, office_radius')
        .eq('company_invite_code', code.toUpperCase())
        .limit(1);
    final list = rows as List;
    return list.isEmpty ? null : list.first as Map<String, dynamic>;
  }

  /// Authenticate a company admin (Manager/HR) for the mobile admin dashboard.
  /// Mirrors the Streamlit `company_login`: looks up by username and verifies
  /// the entered password against the stored bcrypt hash. Returns the company
  /// row (with `company_id` mapped, hash stripped) on success, else null.
  ///
  /// This is the gate that stops anyone from opening the admin surface and
  /// self-approving flagged attendance. It is not a substitute for server-side
  /// RLS, but it closes the open-admin hole on the client.
  Future<Map<String, dynamic>?> companyLogin(
      String username, String password) async {
    final rows = await _db
        .from('companys')
        .select(
            'id, name, username, password, company_invite_code, office_lat, office_lng, office_radius')
        .eq('username', username)
        .limit(1);
    final list = rows as List;
    if (list.isEmpty) return null;
    final company = Map<String, dynamic>.from(list.first as Map);
    final hash = (company['password'] ?? '').toString();
    if (hash.isEmpty) return null;
    bool ok;
    try {
      ok = BCrypt.checkpw(password, hash);
    } catch (_) {
      ok = false; // malformed hash → deny
    }
    if (!ok) return null;
    company.remove('password'); // never keep the hash in memory longer than needed
    company['company_id'] = company['id'];
    return company;
  }

  /// Authenticate a Manager/HR staff account (staff_accounts table) — the same
  /// credentials created in the web dashboard. Used by the mobile admin login
  /// in addition to the company login. Returns the row (hash stripped, with
  /// `role` and `company_id`) on success, else null.
  Future<Map<String, dynamic>?> staffLogin(
      String username, String password) async {
    final rows = await _db
        .from('staff_accounts')
        .select('id, company_id, name, username, password, role')
        .eq('username', username)
        .limit(1);
    final list = rows as List;
    if (list.isEmpty) return null;
    final staff = Map<String, dynamic>.from(list.first as Map);
    final hash = (staff['password'] ?? '').toString();
    if (hash.isEmpty) return null;
    bool ok;
    try {
      ok = BCrypt.checkpw(password, hash);
    } catch (_) {
      ok = false;
    }
    if (!ok) return null;
    staff.remove('password');
    return staff;
  }

  Future<Map<String, dynamic>?> company(int companyId) async {
    final rows = await _db
        .from('companys')
        .select('id, name, company_invite_code, office_lat, office_lng, office_radius')
        .eq('id', companyId)
        .limit(1);
    final list = rows as List;
    return list.isEmpty ? null : list.first as Map<String, dynamic>;
  }

  // ---- Subjects / assigned sites ------------------------------------------

  Future<List<Map<String, dynamic>>> assignedSites(int companyId) async {
    final rows = await _db
        .from('subjects')
        .select('subject_id, subject_code, name, section, company_id')
        .eq('company_id', companyId)
        .order('subject_id');
    return (rows as List).cast<Map<String, dynamic>>();
  }

  // ---- Attendance ----------------------------------------------------------

  Future<List<Map<String, dynamic>>> attendanceLogs(int employeeId) async {
    final rows = await _db
        .from('attendance_logs')
        .select(_attendanceCols)
        .eq('employee_id', employeeId)
        .order('timestamp', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  /// Recent attendance rows for a whole company (admin dashboard). Ordered
  /// newest-first; callers filter to "today" in local time. Limited so the
  /// dashboard query stays light.
  Future<List<Map<String, dynamic>>> companyAttendanceRecent(int companyId,
      {int limit = 200}) async {
    final rows = await _db
        .from('attendance_logs')
        .select(_attendanceCols)
        .eq('company_id', companyId)
        .order('timestamp', ascending: false)
        .limit(limit);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  static const String _attendanceCols =
      'id, employee_id, employee_name, company_id, subject_id, site_id, '
      'timestamp, check_in_time, check_out_time, checkout_time, worked_hours, '
      'is_present, latitude, longitude, location_status, attendance_status, '
      'geofence_status, created_at';

  /// Insert a geofenced check-in record. Writes the new geofencing columns
  /// (employee_name, company_id, site_id, check_in_time, attendance_status,
  /// geofence_status) AND the legacy columns (timestamp, is_present,
  /// location_status, subject_id) so the Streamlit portal keeps working.
  Future<Map<String, dynamic>> markAttendance({
    required int employeeId,
    String? employeeName,
    int? companyId,
    int? subjectId,
    int? siteId,
    required double latitude,
    required double longitude,
    String attendanceStatus = 'Present',
    String geofenceStatus = 'Inside',
    bool present = true,
    String? checkInIso,
  }) async {
    // Store timestamps in UTC (with offset) so worked-hours math is timezone-
    // safe; screens convert to local for display.
    final nowIso = checkInIso ?? DateTime.now().toUtc().toIso8601String();
    final payload = <String, dynamic>{
      'employee_id': employeeId,
      if (employeeName != null) 'employee_name': employeeName,
      if (companyId != null) 'company_id': companyId,
      if (subjectId != null) 'subject_id': subjectId,
      if (siteId != null) 'site_id': siteId,
      'timestamp': nowIso,
      'check_in_time': nowIso,
      // Outside-geofence (flagged) check-ins are NOT counted present until HR
      // approves — so is_present follows the inside/outside decision.
      'is_present': present,
      'latitude': latitude,
      'longitude': longitude,
      'location_status': attendanceStatus,
      'attendance_status': attendanceStatus,
      'geofence_status': geofenceStatus,
    };
    final inserted =
        await _db.from('attendance_logs').insert(payload).select(_attendanceCols);
    return (inserted as List).first as Map<String, dynamic>;
  }

  /// Record clock-out: sets check_out_time (+ legacy checkout_time) and the
  /// computed worked_hours on an existing attendance row.
  Future<void> clockOut({
    required int attendanceId,
    required String checkOutIso,
    required double workedHours,
  }) async {
    await _db.from('attendance_logs').update({
      'check_out_time': checkOutIso,
      'checkout_time': checkOutIso,
      'worked_hours': double.parse(workedHours.toStringAsFixed(2)),
    }).eq('id', attendanceId);
  }

  /// Pending HR-review queue: outside-geofence / flagged attendance for a
  /// company that hasn't been approved or rejected yet.
  Future<List<Map<String, dynamic>>> flaggedAttendance(int companyId) async {
    final rows = await _db
        .from('attendance_logs')
        .select(_attendanceCols)
        .eq('company_id', companyId)
        .or('attendance_status.eq.Flagged,geofence_status.eq.Outside')
        .order('created_at', ascending: false);
    // Exclude records already resolved by HR.
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .where((r) =>
            r['attendance_status'] != 'Present' &&
            r['attendance_status'] != 'Rejected')
        .toList();
  }

  /// HR decision on a flagged attendance record.
  /// Approve → marks Present (counts as attendance everywhere).
  /// Reject  → marks Rejected, stays not-present (still flagged/absent).
  Future<void> reviewFlaggedAttendance(int attendanceId, bool approved) async {
    final patch = approved
        ? {
            'is_present': true,
            'attendance_status': 'Present',
            'location_status': 'Present',
          }
        : {
            'is_present': false,
            'attendance_status': 'Rejected',
            'location_status': 'Rejected',
          };
    await _db.from('attendance_logs').update(patch).eq('id', attendanceId);
  }

  // ---- Site management (admin) --------------------------------------------

  /// A site (subjects row) including its geofence configuration.
  Future<Map<String, dynamic>?> siteWithGeofence(int subjectId) async {
    final rows = await _db
        .from('subjects')
        .select('subject_id, subject_code, name, section, latitude, longitude, radius')
        .eq('subject_id', subjectId)
        .limit(1);
    final list = rows as List;
    return list.isEmpty ? null : list.first as Map<String, dynamic>;
  }

  /// All sites for a company with geofence columns (admin management list).
  Future<List<Map<String, dynamic>>> companySites(int companyId) async {
    final rows = await _db
        .from('subjects')
        .select('subject_id, subject_code, name, section, latitude, longitude, radius')
        .eq('company_id', companyId)
        .order('name');
    return (rows as List).cast<Map<String, dynamic>>();
  }

  /// Company-level fallback geofence (from companys office_lat/lng/radius).
  Future<Map<String, dynamic>?> companyGeofence(int companyId) async {
    final rows = await _db
        .from('companys')
        .select('office_lat, office_lng, office_radius')
        .eq('id', companyId)
        .limit(1);
    final list = rows as List;
    return list.isEmpty ? null : list.first as Map<String, dynamic>;
  }

  /// Create a new work site with its geofence.
  Future<Map<String, dynamic>> createSite({
    required int companyId,
    required String name,
    required String subjectCode,
    String? section,
    required double latitude,
    required double longitude,
    required int radius,
  }) async {
    final inserted = await _db.from('subjects').insert({
      'company_id': companyId,
      'name': name,
      'subject_code': subjectCode,
      if (section != null && section.isNotEmpty) 'section': section,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
    }).select('subject_id, subject_code, name, section, latitude, longitude, radius');
    return (inserted as List).first as Map<String, dynamic>;
  }

  /// Update a site's geofence (and optionally its name/section).
  Future<void> updateSite({
    required int subjectId,
    String? name,
    String? section,
    required double latitude,
    required double longitude,
    required int radius,
  }) async {
    await _db.from('subjects').update({
      if (name != null) 'name': name,
      if (section != null) 'section': section,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
    }).eq('subject_id', subjectId);
  }

  /// The employee's primary assigned site (subjects row). Falls back to the
  /// company's first site if the employee has no explicit assignment.
  Future<Map<String, dynamic>?> primarySite(
      int employeeId, int companyId) async {
    final pe = await _db
        .from('project_employees')
        .select('subject_id')
        .eq('employee_id', employeeId)
        .limit(1);
    int? subjectId;
    if ((pe as List).isNotEmpty) {
      subjectId = (pe.first as Map)['subject_id'] as int?;
    }
    if (subjectId == null) {
      final sites = await assignedSites(companyId);
      return sites.isEmpty ? null : sites.first;
    }
    final sub = await _db
        .from('subjects')
        .select('subject_id, name, section')
        .eq('subject_id', subjectId)
        .limit(1);
    final list = sub as List;
    return list.isEmpty ? null : list.first as Map<String, dynamic>;
  }

  /// The most recent attendance log dated today (local day), if any.
  /// Timestamps are stored in UTC, so convert to local before comparing the
  /// calendar day — this is what enforces one attendance record per local day.
  Future<Map<String, dynamic>?> todayAttendance(int employeeId) async {
    final logs = await attendanceLogs(employeeId);
    final now = DateTime.now();
    for (final log in logs) {
      final ts =
          DateTime.tryParse('${log['check_in_time'] ?? log['timestamp']}')
              ?.toLocal();
      if (ts != null &&
          ts.year == now.year &&
          ts.month == now.month &&
          ts.day == now.day) {
        return log;
      }
    }
    return null;
  }

  // ---- Leave ---------------------------------------------------------------

  Future<List<Map<String, dynamic>>> employeeLeaves(int employeeId) async {
    final rows = await _db
        .from('leave_requests')
        .select('id, employee_id, company_id, start_date, end_date, reason, status, created_at')
        .eq('employee_id', employeeId)
        .order('created_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> companyLeaves(int companyId,
      {String? status}) async {
    var q = _db
        .from('leave_requests')
        .select('id, employee_id, company_id, start_date, end_date, reason, status, created_at')
        .eq('company_id', companyId);
    if (status != null) q = q.eq('status', status);
    final rows = await q.order('created_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  /// Approved-leave days used this year (mirrors the Streamlit balance logic:
  /// 20 annual days minus inclusive approved day spans).
  Future<int> leaveBalance(int employeeId) async {
    final rows = await _db
        .from('leave_requests')
        .select('start_date, end_date')
        .eq('employee_id', employeeId)
        .eq('status', 'Approved');
    var used = 0;
    for (final r in (rows as List)) {
      final s = DateTime.tryParse('${r['start_date']}');
      final e = DateTime.tryParse('${r['end_date']}');
      if (s != null && e != null) used += e.difference(s).inDays + 1;
    }
    return 20 - used;
  }

  Future<void> applyLeave({
    required int employeeId,
    required int companyId,
    required String startDate,
    required String endDate,
    required String reason,
  }) async {
    await _db.from('leave_requests').insert({
      'employee_id': employeeId,
      'company_id': companyId,
      'start_date': startDate,
      'end_date': endDate,
      'reason': reason,
      'status': 'Pending',
    });
  }

  /// status must be 'Approved' or 'Rejected' (DB uses capitalized values).
  Future<void> setLeaveStatus(int leaveId, String status) async {
    await _db.from('leave_requests').update({'status': status}).eq('id', leaveId);
  }

  // ---- Employee name lookup (for admin lists keyed by employee_id) ---------

  Future<Map<int, String>> employeeNames(int companyId) async {
    final emps = await companyEmployees(companyId);
    return {
      for (final e in emps) (e['employee_id'] as int): (e['name'] ?? '').toString()
    };
  }
}
