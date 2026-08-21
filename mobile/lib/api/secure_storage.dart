import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

/// Secure Storage Service
///
/// Uses flutter_secure_storage to safely encrypt and persist
/// access_token, refresh_token, and user authentication session data.
class SecureStorageService {
  static const String _keyAccessToken = 'alumnix_access_token';
  static const String _keyRefreshToken = 'alumnix_refresh_token';
  static const String _keyUserData = 'alumnix_user_data';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  /// Retrieve the encrypted access token
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _keyAccessToken);
    } catch (_) {
      return null;
    }
  }

  /// Store the access token
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }

  /// Retrieve the encrypted refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _keyRefreshToken);
    } catch (_) {
      return null;
    }
  }

  /// Store the refresh token
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  /// Store both access & refresh tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _keyAccessToken, value: accessToken),
      _storage.write(key: _keyRefreshToken, value: refreshToken),
    ]);
  }

  /// Store cached User object for instant app launch restoration
  Future<void> saveUser(User user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      await _storage.write(key: _keyUserData, value: userJson);
    } catch (_) {}
  }

  /// Retrieve cached User object
  Future<User?> getUser() async {
    try {
      final raw = await _storage.read(key: _keyUserData);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return User.fromJson(decoded);
      }
    } catch (_) {}
    return null;
  }

  /// Delete all stored credentials and session data on logout
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
