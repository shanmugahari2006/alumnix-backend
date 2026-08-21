import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/dio_client.dart';
import '../api/secure_storage.dart';
import '../api/services/auth_service.dart';
import '../models/user.dart';

/// Authentication State Data Class
@immutable
class AuthState {
  final User? user;
  final String? accessToken;
  final bool isAuthenticated;
  final UserRole role;
  final bool isLoading;
  final String? errorMessage;
  final bool isAlumniPending;
  final bool isFacultyPending;

  const AuthState({
    this.user,
    this.accessToken,
    this.isAuthenticated = false,
    this.role = UserRole.student,
    this.isLoading = false,
    this.errorMessage,
    this.isAlumniPending = false,
    this.isFacultyPending = false,
  });

  factory AuthState.initial() => const AuthState(isLoading: true);

  factory AuthState.unauthenticated({String? error}) => AuthState(
        user: null,
        accessToken: null,
        isAuthenticated: false,
        role: UserRole.student,
        isLoading: false,
        errorMessage: error,
      );

  factory AuthState.authenticated({
    required User user,
    required String accessToken,
  }) =>
      AuthState(
        user: user,
        accessToken: accessToken,
        isAuthenticated: true,
        role: user.role,
        isLoading: false,
        errorMessage: null,
      );

  AuthState copyWith({
    User? user,
    String? accessToken,
    bool? isAuthenticated,
    UserRole? role,
    bool? isLoading,
    String? errorMessage,
    bool? isAlumniPending,
    bool? isFacultyPending,
  }) {
    return AuthState(
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      role: role ?? this.role,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isAlumniPending: isAlumniPending ?? this.isAlumniPending,
      isFacultyPending: isFacultyPending ?? this.isFacultyPending,
    );
  }
}

/// Secure Storage Provider
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Dio Client Provider
final dioClientProvider = Provider<DioClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return DioClient(
    storage: storage,
    onAuthFailure: () {
      ref.read(authStateProvider.notifier).handleAuthExpired();
    },
  );
});

/// Auth API Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(dioClientProvider);
  return AuthService(client);
});

/// Auth State Notifier Provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(storage, authService);
});

/// Auth State Manager
class AuthNotifier extends StateNotifier<AuthState> {
  final SecureStorageService _storage;
  final AuthService _authService;

  AuthNotifier(this._storage, this._authService) : super(AuthState.initial()) {
    bootstrapSession();
  }

  /// Session bootstrap:
  /// On app launch, check secure storage for token. If present, call GET /auth/me
  /// to hydrate authStateProvider; on failure, clear storage silently and treat as logged out.
  Future<void> bootstrapSession() async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null || token.isEmpty) {
        state = AuthState.unauthenticated();
        return;
      }

      // Token present: fetch fresh profile from /auth/me
      try {
        final user = await _authService.getMe();
        await _storage.saveUser(user);
        state = AuthState.authenticated(
          user: user,
          accessToken: token,
        );
      } catch (_) {
        // Failed to hydrate -> clear storage silently and treat as logged out
        await _storage.clearAll();
        state = AuthState.unauthenticated();
      }
    } catch (_) {
      await _storage.clearAll();
      state = AuthState.unauthenticated();
    }
  }

  /// Shared Login (Student / Alumni / Faculty)
  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      isAlumniPending: false,
      isFacultyPending: false,
    );

    try {
      final data = await _authService.login(
        identifier: identifier,
        password: password,
      );

      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;

      await _storage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      // Hydrate full user profile via GET /auth/me
      final user = await _authService.getMe();
      await _storage.saveUser(user);

      state = AuthState.authenticated(
        user: user,
        accessToken: accessToken,
      );
      return true;
    } on AuthException catch (e) {
      if (e.isAlumniPending) {
        state = state.copyWith(
          isLoading: false,
          isAlumniPending: true,
          errorMessage: e.message,
        );
      } else if (e.isFacultyPending) {
        state = state.copyWith(
          isLoading: false,
          isFacultyPending: true,
          errorMessage: e.message,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.message,
        );
      }
      return false;
    } catch (e) {
      // Offline / demo fallback for testing
      if (kDebugMode && identifier.contains('demo')) {
        final demoUser = User(
          id: 'demo-user-1',
          email: identifier,
          fullName: 'Alexander Wright',
          role: identifier.contains('alumni')
              ? UserRole.alumni
              : (identifier.contains('faculty') ? UserRole.faculty : UserRole.student),
          alumniProfile: null,
        );
        state = AuthState.authenticated(
          user: demoUser,
          accessToken: 'mock-access-token',
        );
        return true;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Invalid credentials. Please verify and try again.',
      );
      return false;
    }
  }

  /// Triggered automatically when tokens expire and refresh fails
  void handleAuthExpired() {
    state = AuthState.unauthenticated(
      error: 'Your session has expired. Please log in again.',
    );
  }

  /// Logout:
  /// Call POST /auth/logout, then always clear secure storage and reset authStateProvider.
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.logout();
    } catch (_) {}
    await _storage.clearAll();
    state = AuthState.unauthenticated();
  }
}

/// ---------------------------------------------------------------------------
/// In-Memory Registration Wizard State
/// ---------------------------------------------------------------------------

@immutable
class RegistrationWizardState {
  final String role; // 'student' | 'alumni'
  final String usn;
  final String fullName;
  final String channel; // 'email' | 'phone'
  final String? verificationToken; // Short-lived in-memory token from Step 3
  final int currentStep; // 0: Role, 1: USN, 2: Send OTP, 3: Verify OTP, 4: Password, 5: Done
  final bool isLoading;
  final String? errorMessage;

  const RegistrationWizardState({
    this.role = 'student',
    this.usn = '',
    this.fullName = '',
    this.channel = 'email',
    this.verificationToken,
    this.currentStep = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  RegistrationWizardState copyWith({
    String? role,
    String? usn,
    String? fullName,
    String? channel,
    String? verificationToken,
    int? currentStep,
    bool? isLoading,
    String? errorMessage,
  }) {
    return RegistrationWizardState(
      role: role ?? this.role,
      usn: usn ?? this.usn,
      fullName: fullName ?? this.fullName,
      channel: channel ?? this.channel,
      verificationToken: verificationToken ?? this.verificationToken,
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final registrationWizardProvider =
    StateNotifierProvider.autoDispose<RegistrationWizardNotifier, RegistrationWizardState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return RegistrationWizardNotifier(authService);
});

class RegistrationWizardNotifier extends StateNotifier<RegistrationWizardState> {
  final AuthService _authService;

  RegistrationWizardNotifier(this._authService) : super(const RegistrationWizardState());

  void setRole(String role) {
    state = state.copyWith(role: role, currentStep: 1, errorMessage: null);
  }

  void goToStep(int step) {
    state = state.copyWith(currentStep: step, errorMessage: null);
  }

  /// Step 1: Verify USN against registry
  Future<bool> verifyUsn(String usn) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final name = await _authService.verifyUsn(usn: usn, role: state.role);
      state = state.copyWith(
        usn: usn,
        fullName: name,
        isLoading: false,
        currentStep: 2,
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'USN verification failed. Please try again.',
      );
      return false;
    }
  }

  /// Step 2: Send OTP
  Future<bool> sendOtp(String channel) async {
    state = state.copyWith(isLoading: true, channel: channel, errorMessage: null);
    try {
      await _authService.sendOtp(usn: state.usn, channel: channel);
      state = state.copyWith(isLoading: false, currentStep: 3);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to send OTP code. Please try again.',
      );
      return false;
    }
  }

  /// Step 3: Verify OTP code & store in-memory verification token
  Future<bool> verifyOtp(String otpCode) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final token = await _authService.verifyOtp(
        usn: state.usn,
        channel: state.channel,
        otpCode: otpCode,
      );
      state = state.copyWith(
        verificationToken: token,
        isLoading: false,
        currentStep: 4,
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Invalid or expired OTP code.',
      );
      return false;
    }
  }

  /// Step 4: Finalize password setup
  Future<bool> setupPassword(String password) async {
    final token = state.verificationToken;
    if (token == null || token.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Your verification expired, please request a new code',
        currentStep: 2, // Route back to Step 2 per specification
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authService.setupPassword(
        verificationToken: token,
        password: password,
      );
      state = state.copyWith(isLoading: false, currentStep: 5);
      return true;
    } on AuthException catch (e) {
      // If token expired or invalid, backtrack to Step 2
      if (e.statusCode == 401 || e.message.toLowerCase().contains('expired') || e.message.toLowerCase().contains('token')) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Your verification expired, please request a new code',
          currentStep: 2,
        );
      } else {
        state = state.copyWith(isLoading: false, errorMessage: e.message);
      }
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Password setup failed. Please try again.',
      );
      return false;
    }
  }

  /// Backtrack to Step 2 when token expires
  void backtrackToSendOtp({String? reason}) {
    state = state.copyWith(
      currentStep: 2,
      verificationToken: null,
      errorMessage: reason ?? 'Your verification expired, please request a new code',
    );
  }

  void reset() {
    state = const RegistrationWizardState();
  }
}
