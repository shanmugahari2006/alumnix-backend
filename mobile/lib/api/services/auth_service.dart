import 'package:dio/dio.dart';
import '../api_config.dart';
import '../dio_client.dart';
import '../../models/user.dart';

/// Exception thrown for specific authentication/moderation states
class AuthException implements Exception {
  final String message;
  final int? statusCode;
  final bool isAlumniPending;
  final bool isFacultyPending;

  AuthException({
    required this.message,
    this.statusCode,
    this.isAlumniPending = false,
    this.isFacultyPending = false,
  });

  @override
  String toString() => message;
}

class AuthService {
  final DioClient client;

  AuthService(this.client);

  /// Step 1 — USN Verification
  /// POST /api/v1/auth/register/verify-usn
  /// Body: { "usn": string, "role": "student" | "alumni" }
  /// Returns: full_name on success
  Future<String> verifyUsn({
    required String usn,
    required String role,
  }) async {
    try {
      final response = await client.post(
        ApiConfig.registerVerifyUsn,
        data: {
          'usn': usn.trim().toUpperCase(),
          'role': role.toLowerCase().trim(),
        },
      );
      final data = response.data as Map<String, dynamic>;
      return data['full_name'] as String? ?? 'Alumni Member';
    } on DioException catch (e) {
      final detail = _extractErrorMessage(e);
      throw AuthException(message: detail, statusCode: e.response?.statusCode);
    }
  }

  /// Step 2 — Send OTP
  /// POST /api/v1/auth/register/send-otp
  /// Body: { "usn": string, "channel": "email" | "phone" }
  Future<String> sendOtp({
    required String usn,
    required String channel,
  }) async {
    try {
      final response = await client.post(
        ApiConfig.registerSendOtp,
        data: {
          'usn': usn.trim().toUpperCase(),
          'channel': channel.toLowerCase().trim(),
        },
      );
      final data = response.data as Map<String, dynamic>;
      return data['message'] as String? ?? 'Verification code dispatched.';
    } on DioException catch (e) {
      final detail = _extractErrorMessage(e);
      throw AuthException(message: detail, statusCode: e.response?.statusCode);
    }
  }

  /// Step 3 — Verify OTP
  /// POST /api/v1/auth/register/verify-otp
  /// Body: { "usn": string, "channel": "email" | "phone", "otp_code": string }
  /// Returns: verification_token
  Future<String> verifyOtp({
    required String usn,
    required String channel,
    required String otpCode,
  }) async {
    try {
      final response = await client.post(
        ApiConfig.registerVerifyOtp,
        data: {
          'usn': usn.trim().toUpperCase(),
          'channel': channel.toLowerCase().trim(),
          'otp_code': otpCode.trim(),
        },
      );
      final data = response.data as Map<String, dynamic>;
      final token = data['verification_token'] as String?;
      if (token == null || token.isEmpty) {
        throw AuthException(message: 'Invalid verification token received from server.');
      }
      return token;
    } on DioException catch (e) {
      final detail = _extractErrorMessage(e);
      throw AuthException(message: detail, statusCode: e.response?.statusCode);
    }
  }

  /// Step 4 — Password Setup
  /// POST /api/v1/auth/register/setup-password
  /// Body: { "verification_token": string, "password": string }
  Future<void> setupPassword({
    required String verificationToken,
    required String password,
  }) async {
    try {
      await client.post(
        ApiConfig.registerSetupPassword,
        data: {
          'verification_token': verificationToken,
          'password': password,
        },
      );
    } on DioException catch (e) {
      final detail = _extractErrorMessage(e);
      throw AuthException(message: detail, statusCode: e.response?.statusCode);
    }
  }

  /// Shared Login (Student / Alumni / Faculty)
  /// POST /api/v1/auth/login
  /// Body: { "email": string, "password": string }
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await client.post(
        ApiConfig.login,
        data: {
          'email': identifier.trim(),
          'password': password,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final detail = _extractErrorMessage(e);
      final isAlumniPending = detail == 'Alumni account pending moderation approval';
      final isFacultyPending = detail == 'Faculty account pending moderation approval';

      throw AuthException(
        message: detail,
        statusCode: e.response?.statusCode,
        isAlumniPending: isAlumniPending,
        isFacultyPending: isFacultyPending,
      );
    }
  }

  /// Faculty Registration
  /// POST /api/v1/auth/register/faculty
  Future<Map<String, dynamic>> registerFaculty({
    required String employeeId,
    required String fullName,
    required String department,
    required String designation,
    required String password,
    String? email,
    String? phoneNumber,
  }) async {
    try {
      final response = await client.post(
        ApiConfig.registerFaculty,
        data: {
          'employee_id': employeeId.trim(),
          'full_name': fullName.trim(),
          'department': department.trim(),
          'designation': designation.trim(),
          'password': password,
          if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
          if (phoneNumber != null && phoneNumber.trim().isNotEmpty)
            'phone_number': phoneNumber.trim(),
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final detail = _extractErrorMessage(e);
      throw AuthException(message: detail, statusCode: e.response?.statusCode);
    }
  }

  /// Hydrate logged-in user profile
  /// GET /api/v1/auth/me
  Future<User> getMe() async {
    try {
      final response = await client.get(ApiConfig.me);
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final detail = _extractErrorMessage(e);
      throw AuthException(message: detail, statusCode: e.response?.statusCode);
    }
  }

  /// Session Logout
  /// POST /api/v1/auth/logout
  Future<void> logout() async {
    try {
      await client.post(ApiConfig.logout);
    } catch (_) {
      // Swallowed: client storage is always cleared
    }
  }

  /// Helper to extract detail message from FastAPI error responses
  String _extractErrorMessage(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        final detail = data['detail'];
        if (detail is String) return detail;
        if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first['msg'] != null) {
            return first['msg'].toString();
          }
        }
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please check your network.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Unable to reach the server. Please verify network connection.';
    }
    return e.message ?? 'An unexpected error occurred. Please try again.';
  }
}
