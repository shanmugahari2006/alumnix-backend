class StudentProfile {
  final String usn;
  final String branch;
  final int graduationYear;

  const StudentProfile({
    required this.usn,
    required this.branch,
    required this.graduationYear,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      usn: json['usn'] as String? ?? '',
      branch: json['branch'] as String? ?? '',
      graduationYear: (json['graduation_year'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'usn': usn,
      'branch': branch,
      'graduation_year': graduationYear,
    };
  }

  StudentProfile copyWith({
    String? usn,
    String? branch,
    int? graduationYear,
  }) {
    return StudentProfile(
      usn: usn ?? this.usn,
      branch: branch ?? this.branch,
      graduationYear: graduationYear ?? this.graduationYear,
    );
  }
}
