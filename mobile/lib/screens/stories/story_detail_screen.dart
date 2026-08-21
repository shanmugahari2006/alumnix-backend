import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/story.dart';
import '../../providers/stories_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/medallion_badge.dart';
import 'widgets/animated_like_button.dart';

class StoryDetailScreen extends ConsumerWidget {
  final String id;

  const StoryDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storyAsync = ref.watch(storyDetailProvider(id));

    return storyAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Story Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: AppSpacing.pagePadding,
            child: LoadingSkeleton.card(height: 320),
          ),
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Story'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: EmptyState(
          icon: Icons.article_outlined,
          title: 'Story Unavailable',
          message: 'This story is not accessible or has been removed.',
          actionText: 'Back to Stories',
          onAction: () => context.pop(),
        ),
      ),
      data: (story) {
        if (story == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Story Not Found'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              ),
            ),
            body: const EmptyState(
              title: 'Not Found',
              message: 'The requested story could not be found.',
            ),
          );
        }

        final formattedDate =
            DateFormat('MMMM d, yyyy').format(story.createdAt);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Success Story'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Share Story',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Story link copied for "${story.title}"',
                        style: GoogleFonts.ibmPlexSans(color: Colors.white),
                      ),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  AnimatedLikeButton(
                    isLiked: story.isLiked,
                    likesCount: story.likesCount,
                    onToggleLike: () => ref
                        .read(storiesFeedNotifierProvider.notifier)
                        .optimisticToggleLike(story.id),
                  ),
                  const Spacer(),
                  Text(
                    'Published on $formattedDate',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cover Image Hero
                if (story.imageUrl != null && story.imageUrl!.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Image.network(
                      story.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.goldLight,
                        child: const Center(
                          child: Icon(
                            Icons.auto_stories_rounded,
                            size: 48,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Article Content Container
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 40.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Story Title in Large Fraunces Typography
                      Text(
                        story.title,
                        style: GoogleFonts.fraunces(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.25,
                        ),
                      ),
                      AppSpacing.gapV16,

                      // Author Card
                      AppCard(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          children: [
                            MedallionBadge.fromGradYear(
                              story.authorGradYear,
                              size: 46,
                            ),
                            AppSpacing.gapH12,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    story.authorName,
                                    style: GoogleFonts.fraunces(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (story.authorDesignation != null) ...[
                                    AppSpacing.gapV2,
                                    Text(
                                      story.authorDesignation!,
                                      style: GoogleFonts.ibmPlexSans(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusXs),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                '${story.readingTimeMinutes} min',
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.gapV24,

                      // Full Story Content with Generous Editorial Line-Height
                      ...story.content.split('\n\n').map((paragraph) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 18.0),
                          child: Text(
                            paragraph.trim(),
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                              height: 1.75,
                              letterSpacing: 0.1,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
