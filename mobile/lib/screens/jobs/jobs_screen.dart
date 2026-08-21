import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/job.dart';
import '../../providers/auth_provider.dart';
import '../../providers/jobs_provider.dart';
import '../../router/route_guards.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/status_pill.dart';

class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> {
  final _searchController = TextEditingController();
  final List<String> _jobTypeFilters = [
    'All',
    'Full-time',
    'Internship',
    'Contract',
    'Remote',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 30) {
      final months = (diff.inDays / 30).floor();
      return 'posted $months ${months == 1 ? "month" : "months"} ago';
    } else if (diff.inDays > 0) {
      return 'posted ${diff.inDays} ${diff.inDays == 1 ? "day" : "days"} ago';
    } else if (diff.inHours > 0) {
      return 'posted ${diff.inHours} ${diff.inHours == 1 ? "hour" : "hours"} ago';
    } else {
      return 'posted just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(jobFilterProvider);
    final jobsAsync = ref.watch(jobsListProvider);
    final authState = ref.watch(authStateProvider);
    final canPost = RouteGuards.canPostJob(authState.user?.role);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: canPost
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/jobs/post'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded, color: AppColors.secondary),
              label: Text(
                'Post Opportunity',
                style: GoogleFonts.ibmPlexSans(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              ),
            )
          : null,
      body: RefreshIndicator(
        color: AppColors.secondary,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          ref.refresh(jobsListProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Top Section: Title, Search, and Horizontal Type Chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Career Opportunities',
                      style: GoogleFonts.fraunces(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapV4,
                    Text(
                      'Roles, fellowships, and internships shared by alumni.',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    AppSpacing.gapV16,

                    // Search Input
                    TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        ref.read(jobFilterProvider.notifier).state =
                            filter.copyWith(query: val);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search by title, company, or role...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(jobFilterProvider.notifier).state =
                                      filter.copyWith(query: '');
                                },
                              )
                            : null,
                      ),
                    ),
                    AppSpacing.gapV12,

                    // Horizontally Scrollable Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _jobTypeFilters.map((type) {
                          final isSelected =
                              (filter.jobType == null && type == 'All') ||
                                  filter.jobType == type;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(type),
                              selected: isSelected,
                              onSelected: (selected) {
                                ref.read(jobFilterProvider.notifier).state =
                                    filter.copyWith(
                                  jobType: selected && type != 'All' ? type : null,
                                );
                              },
                              labelStyle: GoogleFonts.ibmPlexSans(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                              selectedColor: AppColors.primary,
                              backgroundColor: AppColors.surface,
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: 1.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusXs),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Job List Results
            jobsAsync.when(
              loading: () => SliverPadding(
                padding: AppSpacing.pagePadding,
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: LoadingSkeleton.card(height: 140),
                    ),
                    childCount: 4,
                  ),
                ),
              ),
              error: (err, _) => SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.work_off_outlined,
                  title: 'Unable to Load Jobs',
                  message: 'Failed to retrieve available career listings.',
                  actionText: 'Retry',
                  onAction: () => ref.refresh(jobsListProvider),
                ),
              ),
              data: (jobs) {
                if (jobs.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.work_outline_rounded,
                      title: 'No Opportunities Found',
                      message:
                          'No active career listings match your filter criteria.',
                      actionText: 'Clear Filters',
                      onAction: () {
                        _searchController.clear();
                        ref.read(jobFilterProvider.notifier).state =
                            const JobFilter();
                      },
                    ),
                  );
                }

                return SliverPadding(
                  padding: AppSpacing.pagePadding,
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final job = jobs[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _JobCardItem(
                            job: job,
                            relativeTime: _formatRelativeTime(job.createdAt),
                          ),
                        );
                      },
                      childCount: jobs.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _JobCardItem extends StatelessWidget {
  final Job job;
  final String relativeTime;

  const _JobCardItem({
    required this.job,
    required this.relativeTime,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/jobs/${job.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Initial Icon Box
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.goldLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  border: Border.all(
                    color: AppColors.secondary.withOpacity(0.5),
                    width: 1.0,
                  ),
                ),
                child: Center(
                  child: Text(
                    job.company.isNotEmpty
                        ? job.company[0].toUpperCase()
                        : 'C',
                    style: GoogleFonts.fraunces(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              AppSpacing.gapH12,

              // Title & Company
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: GoogleFonts.fraunces(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.gapV2,
                    Text(
                      job.company,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH8,

              // StatusPill for Job Type
              StatusPill(
                label: job.jobType,
                type: StatusPillType.neutral,
              ),
            ],
          ),
          AppSpacing.gapV12,

          // Description preview
          Text(
            job.description,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          AppSpacing.gapV12,

          // Location & Relative Time Row
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  job.location,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                relativeTime,
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
