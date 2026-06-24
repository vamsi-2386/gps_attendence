import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Configuration
///
/// This file contains all Supabase connection settings and initialization logic.
/// Supports environment-based configuration from .env files or fallback to hardcoded values.
class SupabaseConfig {
  // Supabase project URL — same project the Streamlit admin portal uses.
  // Can be overridden at build time with --dart-define=SUPABASE_URL=...
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hpooyhqbooruuvhziwei.supabase.co',
  );

  // Supabase publishable/anon key (safe for client use).
  // Override with --dart-define=SUPABASE_ANON_KEY=...
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_4SyX2VTIPXR-T2DQhh4x0g_r1-K0OrT',
  );

  // Supabase service key (for admin operations) — optional.
  static const String supabaseServiceKey = String.fromEnvironment(
    'SUPABASE_SERVICE_KEY',
    defaultValue: '',
  );

  // Database Tables — names match the live schema used by the Streamlit backend.
  // NOTE: the companies table is intentionally spelled 'companys' in this DB.
  static const String tableEmployees = 'employees';
  static const String tableCompanies = 'companys';
  static const String tableSubjects = 'subjects';
  static const String tableProjectEmployees = 'project_employees';
  static const String tableAttendance = 'attendance_logs';
  static const String tableLeave = 'leave_requests';
  static const String tableOffices = 'offices';
  static const String tableVerificationEvents = 'verification_events';
  static const String tableAttendanceOverrides = 'attendance_overrides';
  static const String tableAuditLogs = 'audit_logs';

  // Storage Buckets
  static const String bucketFaceImages = 'face-images';
  static const String bucketVoiceData = 'voice-data';
  static const String bucketProfilePics = 'profile-pictures';
  static const String bucketDocuments = 'documents';

  // Supabase client instance
  static late SupabaseClient _client;

  /// Get the Supabase client instance
  static SupabaseClient get client {
    try {
      return Supabase.instance.client;
    } catch (e) {
      throw Exception(
        'Supabase not initialized. Call SupabaseConfig.initialize() first.',
      );
    }
  }

  /// Initialize Supabase connection
  /// Call this in your main.dart before running the app
  static Future<void> initialize() async {
    if (!isConfigured()) {
      throw Exception(
        'Supabase credentials not configured. '
        'Please configure SUPABASE_URL and SUPABASE_ANON_KEY in your .env file or app configuration.',
      );
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: RealtimeLogLevel.info,
        ),
      );

      _client = Supabase.instance.client;
      print('Supabase initialized successfully');
    } catch (e) {
      throw Exception('Failed to initialize Supabase: $e');
    }
  }

  /// Validation method to check if credentials are properly configured
  static bool isConfigured() {
    return supabaseUrl.isNotEmpty &&
        supabaseUrl != 'https://your-project.supabase.co' &&
        supabaseAnonKey.isNotEmpty &&
        supabaseAnonKey != 'your-project-anon-key';
  }

  /// Check if Supabase is initialized
  static bool get isInitialized {
    try {
      Supabase.instance.client;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Subscribe to realtime changes on attendance logs.
  /// attendance_logs has no company_id column, so this streams all rows
  /// (ordered newest-first); callers scope by employee/subject as needed.
  static Stream<List<Map<String, dynamic>>> subscribeToAttendanceLogs() {
    return client
        .from(tableAttendance)
        .stream(primaryKey: ['id']).order('timestamp', ascending: false);
  }

  /// Subscribe to realtime changes on leave requests for a company.
  static Stream<List<Map<String, dynamic>>> subscribeToLeaveRequests(
    int companyId,
  ) {
    return client
        .from(tableLeave)
        .stream(primaryKey: ['id']).eq('company_id', companyId);
  }

  /// Get public URL for a file in storage
  static String getPublicFileUrl(String bucketName, String filePath) {
    return client.storage.from(bucketName).getPublicUrl(filePath);
  }
}
