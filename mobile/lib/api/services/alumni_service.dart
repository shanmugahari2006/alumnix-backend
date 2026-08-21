import '../api_config.dart';
import '../dio_client.dart';
import '../../models/alumni_profile.dart';

class AlumniService {
  final DioClient client;

  AlumniService(this.client);

  /// Search alumni with pagination and multi-filter support
  /// GET /api/v1/alumni
  Future<AlumniPaginatedResponse> searchAlumni({
    String? search,
    String? branch,
    int? graduationYear,
    String? location,
    List<String>? skills,
    int page = 1,
    int limit = 10,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (branch != null && branch.isNotEmpty && branch != 'All') {
      queryParams['branch'] = branch.trim();
    }
    if (graduationYear != null) {
      queryParams['batch'] = graduationYear;
    }
    if (location != null && location.trim().isNotEmpty) {
      queryParams['location'] = location.trim();
    }
    if (skills != null && skills.isNotEmpty) {
      queryParams['skills'] = skills;
    }

    final response = await client.get(
      ApiConfig.alumni,
      queryParameters: queryParams,
    );

    if (response.data is Map<String, dynamic>) {
      return AlumniPaginatedResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } else if (response.data is List<dynamic>) {
      final list = (response.data as List<dynamic>)
          .map((e) => AlumniSearchResult.fromJson(e as Map<String, dynamic>))
          .toList();
      return AlumniPaginatedResponse(
        total: list.length,
        page: page,
        limit: limit,
        results: list,
      );
    }

    return AlumniPaginatedResponse(
      total: 0,
      page: page,
      limit: limit,
      results: [],
    );
  }

  /// Fetch single alumnus details
  /// GET /api/v1/alumni/{id}
  Future<AlumniSearchResult> getAlumniById(String id) async {
    final response = await client.get(ApiConfig.alumniById(id));
    return AlumniSearchResult.fromJson(response.data as Map<String, dynamic>);
  }

  /// Update alumni profile
  /// PUT /api/v1/alumni/profile
  Future<AlumniProfile> updateProfile({
    String? company,
    String? designation,
    String? location,
    String? linkedinUrl,
    List<String>? skills,
    String? bio,
  }) async {
    final payload = <String, dynamic>{
      if (company != null) 'company': company,
      if (designation != null) 'designation': designation,
      if (location != null) 'location': location,
      if (linkedinUrl != null) 'linkedin_url': linkedinUrl,
      if (skills != null) 'skills': skills,
      if (bio != null) 'bio': bio,
    };

    final response = await client.put(
      ApiConfig.alumniProfile,
      data: payload,
    );

    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      if (data.containsKey('alumni')) {
        return AlumniProfile.fromJson(data['alumni'] as Map<String, dynamic>);
      }
      return AlumniProfile.fromJson(data);
    }
    return const AlumniProfile(graduationYear: 2020);
  }

  /// Admin approval for pending alumni
  /// PATCH /api/v1/alumni/{alumni_id}/approve
  Future<void> approveAlumni(String alumniId) async {
    await client.patch(ApiConfig.alumniApprove(alumniId));
  }

  /// Get pending alumni list for admin moderation
  Future<List<AlumniSearchResult>> getPendingAlumni() async {
    try {
      final response = await client.get(ApiConfig.alumniPending);
      if (response.data is List<dynamic>) {
        return (response.data as List<dynamic>)
            .map((e) => AlumniSearchResult.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
