import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/story.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stories_provider.dart';
import '../../router/route_guards.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/medallion_badge.dart';
import 'widgets/animated_like_button.dart';

class StoriesScreen extends ConsumerWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesState = ref.watch(storiesFeedNotifierProvider);
    final authState = ref.watch(authStateProvider);
    final canCreate = RouteGuards.canCreateStory(authState.user?.role);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/stories/create'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.edit_note_rounded, color: AppColors.secondary),
              label: Text(
                'Share Your Story',
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
          await ref
              .read(storiesFeedNotifierProvider.notifier)
              .loadInitial(refresh: true);
        },
        child: CustomScrollView(
          slivers: [
            // Magazine Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18.0, 18.0, 18.0, 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Success Stories & Insights',
                      style: GoogleFonts.fraunces(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    AppSpacing.gapV4,
                    Text(
                      'Perspectives, research breakthroughs, and career journeys from the alumni community.',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Stories Feed
            if (storiesState.isLoading)
              SliverPadding(
                padding: AppSpacing.pagePadding,
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: LoadingSkeleton.card(height: 260),
                    ),
                    childCount: 3,
                  ),
                ),
              )
            else if (storiesState.items.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.article_outlined,
                  title: 'No Stories Published',
                  message:
                      'Be the first to share an academic or professional milestone with your peers.',
                  actionText: canCreate ? 'Publish Story' : null,
                  onAction:
                      canCreate ? () => context.push('/stories/create') : null,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 80.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final story = storiesState.items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18.0),
                        child: _EditorialStoryCard(story: story),
                      );
                    },
                    childCount: storiesState.items.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EditorialStoryCard extends ConsumerWidget {
  final Story story;

  const _EditorialStoryCard({required this.story});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formattedDate = DateFormat('MMMM d, yyyy').format(story.createdAt);

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/stories/${story.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cover Image with Fallback
          if (story.imageUrl != null && story.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusXs),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  story.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.goldLight,
                    child: const Center(
                      child: Icon(
                        Icons.auto_stories_rounded,
                        size: 36,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: AppColors.background,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.secondary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Story Text Body with Editorial Padding
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author Byline with Medallion
                Row(
                  children: [
                    MedallionBadge.fromGradYear(
                      story.authorGradYear,
                      size: 34,
                    ),
                    AppSpacing.gapH10,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story.authorName,
                            style: GoogleFonts.fraunces(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (story.authorDesignation != null) ...[
                            Text(
                              story.authorDesignation!,
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      '${story.readingTimeMinutes} min read',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapV14,

                // Title (Larger Fraunces Editorial Feel)
                Text(
                  story.title,
                  style: GoogleFonts.fraunces(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                AppSpacing.gapV8,

                // Excerpt (~120 chars)
                Text(
                  story.excerpt,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                AppSpacing.gapV16,
                const Divider(),
                AppSpacing.gapV8,

                // Footer Row: Like Button and Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedLikeButton(
                      isLiked: story.isLiked,
                      likesCount: story.likesCount,
                      onToggleLike: () => ref
                          .read(storiesFeedNotifierProvider.notifier)
                          .optimisticToggleLike(story.id),
                    ),
                    Text(
                      formattedDate,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
