class Job {
  final String id;
  final String title;
  final String company;
  final String description;
  final String location;
  final String jobType; // Full-time, Internship, Contract, Remote
  final String? salary;
  final String creatorId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? companyLogoUrl;
  final int applicationsCount;

  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.description,
    required this.location,
    required this.jobType,
    this.salary,
    required this.creatorId,
    required this.createdAt,
    required this.updatedAt,
    this.companyLogoUrl,
    this.applicationsCount = 0,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Untitled Opportunity',
      company: json['company'] as String? ?? 'Organization',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? 'Remote',
      jobType: json['job_type'] as String? ?? 'Full-time',
      salary: json['salary'] as String?,
      creatorId: json['creator_id']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      companyLogoUrl: json['company_logo_url'] as String?,
      applicationsCount: (json['applications_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'company': company,
      'description': description,
      'location': location,
      'job_type': jobType,
      'salary': salary,
      'creator_id': creatorId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'company_logo_url': companyLogoUrl,
      'applications_count': applicationsCount,
    };
  }

  Job copyWith({
    String? id,
    String? title,
    String? company,
    String? description,
    String? location,
    String? jobType,
    String? salary,
    String? creatorId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? companyLogoUrl,
    int? applicationsCount,
  }) {
    return Job(
      id: id ?? this.id,
      title: title ?? this.title,
      company: company ?? this.company,
      description: description ?? this.description,
      location: location ?? this.location,
      jobType: jobType ?? this.jobType,
      salary: salary ?? this.salary,
      creatorId: creatorId ?? this.creatorId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      companyLogoUrl: companyLogoUrl ?? this.companyLogoUrl,
      applicationsCount: applicationsCount ?? this.applicationsCount,
    );
  }
}

class JobApplication {
  final String id;
  final String jobId;
  final String studentId;
  final String resumeUrl;
  final String status; // applied, shortlisted, rejected
  final DateTime createdAt;
  final String? coverNote;

  const JobApplication({
    required this.id,
    required this.jobId,
    required this.studentId,
    required this.resumeUrl,
    this.status = 'applied',
    required this.createdAt,
    this.coverNote,
  });

  factory JobApplication.fromJson(Map<String, dynamic> json) {
    return JobApplication(
      id: json['id']?.toString() ?? '',
      jobId: json['job_id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      resumeUrl: json['resume_url'] as String? ?? '',
      status: json['status'] as String? ?? 'applied',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      coverNote: json['cover_note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_id': jobId,
      'student_id': studentId,
      'resume_url': resumeUrl,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'cover_note': coverNote,
    };
  }
}

class JobApplicationDetail {
  final String id;
  final String jobId;
  final String resumeUrl;
  final String status; // applied, shortlisted, rejected
  final DateTime createdAt;
  final String studentName;
  final String studentEmail;
  final String studentBranch;
  final int studentGradYear;
  final String studentUsn;
  final String? coverNote;

  const JobApplicationDetail({
    required this.id,
    required this.jobId,
    required this.resumeUrl,
    required this.status,
    required this.createdAt,
    required this.studentName,
    required this.studentEmail,
    required this.studentBranch,
    required this.studentGradYear,
    required this.studentUsn,
    this.coverNote,
  });

  factory JobApplicationDetail.fromJson(Map<String, dynamic> json) {
    String name = 'Student Applicant';
    String email = '';
    String branch = 'Computer Science';
    int gradYear = 2026;
    String usn = '';

    if (json['student'] != null && json['student'] is Map<String, dynamic>) {
      final studentObj = json['student'] as Map<String, dynamic>;
      if (studentObj['user'] != null && studentObj['user'] is Map<String, dynamic>) {
        final u = studentObj['user'] as Map<String, dynamic>;
        name = u['full_name'] as String? ?? name;
        email = u['email'] as String? ?? email;
      }
      if (studentObj['student'] != null && studentObj['student'] is Map<String, dynamic>) {
        final s = studentObj['student'] as Map<String, dynamic>;
        branch = s['branch'] as String? ?? branch;
        gradYear = (s['graduation_year'] as num?)?.toInt() ?? gradYear;
        usn = s['usn'] as String? ?? usn;
      }
    }

    return JobApplicationDetail(
      id: json['id']?.toString() ?? '',
      jobId: json['job_id']?.toString() ?? '',
      resumeUrl: json['resume_url'] as String? ?? '',
      status: json['status'] as String? ?? 'applied',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      studentName: name,
      studentEmail: email,
      studentBranch: branch,
      studentGradYear: gradYear,
      studentUsn: usn,
      coverNote: json['cover_note'] as String?,
    );
  }

  JobApplicationDetail copyWith({
    String? id,
    String? jobId,
    String? resumeUrl,
    String? status,
    DateTime? createdAt,
    String? studentName,
    String? studentEmail,
    String? studentBranch,
    int? studentGradYear,
    String? studentUsn,
    String? coverNote,
  }) {
    return JobApplicationDetail(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      studentBranch: studentBranch ?? this.studentBranch,
      studentGradYear: studentGradYear ?? this.studentGradYear,
      studentUsn: studentUsn ?? this.studentUsn,
      coverNote: coverNote ?? this.coverNote,
    );
  }
}
