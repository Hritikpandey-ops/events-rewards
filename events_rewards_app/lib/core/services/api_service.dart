import 'dart:io';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logging/logging.dart';
import '../constants/api_constants.dart';
import 'storage_service.dart';
import 'dart:convert';

class ApiService {
  static ApiService? _instance;
  static Dio? _dio;
  static final Logger _logger = Logger('ApiService');

  ApiService._();

  static ApiService get instance {
    _instance ??= ApiService._();
    return _instance!;
  }

  static Future<void> init() async {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: ApiConstants.connectionTimeout),
      receiveTimeout: const Duration(seconds: ApiConstants.receiveTimeout),
      sendTimeout: const Duration(seconds: ApiConstants.sendTimeout),
      headers: ApiConstants.defaultHeaders,
    ));

    // Add interceptors
    _dio!.interceptors.add(AuthInterceptor());
    _dio!.interceptors.add(LoggingInterceptor());
    _dio!.interceptors.add(ErrorInterceptor());
  }

  Dio get dio {
    if (_dio == null) {
      throw Exception('ApiService not initialized. Call ApiService.init() first.');
    }
    return _dio!;
  }

  // Authentication endpoints
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await dio.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await dio.post(ApiConstants.register, data: userData);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final refreshToken = await StorageService.instance.getRefreshToken();
      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final response = await dio.post(ApiConstants.refresh, data: {
        ApiConstants.refreshTokenKey: refreshToken,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await dio.post(ApiConstants.logout);
    } catch (e) {
      // Ignore logout errors, clear local data anyway
      _logger.warning('Error during logout API call', e);
    } finally {
      await StorageService.instance.clearAuthToken();
      await StorageService.instance.clearRefreshToken();
    }
  }

  // User profile endpoints
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await dio.get(ApiConstants.profile);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await dio.put(ApiConstants.updateProfile, data: profileData);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // File upload endpoints
  Future<Map<String, dynamic>> uploadSelfie(File file) async {
    try {
      // Validate file size
      final fileSize = await file.length();
      if (fileSize > ApiConstants.maxImageSize) {
        throw Exception('Image file too large. Maximum size is ${ApiConstants.maxImageSize ~/ (1024 * 1024)}MB');
      }

      final formData = FormData.fromMap({
        'selfie': await MultipartFile.fromFile(
          file.path, 
          filename: 'selfie.jpg',
        ),
      });

      final response = await dio.post(
        ApiConstants.uploadSelfie, 
        data: formData,
        options: Options(
          headers: ApiConstants.multipartHeaders,
        ),
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> uploadVoice(File file) async {
    try {
      // Validate file size
      final fileSize = await file.length();
      if (fileSize > ApiConstants.maxAudioSize) {
        throw Exception('Audio file too large. Maximum size is ${ApiConstants.maxAudioSize ~/ (1024 * 1024)}MB');
      }

      final formData = FormData.fromMap({
        'voice': await MultipartFile.fromFile(
          file.path, 
          filename: 'voice.m4a',
        ),
      });

      final response = await dio.post(
        ApiConstants.uploadVoice, 
        data: formData,
        options: Options(
          headers: ApiConstants.multipartHeaders,
        ),
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Identity verification
  Future<Map<String, dynamic>> verifyIdentity() async {
    try {
      final response = await dio.post(ApiConstants.verifyIdentity);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Events endpoints
  Future<Map<String, dynamic>> getEvents({
    int page = ApiConstants.defaultPage,
    int limit = ApiConstants.defaultPageSize,
    String? category,
    String? location,
    String? search,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        ApiConstants.pageParam: page,
        ApiConstants.limitParam: limit,
      };

      if (category != null) queryParameters[ApiConstants.categoryParam] = category;
      if (location != null) queryParameters[ApiConstants.locationParam] = location;
      if (search != null) queryParameters[ApiConstants.searchParam] = search;

      final response = await dio.get(
        ApiConstants.events, 
        queryParameters: queryParameters,
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getEvent(String eventId) async {
    try {
      final response = await dio.get(ApiConstants.eventDetails(eventId));
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> registerForEvent(String eventId) async {
    try {
      final response = await dio.post(ApiConstants.registerEvent(eventId));
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> unregisterFromEvent(String eventId) async {
    try {
      final response = await dio.delete(ApiConstants.unregisterEvent(eventId));
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // News endpoints
  Future<Map<String, dynamic>> getNews({
    int page = ApiConstants.defaultPage,
    int limit = ApiConstants.defaultPageSize,
    String? category,
    String? search,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        ApiConstants.pageParam: page,
        ApiConstants.limitParam: limit,
      };

      if (category != null) queryParameters[ApiConstants.categoryParam] = category;
      if (search != null) queryParameters[ApiConstants.searchParam] = search;

      final response = await dio.get(
        ApiConstants.news, 
        queryParameters: queryParameters,
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getNewsArticle(String newsId) async {
    try {
      final response = await dio.get(ApiConstants.newsDetails(newsId));
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Events endpoints
  Future<Map<String, dynamic>> createEvent(Map<String, dynamic> eventData) async {
    try {
      print("DEBUG: Sending to ${ApiConstants.events}");
      print("DEBUG: Data: ${jsonEncode(eventData)}");
      
      final response = await dio.post(
        ApiConstants.events, 
        data: eventData,
      );
      
      print("DEBUG: Success Response: ${response.data}");
      return response.data;
      
    } on DioException catch (e) {
      print("DEBUG: DioException: ${e.response?.statusCode}");
      print("DEBUG: Response data: ${e.response?.data}");
      
      // Handle 400 Bad Request specifically
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          // Return the actual error from backend
          return {
            'success': false,
            'message': errorData['message'] ?? errorData['error'] ?? 'Validation failed',
            'data': errorData
          };
        }
      }
      
      // For other errors, use the existing error handler
      throw _handleError(e);
    } catch (e) {
      print("DEBUG: Generic Exception: $e");
      throw Exception("An unexpected error occurred: $e");
    }
  }

    // UPDATE EVENT - PUT /events/:id
  Future<Map<String, dynamic>> updateEvent(String eventId, Map<String, dynamic> updateData) async {
    try {
      final response = await dio.put(
        ApiConstants.eventDetails(eventId), // Use your constant with parameter
        data: updateData,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );
      
      return response.data;
    } on DioException catch (e) {
      print('DioException in updateEvent: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('Exception in updateEvent: $e');
      rethrow;
    }
  }

  // DELETE EVENT - DELETE /events/:id
  Future<Map<String, dynamic>> deleteEvent(String eventId) async {
    try {
      final response = await dio.delete(
        ApiConstants.eventDetails(eventId), // Use your constant with parameter
      );
      return response.data;
    } on DioException catch (e) {
      print('DioException in deleteEvent: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('Exception in deleteEvent: $e');
      rethrow;
    }
  }

  // GET USER'S CREATED EVENTS - GET /events/user
  Future<Map<String, dynamic>> getMyEvents({int page = 1, int limit = 20}) async {
    try {
      final response = await dio.get(
        ApiConstants.userEvents, // Use your constant
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      
      return response.data;
    } on DioException catch (e) {
      print('DioException in getMyEvents: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('Exception in getMyEvents: $e');
      rethrow;
    }
  }


  // Lucky draw endpoints
  Future<Map<String, dynamic>> getLuckyDrawConfig() async {
    try {
      final response = await dio.get(ApiConstants.luckyDrawConfig);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> spinWheel() async {
    try {
      final response = await dio.post(ApiConstants.spinWheel);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getUserRewards() async {
    try {
      final response = await dio.get(ApiConstants.userRewards);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> claimReward(String rewardId) async {
    try {
      final response = await dio.post(ApiConstants.claimReward(rewardId));
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // UI Config endpoint
  Future<Map<String, dynamic>> getUIConfig() async {
    try {
      final response = await dio.get(ApiConstants.uiConfig);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Device info endpoint
  Future<Map<String, dynamic>> updateDeviceInfo(Map<String, dynamic> deviceInfo) async {
    try {
      final response = await dio.put(ApiConstants.deviceInfo, data: deviceInfo);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Location endpoint
  Future<Map<String, dynamic>> updateLocation(Map<String, dynamic> locationData) async {
    try {
      final response = await dio.put(ApiConstants.location, data: locationData);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Health check
  Future<bool> healthCheck() async {
    try {
      final response = await dio.get(
        ApiConstants.healthCheck,
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode == ApiConstants.statusSuccess;
    } catch (e) {
      return false;
    }
  }

  // Error handling
  Exception _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return Exception(ApiConstants.timeoutError);
        case DioExceptionType.sendTimeout:
          return Exception(ApiConstants.timeoutError);
        case DioExceptionType.receiveTimeout:
          return Exception(ApiConstants.timeoutError);
        case DioExceptionType.badResponse:
          return _handleResponseError(error);
        case DioExceptionType.cancel:
          return Exception('Request cancelled');
        case DioExceptionType.unknown:
          if (error.error is SocketException) {
            return Exception(ApiConstants.networkError);
          }
          return Exception(ApiConstants.unknownError);
        default:
          return Exception(ApiConstants.unknownError);
      }
    } else {
      return Exception('${ApiConstants.unknownError}: ${error.toString()}');
    }
  }

  Exception _handleResponseError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    switch (statusCode) {
      case ApiConstants.statusUnauthorized:
        return Exception(ApiConstants.unauthorizedError);
      case ApiConstants.statusForbidden:
        return Exception(ApiConstants.forbiddenError);
      case ApiConstants.statusNotFound:
        return Exception(ApiConstants.notFoundError);
      case ApiConstants.statusUnprocessableEntity:
        // Handle validation errors
        if (data is Map<String, dynamic> && data.containsKey('errors')) {
          final errors = data['errors'] as Map<String, dynamic>;
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            return Exception(firstError.first.toString());
          }
        }
        return Exception(ApiConstants.validationError);
      case ApiConstants.statusInternalServerError:
        return Exception(ApiConstants.serverError);
      case ApiConstants.statusTooManyRequests:
        return Exception('Too many requests. Please try again later.');
      default:
        final message = data is Map<String, dynamic> 
            ? (data['message'] ?? data['error'] ?? ApiConstants.unknownError)
            : ApiConstants.unknownError;
        return Exception(message.toString());
    }
  }

  // Network connectivity check
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      return await healthCheck();
    } catch (e) {
      return false;
    }
  }
}

// Auth Interceptor
class AuthInterceptor extends Interceptor {
  final Logger _logger = Logger('AuthInterceptor');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await StorageService.instance.getAuthToken();

    if (token != null) {
      options.headers[ApiConstants.authHeaderKey] = '${ApiConstants.bearerPrefix}$token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == ApiConstants.statusUnauthorized) {
      try {
        final apiService = ApiService.instance;
        final refreshResponse = await apiService.refreshToken();

        if (refreshResponse['success'] == true) {
          final newToken = refreshResponse['data'][ApiConstants.accessTokenKey] as String;
          final newRefreshToken = refreshResponse['data'][ApiConstants.refreshTokenKey] as String;

          await StorageService.instance.saveAuthToken(newToken);
          await StorageService.instance.saveRefreshToken(newRefreshToken);

          // Retry original request
          err.requestOptions.headers[ApiConstants.authHeaderKey] = '${ApiConstants.bearerPrefix}$newToken';
          final response = await apiService.dio.fetch(err.requestOptions);
          handler.resolve(response);
          return;
        }
      } catch (e) {
        _logger.severe('Token refresh failed', e);
        await StorageService.instance.clearAuthToken();
        await StorageService.instance.clearRefreshToken();
      }
    }

    handler.next(err);
  }
}

// Logging Interceptor
class LoggingInterceptor extends Interceptor {
  final Logger _logger = Logger('LoggingInterceptor');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (ApiConstants.enableNetworkLogging) {
      _logger.info('[REQUEST] ${options.method} ${options.uri}');
      if (ApiConstants.enableDetailedLogging) {
        _logger.fine('Headers: ${options.headers}');
        if (options.data != null) {
          _logger.fine('Data: ${options.data}');
        }
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (ApiConstants.enableNetworkLogging) {
      _logger.info('[RESPONSE] ${response.statusCode} ${response.requestOptions.uri}');
      if (ApiConstants.enableDetailedLogging) {
        _logger.fine('Data: ${response.data}');
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (ApiConstants.enableLogging) {
      _logger.warning('[ERROR] ${err.requestOptions.method} ${err.requestOptions.uri}');
      _logger.warning('Status: ${err.response?.statusCode}');
      _logger.warning('Message: ${err.message}');
      if (ApiConstants.enableDetailedLogging && err.response?.data != null) {
        _logger.warning('Data: ${err.response?.data}');
      }
    }
    handler.next(err);
  }
}

// Error Interceptor
class ErrorInterceptor extends Interceptor {
  final Logger _logger = Logger('ErrorInterceptor');

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle retry logic for specific status codes
    if (ApiConstants.retryStatusCodes.contains(err.response?.statusCode)) {
      _logger.info('Retryable error detected for status code: ${err.response?.statusCode}');
    }

    handler.next(err);
  }

}