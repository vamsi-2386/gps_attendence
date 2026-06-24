import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/employee.dart';
import '../models/company.dart';
import '../models/attendance.dart';
import '../models/leave.dart';
import '../models/office.dart';

/// Supabase Service
///
/// Handles all Supabase database and authentication operations
/// Implements business logic for employee, attendance, leave, and company management
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  /// Initialize Supabase connection
  static Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured()) {
      throw Exception(
        'Supabase credentials not configured. '
        'Please set SUPABASE_URL and SUPABASE_ANON_KEY in supabase_config.dart',
      );
    }

    try {
      await SupabaseConfig.initialize();
      print('SupabaseService initialized successfully');
    } catch (e) {
      throw Exception('Failed to initialize SupabaseService: $e');
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated {
    return client.auth.currentUser != null;
  }

  /// Get current authenticated user
  User? get currentUser {
    return client.auth.currentUser;
  }

  /// Get current user ID
  String? get currentUserId {
    return client.auth.currentUser?.id;
  }

  /// Fetch data from a table
  Future<List<Map<String, dynamic>>> fetchFromTable(
    String tableName, {
    String? select,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    try {
      var filterBuilder = client.from(tableName).select(select ?? '*');

      // Apply filters (eq keeps the FilterBuilder type)
      if (filters != null) {
        filters.forEach((key, value) {
          filterBuilder = filterBuilder.eq(key, value);
        });
      }

      // order()/limit() return a TransformBuilder, so hold the chain as dynamic
      dynamic query = filterBuilder;
      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }
      if (limit != null) {
        query = query.limit(limit);
      }

      final result = await query;
      return (result as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Error fetching from $tableName: $e');
    }
  }

  /// Insert data into a table
  Future<Map<String, dynamic>> insertIntoTable(
    String tableName,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await client
          .from(tableName)
          .insert(data)
          .select()
          .single();

      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error inserting into $tableName: $e');
    }
  }

  /// Update data in a table
  Future<Map<String, dynamic>> updateInTable(
    String tableName,
    Map<String, dynamic> data,
    String columnName,
    dynamic value,
  ) async {
    try {
      final response = await client
          .from(tableName)
          .update(data)
          .eq(columnName, value)
          .select()
          .single();

      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error updating $tableName: $e');
    }
  }

  /// Delete data from a table
  Future<void> deleteFromTable(
    String tableName,
    String columnName,
    dynamic value,
  ) async {
    try {
      await client.from(tableName).delete().eq(columnName, value);
    } catch (e) {
      throw Exception('Error deleting from $tableName: $e');
    }
  }

  /// Execute RPC call
  Future<dynamic> executeRpc(String functionName, {Map<String, dynamic>? params}) async {
    try {
      return await client.rpc(functionName, params: params);
    } catch (e) {
      throw Exception('Error executing RPC $functionName: $e');
    }
  }

  /// Listen to realtime changes on a table.
  ///
  /// Uses the Supabase realtime stream API; emits the full row set each time
  /// any row matching [primaryKey] changes (INSERT/UPDATE/DELETE).
  Stream<List<Map<String, dynamic>>> listenToTable(
    String tableName, {
    List<String> primaryKey = const ['id'],
  }) {
    return client.from(tableName).stream(primaryKey: primaryKey);
  }

  /// Upload file to storage
  Future<String> uploadFile(
    String bucketName,
    String filePath,
    List<int> fileBytes,
  ) async {
    try {
      await client.storage.from(bucketName).uploadBinary(
            filePath,
            Uint8List.fromList(fileBytes),
          );

      final publicUrl = client.storage
          .from(bucketName)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Error uploading file: $e');
    }
  }

  /// Download file from storage
  Future<List<int>> downloadFile(
    String bucketName,
    String filePath,
  ) async {
    try {
      return await client.storage
          .from(bucketName)
          .download(filePath);
    } catch (e) {
      throw Exception('Error downloading file: $e');
    }
  }

  /// Delete file from storage
  Future<void> deleteFile(
    String bucketName,
    String filePath,
  ) async {
    try {
      await client.storage
          .from(bucketName)
          .remove([filePath]);
    } catch (e) {
      throw Exception('Error deleting file: $e');
    }
  }

  /// Get public URL of a file
  String getPublicFileUrl(String bucketName, String filePath) {
    return client.storage
        .from(bucketName)
        .getPublicUrl(filePath);
  }

  /// Close connection (if needed)
  Future<void> dispose() async {
    // Add any cleanup code here
  }

  // EMPLOYEE OPERATIONS

  /// Get employee by ID
  Future<Employee> getEmployee(String employeeId) async {
    try {
      final response = await client
          .from(SupabaseConfig.tableEmployees)
          .select()
          .eq('id', employeeId)
          .single();

      return Employee.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch employee: $e');
    }
  }

  /// Get all employees for a company
  Future<List<Employee>> getCompanyEmployees(String companyId) async {
    try {
      final response = await client
          .from(SupabaseConfig.tableEmployees)
          .select()
          .eq('company_id', companyId)
          .eq('is_active', true);

      return (response as List)
          .map((e) => Employee.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch company employees: $e');
    }
  }

  /// Create or update employee
  Future<Employee> upsertEmployee(Employee employee) async {
    try {
      final response = await client
          .from(SupabaseConfig.tableEmployees)
          .upsert(employee.toJson())
          .select()
          .single();

      return Employee.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to upsert employee: $e');
    }
  }

  // ATTENDANCE OPERATIONS

  /// Get attendance records for an employee
  Future<List<Attendance>> getEmployeeAttendance(
    String employeeId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = client
          .from(SupabaseConfig.tableAttendance)
          .select()
          .eq('employee_id', employeeId);

      if (startDate != null) {
        query = query.gte('check_in_time', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('check_in_time', endDate.toIso8601String());
      }

      final response = await query.order('check_in_time', ascending: false);

      return (response as List)
          .map((e) => Attendance.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch employee attendance: $e');
    }
  }

  /// Create attendance record
  Future<Attendance> createAttendance(Attendance attendance) async {
    try {
      final response = await client
          .from(SupabaseConfig.tableAttendance)
          .insert(attendance.toJson())
          .select()
          .single();

      return Attendance.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create attendance record: $e');
    }
  }

  /// Update attendance (check-out)
  Future<Attendance> updateAttendance(Attendance attendance) async {
    try {
      final response = await client
          .from(SupabaseConfig.tableAttendance)
          .update(attendance.toJson())
          .eq('id', attendance.id)
          .select()
          .single();

      return Attendance.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update attendance: $e');
    }
  }

  // LEAVE OPERATIONS

  /// Get leave requests for an employee
  Future<List<LeaveRequest>> getEmployeeLeaves(
    String employeeId, {
    String? status,
  }) async {
    try {
      var query = client
          .from(SupabaseConfig.tableLeave)
          .select()
          .eq('employee_id', employeeId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('start_date', ascending: false);

      return (response as List)
          .map((e) => LeaveRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch employee leaves: $e');
    }
  }

  /// Get leave requests for approval (for managers/HR)
  Future<List<LeaveRequest>> getPendingLeaveRequests(String companyId) async {
    try {
      final response = await client
          .from(SupabaseConfig.tableLeave)
          .select()
          .eq('company_id', companyId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => LeaveRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch pending leave requests: $e');
    }
  }

  /// Apply for leave
  Future<LeaveRequest> applyLeave(LeaveRequest leaveRequest) async {
    try {
      final response = await client
          .from(SupabaseConfig.tableLeave)
          .insert(leaveRequest.toJson())
          .select()
          .single();

      return LeaveRequest.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to apply for leave: $e');
    }
  }

  /// Approve leave request
  Future<LeaveRequest> approveLeave(
    String leaveId, {
    required String approverEmployeeId,
    String? approverComments,
  }) async {
    try {
      final response = await client
          .from(SupabaseConfig.tableLeave)
          .update({
            'status': 'approved',
            'approved_by_employee_id': approverEmployeeId,
            'approval_date': DateTime.now().toIso8601String(),
            'approver_comments': approverComments,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', leaveId)
          .select()
          .single();

      return LeaveRequest.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to approve leave: $e');
    }
  }

  /// Reject leave request
  Future<LeaveRequest> rejectLeave(
    String leaveId, {
    required String approverEmployeeId,
    String? approverComments,
  }) async {
    try {
      final response = await client
          .from(SupabaseConfig.tableLeave)
          .update({
            'status': 'rejected',
            'approved_by_employee_id': approverEmployeeId,
            'approval_date': DateTime.now().toIso8601String(),
            'approver_comments': approverComments,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', leaveId)
          .select()
          .single();

      return LeaveRequest.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to reject leave: $e');
    }
  }

  // COMPANY OPERATIONS

  /// Get company by ID
  Future<Company> getCompany(String companyId) async {
    try {
      final response = await client
          .from(SupabaseConfig.tableCompanies)
          .select()
          .eq('id', companyId)
          .single();

      return Company.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch company: $e');
    }
  }

  // OFFICE OPERATIONS

  /// Get all offices for a company
  Future<List<Office>> getCompanyOffices(String companyId) async {
    try {
      final response = await client
          .from(SupabaseConfig.tableOffices)
          .select()
          .eq('company_id', companyId)
          .eq('is_active', true);

      return (response as List)
          .map((e) => Office.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch company offices: $e');
    }
  }

  /// Get office by ID
  Future<Office> getOffice(String officeId) async {
    try {
      final response = await client
          .from(SupabaseConfig.tableOffices)
          .select()
          .eq('id', officeId)
          .single();

      return Office.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch office: $e');
    }
  }

  // REALTIME SUBSCRIPTIONS

  /// Subscribe to attendance changes (emits the latest row set on every change).
  Stream<List<Attendance>> subscribeToAttendance() {
    return SupabaseConfig.subscribeToAttendanceLogs()
        .map((rows) => rows.map((data) => Attendance.fromJson(data)).toList());
  }

  /// Subscribe to leave request changes for a company.
  Stream<List<LeaveRequest>> subscribeToLeaveRequests(int companyId) {
    return SupabaseConfig.subscribeToLeaveRequests(companyId)
        .map((rows) => rows.map((data) => LeaveRequest.fromJson(data)).toList());
  }
}
