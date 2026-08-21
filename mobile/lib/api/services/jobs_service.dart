import '../api_config.dart';
import '../dio_client.dart';
import '../../models/job.dart';

class JobsService {
  final DioClient client;

  JobsService(this.client);

  /// Fetch all jobs with optional filters
  /// GET /api/v1/jobs
  Future<List<Job>> getJobs({
    String? search,
    String? company,
    String? jobType,
  }) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['title'] = search.trim();
    }
    if (company != null && company.trim().isNotEmpty) {
      queryParams['company'] = company.trim();
    }
    if (jobType != null && jobType.isNotEmpty && jobType != 'All') {
      queryParams['job_type'] = jobType.trim();
    }

    final response = await client.get(
      ApiConfig.jobs,
      queryParameters: queryParams,
    );

    if (response.data is List<dynamic>) {
      return (response.data as List<dynamic>)
          .map((e) => Job.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Fetch single job by ID
  /// GET /api/v1/jobs/{id}
  Future<Job> getJobById(String id) async {
    final response = await client.get(ApiConfig.jobById(id));
    return Job.fromJson(response.data as Map<String, dynamic>);
  }

  /// Create a new job opportunity
  /// POST /api/v1/jobs
  Future<Job> createJob({
    required String title,
    required String company,
    required String description,
    required String location,
    required String jobType,
    String? salary,
  }) async {
    final response = await client.post(
      ApiConfig.jobs,
      data: {
        'title': title.trim(),
        'company': company.trim(),
        'description': description.trim(),
        'location': location.trim(),
        'job_type': jobType.trim(),
        if (salary != null && salary.trim().isNotEmpty) 'salary': salary.trim(),
      },
    );
    return Job.fromJson(response.data as Map<String, dynamic>);
  }

  /// Apply to job opportunity
  /// POST /api/v1/jobs/{job_id}/apply
  Future<JobApplication> applyForJob({
    required String jobId,
    required String resumeUrl,
    String? coverNote,
  }) async {
    final response = await client.post(
      ApiConfig.jobApply(jobId),
      data: {
        'resume_url': resumeUrl.trim(),
        if (coverNote != null && coverNote.trim().isNotEmpty)
          'cover_note': coverNote.trim(),
      },
    );
    return JobApplication.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get candidate applications for a job (Job creator or Admin only)
  /// GET /api/v1/jobs/{job_id}/applications
  Future<List<JobApplicationDetail>> getJobApplications(String jobId) async {
    final response = await client.get(ApiConfig.jobApplications(jobId));
    if (response.data is List<dynamic>) {
      return (response.data as List<dynamic>)
          .map((e) => JobApplicationDetail.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Update application status (e.g. shortlisted or rejected)
  /// PATCH /api/v1/jobs/applications/{application_id}/status
  Future<void> updateApplicationStatus({
    required String applicationId,
    required String status,
  }) async {
    await client.patch(
      '/jobs/applications/$applicationId/status',
      data: {'status': status.toLowerCase().trim()},
    );
  }

  /// Helper to simulate uploading resume file to object storage and returning secure URL
  Future<String> uploadResume(String fileName) async {
    // In production, upload multipart bytes to cloud storage (e.g. S3 / GCS / Cloudinary)
    await Future.delayed(const Duration(milliseconds: 600));
    final cleanName = fileName.replaceAll(' ', '_');
    return 'https://storage.alumnix.edu/resumes/$cleanName';
  }
}
