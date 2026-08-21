import '../models/user.dart';

/// Route guard helper functions
class RouteGuards {
  RouteGuards._();

  /// Check if user has permission to post jobs (Alumni or Admin)
  static bool canPostJob(UserRole? role) {
    if (role == null) return false;
    return role == UserRole.alumni || role == UserRole.admin;
  }

  /// Check if user has permission to post stories
  static bool canCreateStory(UserRole? role) {
    if (role == null) return false;
    return role == UserRole.alumni || role == UserRole.faculty || role == UserRole.admin;
  }

  /// Check if user can approve profiles / faculty
  static bool isAdmin(UserRole? role) {
    return role == UserRole.admin;
  }
}
