/// API Configuration and endpoint routes
class ApiConfig {
  ApiConfig._();

  /// Base URL placeholder as requested.
  /// Easily editable for local dev (http://10.0.2.2:8000/api/v1 or http://localhost:8000/api/v1) or production.
  static const String baseUrl = 'https://alumnix-backend-production.up.railway.app/api/v1';

  // Network Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  // Authentication & Onboarding Endpoints
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String me = '/auth/me';

  // Registration Wizard Endpoints
  static const String register = '/auth/register';
  static const String registerVerifyUsn = '/auth/register/verify-usn';
  static const String registerSendOtp = '/auth/register/send-otp';
  static const String registerVerifyOtp = '/auth/register/verify-otp';
  static const String registerSetupPassword = '/auth/register/setup-password';
  static const String registerFaculty = '/auth/register/faculty';

  // Password Recovery
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // Alumni Directory Endpoints
  static const String alumni = '/alumni';
  static const String alumniSearch = '/alumni';
  static const String alumniProfile = '/alumni/profile';
  static const String alumniPending = '/alumni/pending';
  static String alumniById(String id) => '/alumni/$id';
  static String alumniApprove(String id) => '/alumni/$id/approve';

  // Jobs
  static const String jobs = '/jobs';
  static String jobById(String id) => '/jobs/$id';
  static String jobApply(String id) => '/jobs/$id/apply';
  static String jobApplications(String id) => '/jobs/$id/applications';

  // Stories
  static const String stories = '/stories';
  static String storyById(String id) => '/stories/$id';
  static String storyLike(String id) => '/stories/$id/like';

  // Fundraisers
  static const String fundraisers = '/fundraisers';
  static String fundraiserById(String id) => '/fundraisers/$id';
  static String fundraiserDonate(String id) => '/fundraisers/$id/donate';

  // Events
  static const String events = '/events';
  static String eventById(String id) => '/events/$id';
  static String eventRegister(String id) => '/events/$id/register';
}
