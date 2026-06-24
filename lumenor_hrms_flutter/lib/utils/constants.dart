/// Application Constants
///
/// Centralized constants for the entire application
class AppConstants {
  // Application Info
  static const String appName = 'Lumenor HRMS';
  static const String appVersion = '1.0.0';
  static const String appBuild = '1';

  // API & Services
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration readTimeout = Duration(seconds: 30);

  // Attendance
  static const double geofenceDefaultRadius = 100.0; // meters
  static const int checkInEarlyMinutes = 15; // minutes before shift start
  static const int lateArrivalMinutes = 10; // minutes after shift start

  // Face Recognition
  static const int minFaceFrameSize = 100; // minimum pixel size
  static const double minFaceConfidence = 0.7; // minimum confidence threshold
  static const int maxFaceRegistrationAttempts = 5;

  // Leave Types
  static const List<String> leaveTypes = [
    'casual',
    'sick',
    'earned',
    'unpaid',
    'maternity',
  ];

  // Employee Roles
  static const String roleEmployee = 'employee';
  static const String roleManager = 'manager';
  static const String roleHR = 'hr';
  static const String roleAdmin = 'admin';

  // Attendance Statuses
  static const String statusCheckedIn = 'checked_in';
  static const String statusCheckedOut = 'checked_out';
  static const String statusAbsent = 'absent';
  static const String statusLate = 'late';

  // Leave Statuses
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';
  static const String statusCancelled = 'cancelled';

  // Storage Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyEmployeeId = 'employee_id';
  static const String keyCompanyId = 'company_id';
  static const String keyUserRole = 'user_role';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyLastSyncTime = 'last_sync_time';

  // Error Messages
  static const String errorNetworkConnection = 'Network connection error. Please check your internet.';
  static const String errorUnauthorized = 'Unauthorized. Please login again.';
  static const String errorServerError = 'Server error. Please try again later.';
  static const String errorInvalidInput = 'Invalid input. Please check your entries.';
  static const String errorTimeOut = 'Request timeout. Please try again.';
  static const String errorGeofenceOutside = 'You are outside the office geofence.';
  static const String errorFaceNotVerified = 'Face verification failed. Please try again.';
  static const String errorCameraPermission = 'Camera permission is required.';
  static const String errorLocationPermission = 'Location permission is required.';

  // Success Messages
  static const String successCheckedIn = 'You have successfully checked in.';
  static const String successCheckedOut = 'You have successfully checked out.';
  static const String successLeaveApplied = 'Leave request submitted successfully.';
  static const String successProfileUpdated = 'Profile updated successfully.';

  // Date Formats
  static const String dateFormatDisplay = 'dd MMM yyyy';
  static const String dateFormatServer = 'yyyy-MM-dd';
  static const String timeFormatDisplay = 'hh:mm a';
  static const String dateTimeFormatDisplay = 'dd MMM yyyy hh:mm a';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxRetries = 3;

  // UI
  static const int animationDurationMs = 300;
  static const int snackBarDurationMs = 2000;
}
