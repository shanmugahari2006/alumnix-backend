import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/alumni_profile.dart';
import '../../providers/alumni_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/medallion_badge.dart';
import 'widgets/directory_filter_modal.dart';

class DirectoryScreen extends ConsumerStatefulWidget {
  const DirectoryScreen({super.key});

  @override
  ConsumerState<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends ConsumerState<DirectoryScreen> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(directoryFilterProvider);
    _searchController = TextEditingController(text: filter.search);
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(alumniDirectoryNotifierProvider.notifier).loadNextPage();
    }
  }

  void _openFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const DirectoryFilterModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(directoryFilterProvider);
    final directoryState = ref.watch(alumniDirectoryNotifierProvider);
    final filterCount = filter.activeFilterCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.secondary,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          await ref
              .read(alumniDirectoryNotifierProvider.notifier)
              .loadInitial(refresh: true);
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Top Sticky Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alumni Directory',
                      style: GoogleFonts.fraunces(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapV4,
                    Text(
                      'Connect with graduates, founders, and scholars worldwide.',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    AppSpacing.gapV16,

                    // Search Bar & Filter Button Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (query) {
                              ref
                                  .read(alumniDirectoryNotifierProvider.notifier)
                                  .onSearchQueryChanged(
                                    query,
                                    ref.read(directoryFilterProvider.notifier),
                                  );
                            },
                            decoration: InputDecoration(
                              hintText: 'Search by name, role, company, or city...',
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: AppColors.textSecondary,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        ref
                                            .read(alumniDirectoryNotifierProvider
                                                .notifier)
                                            .onSearchQueryChanged(
                                              '',
                                              ref.read(
                                                  directoryFilterProvider.notifier),
                                            );
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        AppSpacing.gapH8,

                        // Filters Button with Active Filter Badge
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: filter.hasActiveFilters
                                    ? AppColors.primary
                                    : AppColors.surface,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusXs),
                                border: Border.all(
                                  color: filter.hasActiveFilters
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: 1.0,
                                ),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.tune_rounded,
                                  color: filter.hasActiveFilters
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                                tooltip: 'Filter Alumni',
                                onPressed: _openFilterModal,
                              ),
                            ),
                            if (filterCount > 0)
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: const BoxDecoration(
                                    color: AppColors.secondary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$filterCount',
                                    style: GoogleFonts.ibmPlexSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Main Content Area
            if (directoryState.isLoading)
              SliverPadding(
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
              )
            else if (directoryState.items.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.person_search_outlined,
                  title: 'No Alumni Found',
                  message: 'No alumni match your filters or search query.',
                  actionText: 'Clear Filters',
                  onAction: () {
                    _searchController.clear();
                    ref.read(directoryFilterProvider.notifier).reset();
                    ref
                        .read(alumniDirectoryNotifierProvider.notifier)
                        .loadInitial(refresh: true);
                  },
                ),
              )
            else
              SliverPadding(
                padding: AppSpacing.pagePadding,
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == directoryState.items.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.secondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      final alumni = directoryState.items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _AlumniDirectoryCard(alumni: alumni),
                      );
                    },
                    childCount: directoryState.items.length +
                        (directoryState.isLoadingMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AlumniDirectoryCard extends StatelessWidget {
  final AlumniSearchResult alumni;

  const _AlumniDirectoryCard({required this.alumni});

  @override
  Widget build(BuildContext context) {
    final hasSkills = alumni.skills.isNotEmpty;
    final displaySkills = alumni.skills.take(3).toList();
    final remainingCount = alumni.skills.length - 3;

    return AppCard(
      onTap: () => context.push('/directory/${alumni.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.goldLight,
                  border: Border.all(color: AppColors.border, width: 1.0),
                ),
                child: Center(
                  child: Text(
                    alumni.fullName.isNotEmpty
                        ? alumni.fullName[0].toUpperCase()
                        : 'A',
                    style: GoogleFonts.fraunces(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              AppSpacing.gapH12,

              // Name & Company/Designation
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alumni.fullName,
                      style: GoogleFonts.fraunces(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.gapV2,
                    if (alumni.designation != null || alumni.company != null)
                      Text(
                        [alumni.designation, alumni.company]
                            .where((e) => e != null && e.isNotEmpty)
                            .join(' • '),
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (alumni.location != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              alumni.location!,
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              AppSpacing.gapH8,

              // Signature Medallion Badge with Grad Year
              MedallionBadge.fromGradYear(
                alumni.graduationYear,
                size: 40,
              ),
            ],
          ),

          // Skill Chips (Max 3 + "+N more")
          if (hasSkills) ...[
            AppSpacing.gapV12,
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                ...displaySkills.map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                      border: Border.all(color: AppColors.border, width: 0.8),
                    ),
                    child: Text(
                      skill,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }),
                if (remainingCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.goldLight,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                      border: Border.all(
                        color: AppColors.secondary.withOpacity(0.5),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      '+$remainingCount more',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
