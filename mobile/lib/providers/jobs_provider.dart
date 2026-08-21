import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/services/jobs_service.dart';
import '../models/job.dart';
import 'auth_provider.dart';

final jobsServiceProvider = Provider<JobsService>((ref) {
  final client = ref.watch(dioClientProvider);
  return JobsService(client);
});

class JobFilter {
  final String query;
  final String? jobType; // Full-time, Internship, Contract, Remote

  const JobFilter({
    this.query = '',
    this.jobType,
  });

  JobFilter copyWith({
    String? query,
    String? jobType,
  }) {
    return JobFilter(
      query: query ?? this.query,
      jobType: jobType ?? this.jobType,
    );
  }
}

final jobFilterProvider = StateProvider<JobFilter>((ref) {
  return const JobFilter();
});

/// Track IDs of jobs applied by current student in session
final appliedJobsProvider =
    StateNotifierProvider<AppliedJobsNotifier, Set<String>>((ref) {
  return AppliedJobsNotifier();
});

class AppliedJobsNotifier extends StateNotifier<Set<String>> {
  AppliedJobsNotifier() : super({'job-1'}); // Default mock applied for demo

  void markApplied(String jobId) {
    state = {...state, jobId};
  }

  bool hasApplied(String jobId) => state.contains(jobId);
}

final jobsListProvider = FutureProvider<List<Job>>((ref) async {
  final filter = ref.watch(jobFilterProvider);
  final service = ref.watch(jobsServiceProvider);

  try {
    final results = await service.getJobs(
      search: filter.query,
      jobType: filter.jobType == 'All' ? null : filter.jobType,
    );
    if (results.isNotEmpty) return results;
  } catch (_) {}

  // Fallback curated Jobs matching Convocation theme
  return [
    Job(
      id: 'job-1',
      title: 'Principal Systems Architect',
      company: 'Palantir Technologies',
      description:
          'Lead next-generation enterprise mission architectures. Build resilient, highly distributed data pipelines across hybrid cloud environments. Mentor junior software associates and interface directly with defense and commercial enterprise leads.',
      location: 'Palo Alto, CA (Hybrid)',
      jobType: 'Full-time',
      salary: '\$220,000 - \$280,000 / yr',
      creatorId: 'alumni-1',
      applicationsCount: 4,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Job(
      id: 'job-2',
      title: 'AI Alignment Research Fellow',
      company: 'Anthropic AI',
      description:
          'Investigate interpretability and steering methods for state-of-the-art foundation models. Work closely with leading safety scientists to build scalable auditing tools and safety evaluations.',
      location: 'San Francisco, CA',
      jobType: 'Full-time',
      salary: '\$190,000 - \$260,000 + Equity',
      creatorId: 'demo-user-1', // Matches current demo user ID for creator testing!
      applicationsCount: 7,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      updatedAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    Job(
      id: 'job-3',
      title: 'Robotics Perception Intern (Summer 2026)',
      company: 'Boston Dynamics',
      description:
          'Implement real-time trajectory optimization and perception algorithms on quadrupedal platforms. Great opportunity for Computer Science and Mechanical/Robotics students looking for hands-on hardware integration.',
      location: 'Waltham, MA',
      jobType: 'Internship',
      salary: '\$55 / hr + Housing Stipend',
      creatorId: 'alumni-2',
      applicationsCount: 12,
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
      updatedAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
    Job(
      id: 'job-4',
      title: 'Quantitative Research Analyst',
      company: 'Citadel Securities',
      description:
          'Develop mathematical models and automated trading strategies for global equity derivatives markets. Leverage large scale computing clusters and low latency execution frameworks.',
      location: 'New York, NY',
      jobType: 'Contract',
      salary: '\$200,000 - \$320,000 Base',
      creatorId: 'alumni-4',
      applicationsCount: 3,
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      updatedAt: DateTime.now().subtract(const Duration(days: 8)),
    ),
  ].where((job) {
    if (filter.query.isNotEmpty) {
      final q = filter.query.toLowerCase();
      final match = job.title.toLowerCase().contains(q) ||
          job.company.toLowerCase().contains(q) ||
          job.location.toLowerCase().contains(q);
      if (!match) return false;
    }
    if (filter.jobType != null &&
        filter.jobType != 'All' &&
        job.jobType != filter.jobType) {
      return false;
    }
    return true;
  }).toList();
});

final jobDetailProvider = FutureProvider.family<Job?, String>((ref, id) async {
  final list = await ref.watch(jobsListProvider.future);
  try {
    return list.firstWhere((item) => item.id == id);
  } catch (_) {
    return null;
  }
});

/// ---------------------------------------------------------------------------
/// Applicant Tracking State Notifier (Optimistic Status Updates)
/// ---------------------------------------------------------------------------

final jobApplicationsProvider = StateNotifierProvider.family<
    JobApplicationsNotifier, AsyncValue<List<JobApplicationDetail>>, String>(
  (ref, jobId) {
    final service = ref.watch(jobsServiceProvider);
    return JobApplicationsNotifier(service, jobId);
  },
);

class JobApplicationsNotifier
    extends StateNotifier<AsyncValue<List<JobApplicationDetail>>> {
  final JobsService _service;
  final String jobId;

  JobApplicationsNotifier(this._service, this.jobId)
      : super(const AsyncValue.loading()) {
    loadApplications();
  }

  Future<void> loadApplications() async {
    state = const AsyncValue.loading();
    try {
      final list = await _service.getJobApplications(jobId);
      if (list.isNotEmpty) {
        state = AsyncValue.data(list);
        return;
      }
    } catch (_) {}

    // Mock Applicants for candidate tracking
    final mockApplicants = [
      JobApplicationDetail(
        id: 'app-101',
        jobId: jobId,
        resumeUrl: 'https://storage.alumnix.edu/resumes/arjun_sharma_cv.pdf',
        status: 'applied',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        studentName: 'Arjun Sharma',
        studentEmail: 'arjun.sharma@college.edu',
        studentBranch: 'Computer Science & Engineering',
        studentGradYear: 2026,
        studentUsn: '1MS22CS014',
        coverNote:
            'Passionate about distributed system reliability and high performance C++ architectures.',
      ),
      JobApplicationDetail(
        id: 'app-102',
        jobId: jobId,
        resumeUrl: 'https://storage.alumnix.edu/resumes/priya_patel_resume.pdf',
        status: 'shortlisted',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        studentName: 'Priya Patel',
        studentEmail: 'priya.patel@college.edu',
        studentBranch: 'Information Science',
        studentGradYear: 2025,
        studentUsn: '1MS21IS088',
        coverNote:
            'Published author on transformers interpretability at NeurIPS workshop 2025.',
      ),
      JobApplicationDetail(
        id: 'app-103',
        jobId: jobId,
        resumeUrl: 'https://storage.alumnix.edu/resumes/rohit_verma.pdf',
        status: 'rejected',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        studentName: 'Rohit Verma',
        studentEmail: 'rohit.v@college.edu',
        studentBranch: 'Electronics & Communication',
        studentGradYear: 2026,
        studentUsn: '1MS22EC052',
        coverNote: 'Experienced in embedded Linux kernel development and ROS.',
      ),
    ];

    state = AsyncValue.data(mockApplicants);
  }

  /// Optimistic status update with automatic rollback on error
  Future<bool> updateStatus(String applicationId, String newStatus) async {
    final previousList = state.valueOrNull;
    if (previousList == null) return false;

    // 1. Optimistic UI update
    final updatedList = previousList.map((app) {
      if (app.id == applicationId) {
        return app.copyWith(status: newStatus);
      }
      return app;
    }).toList();

    state = AsyncValue.data(updatedList);

    // 2. Perform network request
    try {
      await _service.updateApplicationStatus(
        applicationId: applicationId,
        status: newStatus,
      );
      return true;
    } catch (e) {
      // 3. Rollback on failure
      state = AsyncValue.data(previousList);
      return false;
    }
  }
}
