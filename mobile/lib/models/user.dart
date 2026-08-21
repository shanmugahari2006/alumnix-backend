import 'alumni_profile.dart';
import 'student_profile.dart';
import 'faculty_profile.dart';

enum UserRole {
  student,
  alumni,
  faculty,
  admin;

  static UserRole fromString(String? value) {
    if (value == null) return UserRole.student;
    switch (value.toLowerCase().trim()) {
      case 'alumni':
        return UserRole.alumni;
      case 'faculty':
        return UserRole.faculty;
      case 'admin':
        return UserRole.admin;
      case 'student':
      default:
        return UserRole.student;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.alumni:
        return 'Alumni';
      case UserRole.faculty:
        return 'Faculty';
      case UserRole.admin:
        return 'Administrator';
    }
  }
}

class User {
  final String id;
  final String? email;
  final String? phoneNumber;
  final String? avatarUrl;
  final String fullName;
  final UserRole role;
  final bool isActive;
  final StudentProfile? studentProfile;
  final AlumniProfile? alumniProfile;
  final FacultyProfile? facultyProfile;

  const User({
    required this.id,
    this.email,
    this.phoneNumber,
    this.avatarUrl,
    required this.fullName,
    required this.role,
    this.isActive = true,
    this.studentProfile,
    this.alumniProfile,
    this.facultyProfile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] as String?,
      phoneNumber: json['phone_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      fullName: json['full_name'] as String? ?? 'Unnamed User',
      role: UserRole.fromString(json['role'] as String?),
      isActive: json['is_active'] as bool? ?? true,
      studentProfile: json['student_profile'] != null
          ? StudentProfile.fromJson(json['student_profile'] as Map<String, dynamic>)
          : (json['student'] != null
              ? StudentProfile.fromJson(json['student'] as Map<String, dynamic>)
              : null),
      alumniProfile: json['alumni_profile'] != null
          ? AlumniProfile.fromJson(json['alumni_profile'] as Map<String, dynamic>)
          : (json['alumni'] != null
              ? AlumniProfile.fromJson(json['alumni'] as Map<String, dynamic>)
              : null),
      facultyProfile: json['faculty_profile'] != null
          ? FacultyProfile.fromJson(json['faculty_profile'] as Map<String, dynamic>)
          : (json['faculty'] != null
              ? FacultyProfile.fromJson(json['faculty'] as Map<String, dynamic>)
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'full_name': fullName,
      'role': role.name,
      'is_active': isActive,
      'student_profile': studentProfile?.toJson(),
      'alumni_profile': alumniProfile?.toJson(),
      'faculty_profile': facultyProfile?.toJson(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? phoneNumber,
    String? avatarUrl,
    String? fullName,
    UserRole? role,
    bool? isActive,
    StudentProfile? studentProfile,
    AlumniProfile? alumniProfile,
    FacultyProfile? facultyProfile,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      studentProfile: studentProfile ?? this.studentProfile,
      alumniProfile: alumniProfile ?? this.alumniProfile,
      facultyProfile: facultyProfile ?? this.facultyProfile,
    );
  }
}
