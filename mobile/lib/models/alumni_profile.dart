class AlumniProfile {
  final String? usn;
  final String? company;
  final String? designation;
  final int graduationYear;
  final bool isApproved;
  final String? branch;
  final String? location;
  final String? linkedinUrl;
  final List<String> skills;
  final String? bio;

  const AlumniProfile({
    this.usn,
    this.company,
    this.designation,
    required this.graduationYear,
    this.isApproved = false,
    this.branch,
    this.location,
    this.linkedinUrl,
    this.skills = const [],
    this.bio,
  });

  factory AlumniProfile.fromJson(Map<String, dynamic> json) {
    return AlumniProfile(
      usn: json['usn'] as String?,
      company: json['company'] as String?,
      designation: json['designation'] as String?,
      graduationYear: (json['graduation_year'] as num?)?.toInt() ?? 0,
      isApproved: json['is_approved'] as bool? ?? false,
      branch: json['branch'] as String?,
      location: json['location'] as String?,
      linkedinUrl: json['linkedin_url'] as String?,
      bio: json['bio'] as String?,
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'usn': usn,
      'company': company,
      'designation': designation,
      'graduation_year': graduationYear,
      'is_approved': isApproved,
      'branch': branch,
      'location': location,
      'linkedin_url': linkedinUrl,
      'skills': skills,
      'bio': bio,
    };
  }

  AlumniProfile copyWith({
    String? usn,
    String? company,
    String? designation,
    int? graduationYear,
    bool? isApproved,
    String? branch,
    String? location,
    String? linkedinUrl,
    List<String>? skills,
    String? bio,
  }) {
    return AlumniProfile(
      usn: usn ?? this.usn,
      company: company ?? this.company,
      designation: designation ?? this.designation,
      graduationYear: graduationYear ?? this.graduationYear,
      isApproved: isApproved ?? this.isApproved,
      branch: branch ?? this.branch,
      location: location ?? this.location,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      skills: skills ?? this.skills,
      bio: bio ?? this.bio,
    );
  }
}

class AlumniSearchResult {
  final String id;
  final String fullName;
  final String email;
  final String? company;
  final String? designation;
  final int graduationYear;
  final String? branch;
  final String? location;
  final String? linkedinUrl;
  final List<String> skills;
  final String? avatarUrl;
  final String? bio;
  final bool isApproved;

  const AlumniSearchResult({
    required this.id,
    required this.fullName,
    required this.email,
    this.company,
    this.designation,
    required this.graduationYear,
    this.branch,
    this.location,
    this.linkedinUrl,
    this.skills = const [],
    this.avatarUrl,
    this.bio,
    this.isApproved = true,
  });

  factory AlumniSearchResult.fromJson(Map<String, dynamic> json) {
    return AlumniSearchResult(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name'] as String? ?? 'Alumni Member',
      email: json['email'] as String? ?? '',
      company: json['company'] as String?,
      designation: json['designation'] as String?,
      graduationYear: (json['graduation_year'] as num?)?.toInt() ?? 0,
      branch: json['branch'] as String?,
      location: json['location'] as String?,
      linkedinUrl: json['linkedin_url'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      isApproved: json['is_approved'] as bool? ?? true,
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'company': company,
      'designation': designation,
      'graduation_year': graduationYear,
      'branch': branch,
      'location': location,
      'linkedin_url': linkedinUrl,
      'skills': skills,
      'avatar_url': avatarUrl,
      'bio': bio,
      'is_approved': isApproved,
    };
  }

  AlumniSearchResult copyWith({
    String? id,
    String? fullName,
    String? email,
    String? company,
    String? designation,
    int? graduationYear,
    String? branch,
    String? location,
    String? linkedinUrl,
    List<String>? skills,
    String? avatarUrl,
    String? bio,
    bool? isApproved,
  }) {
    return AlumniSearchResult(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      company: company ?? this.company,
      designation: designation ?? this.designation,
      graduationYear: graduationYear ?? this.graduationYear,
      branch: branch ?? this.branch,
      location: location ?? this.location,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      skills: skills ?? this.skills,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}

class AlumniPaginatedResponse {
  final int total;
  final int page;
  final int limit;
  final List<AlumniSearchResult> results;

  const AlumniPaginatedResponse({
    required this.total,
    required this.page,
    required this.limit,
    required this.results,
  });

  factory AlumniPaginatedResponse.fromJson(Map<String, dynamic> json) {
    return AlumniPaginatedResponse(
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 10,
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => AlumniSearchResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
