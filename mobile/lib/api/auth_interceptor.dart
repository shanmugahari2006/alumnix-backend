import 'package:dio/dio.dart';
import 'api_config.dart';
import 'secure_storage.dart';

typedef OnAuthFailureCallback = void Function();

/// Dio Auth Interceptor
///
/// Attaches Bearer token to outgoing requests and handles queued 401 token refresh.
class AuthInterceptor extends QueuedInterceptorsWrapper {
  final Dio dio;
  final SecureStorageService storage;
  final OnAuthFailureCallback onAuthFailure;

  // Dedicated Dio instance for token refresh to avoid interceptor recursion loops
  late final Dio _refreshDio;

  AuthInterceptor({
    required this.dio,
    required this.storage,
    required this.onAuthFailure,
  }) {
    _refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip token for auth routes like login, register, refresh
    final path = options.path;
    final isAuthRoute = path.contains(ApiConfig.login) ||
        path.contains(ApiConfig.register) ||
        path.contains(ApiConfig.refreshToken);

    if (!isAuthRoute) {
      final token = await storage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Check if error is 401 Unauthorized and not already retried
    final is401 = err.response?.statusCode == 401;
    final isRefreshCall = err.requestOptions.path.contains(ApiConfig.refreshToken);
    final hasRetried = err.requestOptions.extra['retried'] == true;

    if (is401 && !isRefreshCall && !hasRetried) {
      final refreshToken = await storage.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        // No refresh token available -> trigger logout and reject
        await storage.clearAll();
        onAuthFailure();
        return handler.reject(err);
      }

      try {
        // Request new access token using refresh token
        final response = await _refreshDio.post(
          ApiConfig.refreshToken,
          data: {'refresh_token': refreshToken},
        );

        if (response.statusCode == 200 && response.data != null) {
          final data = response.data as Map<String, dynamic>;
          final newAccessToken = data['access_token'] as String?;
          final newRefreshToken = data['refresh_token'] as String? ?? refreshToken;

          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            // Save new tokens to secure storage
            await storage.saveTokens(
              accessToken: newAccessToken,
              refreshToken: newRefreshToken,
            );

            // Update original request options with new token
            final requestOptions = err.requestOptions;
            requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            requestOptions.extra['retried'] = true;

            // Retry original request
            final retryResponse = await dio.fetch(requestOptions);
            return handler.resolve(retryResponse);
          }
        }
      } catch (refreshErr) {
        // Refresh token failed or expired -> clear storage and trigger logout
        await storage.clearAll();
        onAuthFailure();
        return handler.reject(err);
      }
    }

    return handler.next(err);
  }
}
