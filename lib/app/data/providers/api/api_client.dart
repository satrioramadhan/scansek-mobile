import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../../../core/constants/app_constants.dart';
import '../local/storage_service.dart';
import 'api_endpoints.dart';
import 'network_exception.dart';

/// API Client using Dio with interceptors
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio _dio;
  final StorageService _storage = getx.Get.find<StorageService>();

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.apiTimeout,
        receiveTimeout: AppConstants.apiTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(_authInterceptor());
    _dio.interceptors.add(_errorInterceptor());

    // Add logger only in debug mode
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        compact: true,
      ),
    );
  }

  /// Get Dio instance
  Dio get dio => _dio;

  // ============================================
  // AUTH INTERCEPTOR
  // ============================================

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add access token to all requests except auth endpoints
        final isAuthEndpoint = options.path.contains('/auth/') &&
            !options.path.contains('/auth/refresh');

        if (!isAuthEndpoint) {
          final accessToken = await _storage.getAccessToken();
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
        }

        return handler.next(options);
      },
    );
  }

  // ============================================
  // ERROR INTERCEPTOR
  // ============================================

  InterceptorsWrapper _errorInterceptor() {
    return InterceptorsWrapper(
      onError: (DioException error, handler) async {
        // Handle 401 Unauthorized - try to refresh token
        if (error.response?.statusCode == 401) {
          try {
            // Try to refresh token
            final newAccessToken = await _refreshToken();

            if (newAccessToken != null) {
              // Retry the original request with new token
              final options = error.requestOptions;
              options.headers['Authorization'] = 'Bearer $newAccessToken';

              final response = await _dio.request(
                options.path,
                options: Options(
                  method: options.method,
                  headers: options.headers,
                ),
                data: options.data,
                queryParameters: options.queryParameters,
              );

              return handler.resolve(response);
            } else {
              // Refresh failed, logout user
              await _handleLogout();
              return handler.reject(error);
            }
          } catch (e) {
            // Refresh failed, logout user
            await _handleLogout();
            return handler.reject(error);
          }
        }

        return handler.next(error);
      },
    );
  }

  // ============================================
  // TOKEN REFRESH
  // ============================================

  Future<String?> _refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();

      if (refreshToken == null) return null;

      final response = await _dio.post(
        ApiEndpoints.refreshToken,
        options: Options(
          headers: {
            'Authorization': 'Bearer $refreshToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final newAccessToken = data['accessToken'];

        // Save new access token
        await _storage.saveAccessToken(newAccessToken);

        return newAccessToken;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // ============================================
  // LOGOUT HANDLER
  // ============================================

  Future<void> _handleLogout() async {
    // Clear all storage
    await _storage.clearAll();

    // Navigate to login (menggunakan GetX)
    // TODO: Navigate to login screen
    // Get.offAllNamed(Routes.LOGIN);
  }

  // ============================================
  // HTTP METHODS
  // ============================================

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw ExceptionHandler.handleDioError(e);
    } catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw ExceptionHandler.handleDioError(e);
    } catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw ExceptionHandler.handleDioError(e);
    } catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw ExceptionHandler.handleDioError(e);
    } catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  /// PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw ExceptionHandler.handleDioError(e);
    } catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }
}
