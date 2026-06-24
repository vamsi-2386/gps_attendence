import 'package:dio/dio.dart';
import 'dart:io';
import '../utils/constants.dart';

const String _defaultApiBaseUrl = 'http://10.79.79.4:8000';

/// API Service
///
/// Handles HTTP requests to FastAPI backend with Dio client
/// Implements face recognition, check-in, check-out, and leave management endpoints
class ApiService {
  static final ApiService _instance = ApiService._internal();
  late Dio _dio;
  String _baseUrl = _defaultApiBaseUrl;

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _initializeDio();
  }

  /// Initialize Dio instance
  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: AppConstants.connectionTimeout,
        receiveTimeout: AppConstants.readTimeout,
        sendTimeout: AppConstants.connectionTimeout,
        contentType: Headers.jsonContentType,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // Add interceptors
    _dio.interceptors.add(_LoggingInterceptor());
    _dio.interceptors.add(_ErrorInterceptor(_dio));
  }

  /// Set base URL for API
  void setBaseUrl(String baseUrl) {
    _baseUrl = baseUrl;
    _dio.options.baseUrl = baseUrl;
  }

  /// Get current base URL
  String getBaseUrl() => _baseUrl;

  /// Set authorization token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Clear authorization token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// GET request
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// POST request
  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// PUT request
  Future<Response<dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// PATCH request
  Future<Response<dynamic>> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// DELETE request
  Future<Response<dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Upload file
  Future<Response<dynamic>> uploadFile(
    String path, {
    required String filePath,
    Map<String, dynamic>? additionalFields,
    Options? options,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final formData = FormData.fromMap({
        if (additionalFields != null) ...additionalFields,
        'file': await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post(
        path,
        data: formData,
        options: options,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );

      return response;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Download file
  Future<void> downloadFile(
    String path, {
    required String savePath,
    Options? options,
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.download(
        path,
        savePath,
        options: options,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // HRMS SPECIFIC ENDPOINTS

  /// Face login - verify employee using face image
  Future<Map<String, dynamic>> faceLogin(
    List<int> imageBytes, {
    String? imageFormat = 'jpg',
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          imageBytes,
          filename: 'face_image.$imageFormat',
        ),
      });

      final response = await _dio.post(
        '/api/v1/face/login',
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Face login failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Submit a captured enrollment/verification face frame to the backend.
  ///
  /// Posts to the FastAPI face endpoint (`/api/employee/login`, multipart field
  /// `photo`) which runs the dlib pipeline and returns the match decision.
  /// Returns the decoded response; throws on transport errors so the caller can
  /// decide whether to treat a failure as fatal.
  Future<Map<String, dynamic>> verifyFaceFrame(
    List<int> imageBytes, {
    String imageFormat = 'jpg',
  }) async {
    final formData = FormData.fromMap({
      'photo': MultipartFile.fromBytes(
        imageBytes,
        filename: 'enroll_face.$imageFormat',
      ),
    });

    final response = await _dio.post('/api/employee/login', data: formData);
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {'status': response.statusCode, 'raw': response.data};
  }

  /// Check-in employee with face recognition and location
  Future<Map<String, dynamic>> checkIn({
    required String employeeId,
    required List<int> imageBytes,
    required double latitude,
    required double longitude,
    String? imageFormat = 'jpg',
  }) async {
    try {
      final formData = FormData.fromMap({
        'employee_id': employeeId,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'file': MultipartFile.fromBytes(
          imageBytes,
          filename: 'check_in_face.$imageFormat',
        ),
      });

      final response = await _dio.post(
        '/api/v1/attendance/check-in',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Check-in failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Check-out employee
  Future<Map<String, dynamic>> checkOut({
    required String employeeId,
    required List<int> imageBytes,
    required double latitude,
    required double longitude,
    String? imageFormat = 'jpg',
  }) async {
    try {
      final formData = FormData.fromMap({
        'employee_id': employeeId,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'file': MultipartFile.fromBytes(
          imageBytes,
          filename: 'check_out_face.$imageFormat',
        ),
      });

      final response = await _dio.post(
        '/api/v1/attendance/check-out',
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Check-out failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Get attendance history for employee
  Future<List<Map<String, dynamic>>> getAttendanceHistory({
    required String employeeId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 30,
  }) async {
    try {
      final queryParams = {
        'employee_id': employeeId,
        'limit': limit.toString(),
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      };

      final response = await _dio.get(
        '/api/v1/attendance/history',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['records'] ?? []);
      } else {
        throw Exception('Failed to fetch attendance history: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Apply for leave
  Future<Map<String, dynamic>> applyLeave({
    required String employeeId,
    required DateTime startDate,
    required DateTime endDate,
    required String leaveType,
    required String reason,
    String? attachmentUrl,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/leave/apply',
        data: {
          'employee_id': employeeId,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'leave_type': leaveType,
          'reason': reason,
          'attachment_url': attachmentUrl,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to apply leave: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Get leave history for employee
  Future<List<Map<String, dynamic>>> getLeaveHistory({
    required String employeeId,
    String? status,
    int limit = 30,
  }) async {
    try {
      final queryParams = {
        'employee_id': employeeId,
        'limit': limit.toString(),
        if (status != null) 'status': status,
      };

      final response = await _dio.get(
        '/api/v1/leave/history',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['records'] ?? []);
      } else {
        throw Exception('Failed to fetch leave history: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Health check endpoint
  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get(
        '/api/v1/health',
        options: Options(validateStatus: (status) => status! < 500),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Handle errors
  void _handleError(DioException error) {
    String message;

    if (error.type == DioExceptionType.connectionTimeout) {
      message = AppConstants.errorTimeOut;
    } else if (error.type == DioExceptionType.receiveTimeout) {
      message = AppConstants.errorTimeOut;
    } else if (error.type == DioExceptionType.sendTimeout) {
      message = AppConstants.errorTimeOut;
    } else if (error.type == DioExceptionType.badResponse) {
      if (error.response?.statusCode == 401) {
        message = AppConstants.errorUnauthorized;
      } else if (error.response?.statusCode == 500) {
        message = AppConstants.errorServerError;
      } else {
        message = 'Error: ${error.response?.statusCode}';
      }
    } else if (error.type == DioExceptionType.connectionError) {
      message = AppConstants.errorNetworkConnection;
    } else {
      message = 'Error: ${error.message}';
    }

    // Log error
    print('API Error: $message');
  }
}

/// Logging Interceptor
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('┌─────────────────────────────────────────');
    print('│ Request: ${options.method} ${options.path}');
    print('│ Headers: ${options.headers}');
    if (options.data != null) {
      if (options.data is FormData) {
        print('│ Data: <FormData with ${(options.data as FormData).fields.length} fields>');
      } else {
        print('│ Data: ${options.data}');
      }
    }
    print('└─────────────────────────────────────────');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('┌─────────────────────────────────────────');
    print('│ Response: ${response.statusCode} ${response.requestOptions.path}');
    if (response.data != null) {
      print('│ Data: ${response.data}');
    }
    print('└─────────────────────────────────────────');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('┌─────────────────────────────────────────');
    print('│ Error: ${err.message}');
    print('│ Path: ${err.requestOptions.path}');
    if (err.response != null) {
      print('│ Status: ${err.response?.statusCode}');
      print('│ Data: ${err.response?.data}');
    }
    print('└─────────────────────────────────────────');
    super.onError(err, handler);
  }
}

/// Error Interceptor for handling common errors and retries
class _ErrorInterceptor extends Interceptor {
  final Dio _dio;
  _ErrorInterceptor(this._dio);

  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const List<int> _retryableStatusCodes = [408, 429, 500, 502, 503, 504];

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final isRetryable = _retryableStatusCodes.contains(err.response?.statusCode) ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout;

    if (isRetryable && _retryCount < _maxRetries) {
      _retryCount++;
      print('Retrying request (${_retryCount}/$_maxRetries)...');

      await Future.delayed(Duration(milliseconds: 500 * _retryCount));

      try {
        final response = await _dio.fetch(err.requestOptions);

        _retryCount = 0;
        return handler.resolve(response);
      } catch (e) {
        return super.onError(err, handler);
      }
    } else {
      _retryCount = 0;
      return super.onError(err, handler);
    }
  }
}
