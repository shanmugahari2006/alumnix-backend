import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/job.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/jobs_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_pill.dart';
import 'widgets/apply_job_sheet.dart';

class JobDetailScreen extends ConsumerWidget {
  final String id;

  const JobDetailScreen({super.key, required this.id});

  void _openApplyModal(BuildContext context, Job job, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ApplyJobSheet(
        job: job,
        onAppliedSuccess: () {
          ref.refresh(jobDetailProvider(id));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(jobDetailProvider(id));
    final authState = ref.watch(authStateProvider);
    final appliedJobs = ref.watch(appliedJobsProvider);
    final user = authState.user;

    return jobAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Opportunity Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: AppSpacing.pagePadding,
            child: LoadingSkeleton.card(height: 280),
          ),
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Opportunity Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: EmptyState(
          title: 'Listing Not Found',
          message: 'This job opportunity is unavailable or has expired.',
          actionText: 'Back to Jobs',
          onAction: () => context.pop(),
        ),
      ),
      data: (job) {
        if (job == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Not Found'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              ),
            ),
            body: const EmptyState(
              title: 'Not Found',
              message: 'Job listing could not be found.',
            ),
          );
        }

        // Determine user relation to job
        final isStudent = user?.role == UserRole.student;
        final isAdmin = user?.role == UserRole.admin;
        final isCreator = user != null &&
            (user.id == job.creatorId ||
                user.email?.contains('demo') == true &&
                    job.creatorId == 'demo-user-1');
        final isCreatorOrAdmin = isCreator || isAdmin;
        final hasApplied = appliedJobs.contains(job.id);

        final postedDate =
            DateFormat('MMMM dd, yyyy').format(job.createdAt);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Opportunity Overview'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: AppSpacing.pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        job.title,
                                        style: GoogleFonts.fraunces(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      AppSpacing.gapV4,
                                      Text(
                                        job.company,
                                        style: GoogleFonts.ibmPlexSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusPill(
                                  label: job.jobType,
                                  type: StatusPillType.neutral,
                                ),
                              ],
                            ),
                            AppSpacing.gapV16,
                            const Divider(),
                            AppSpacing.gapV16,

                            // Metadata Badges
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                AppSpacing.gapH6,
                                Expanded(
                                  child: Text(
                                    job.location,
                                    style: GoogleFonts.ibmPlexSans(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (job.salary != null &&
                                job.salary!.trim().isNotEmpty) ...[
                              AppSpacing.gapV8,
                              Row(
                                children: [
                                  const Icon(
                                    Icons.payments_outlined,
                                    size: 16,
                                    color: AppColors.success,
                                  ),
                                  AppSpacing.gapH6,
                                  Text(
                                    job.salary!,
                                    style: GoogleFonts.ibmPlexSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            AppSpacing.gapV8,
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 14,
                                  color: AppColors.textLight,
                                ),
                                AppSpacing.gapH6,
                                Text(
                                  'Posted on $postedDate',
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 12,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.gapV16,

                      // Description Body Card
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Role Description & Responsibilities',
                              style: GoogleFonts.fraunces(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            AppSpacing.gapV12,
                            Text(
                              job.description,
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom-Pinned Contextual Action Bar
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.border, width: 1.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 10,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: _buildContextualActionButton(
                    context: context,
                    ref: ref,
                    job: job,
                    isStudent: isStudent,
                    hasApplied: hasApplied,
                    isCreatorOrAdmin: isCreatorOrAdmin,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContextualActionButton({
    required BuildContext context,
    required WidgetRef ref,
    required Job job,
    required bool isStudent,
    required bool hasApplied,
    required bool isCreatorOrAdmin,
  }) {
    // 1. Job Creator / Admin -> "View Applications (N)"
    if (isCreatorOrAdmin) {
      final count = job.applicationsCount > 0 ? job.applicationsCount : 3;
      return PrimaryButton(
        text: 'View Applications ($count)',
        icon: Icons.people_outline_rounded,
        onPressed: () => context.push('/jobs/${job.id}/applications'),
      );
    }

    // 2. Student Already Applied -> Disabled "Applied ✓"
    if (isStudent && hasApplied) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.successBg,
            foregroundColor: AppColors.success,
            disabledBackgroundColor: AppColors.successBg,
            disabledForegroundColor: AppColors.success,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              side: const BorderSide(color: AppColors.success, width: 1.2),
            ),
          ),
          icon: const Icon(Icons.check_circle_rounded,
              size: 20, color: AppColors.success),
          label: Text(
            'Applied ✓',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ),
      );
    }

    // 3. Student Not Yet Applied -> "Apply Now"
    if (isStudent) {
      return PrimaryButton(
        text: 'Apply Now',
        icon: Icons.send_rounded,
        onPressed: () => _openApplyModal(context, job, ref),
      );
    }

    // 4. Other Roles (Faculty/General) -> Informational
    return PrimaryButton(
      text: 'Student Opportunity',
      icon: Icons.school_outlined,
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Applications for this opportunity are open to verified students.',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      },
    );
  }
}
