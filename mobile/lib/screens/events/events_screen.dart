import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/bulletin_event.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/events_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/status_pill.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  Future<void> _handleDeleteEvent(
    BuildContext context,
    WidgetRef ref,
    BulletinEvent event,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        title: Text(
          'Delete Event',
          style: GoogleFonts.fraunces(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to remove "${event.title}" from the collegiate bulletin?',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(eventsListProvider.notifier)
          .deleteEvent(event.id);

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Event "${event.title}" deleted.',
                style: GoogleFonts.ibmPlexSans(color: Colors.white),
              ),
              backgroundColor: AppColors.primary,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete event. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsListProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final canCreate =
        user?.role == UserRole.faculty || user?.role == UserRole.admin;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/events/create'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.event_available_rounded,
                  color: AppColors.secondary),
              label: Text(
                'Create Event',
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
          await ref.read(eventsListProvider.notifier).loadEvents();
        },
        child: CustomScrollView(
          slivers: [
            // Header Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Events & Bulletin',
                      style: GoogleFonts.fraunces(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapV4,
                    Text(
                      'Academic symposia, convocation reunions, and research summits.',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    AppSpacing.gapV16,
                  ],
                ),
              ),
            ),

            // Events List (Sorted Soonest Event First)
            eventsAsync.when(
              loading: () => SliverPadding(
                padding: AppSpacing.pagePadding,
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: LoadingSkeleton.card(height: 150),
                    ),
                    childCount: 4,
                  ),
                ),
              ),
              error: (err, _) => SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.event_busy_outlined,
                  title: 'Unable to Load Events',
                  message: 'Failed to retrieve collegiate bulletin listings.',
                  actionText: 'Retry',
                  onAction: () =>
                      ref.read(eventsListProvider.notifier).loadEvents(),
                ),
              ),
              data: (events) {
                if (events.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.event_note_rounded,
                      title: 'No Upcoming Events',
                      message:
                          'There are currently no active bulletin announcements or workshops.',
                      actionText: canCreate ? 'Create Event' : null,
                      onAction:
                          canCreate ? () => context.push('/events/create') : null,
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 80.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final event = events[index];
                        final isCreatorOrAdmin = user != null &&
                            (user.id == event.creatorId ||
                                user.role == UserRole.admin);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _EventBulletinCard(
                            event: event,
                            isCreatorOrAdmin: isCreatorOrAdmin,
                            onDelete: () =>
                                _handleDeleteEvent(context, ref, event),
                          ),
                        );
                      },
                      childCount: events.length,
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

class _EventBulletinCard extends StatelessWidget {
  final BulletinEvent event;
  final bool isCreatorOrAdmin;
  final VoidCallback onDelete;

  const _EventBulletinCard({
    required this.event,
    required this.isCreatorOrAdmin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/events/${event.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calendar Date Block Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.goldLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  border: Border.all(
                    color: AppColors.secondary.withOpacity(0.5),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      size: 22,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH12,

              // Title & Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: GoogleFonts.fraunces(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.gapV4,

                    // Formatted Date ("12 Sept 2026, 5:00 PM")
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        AppSpacing.gapH4,
                        Text(
                          event.formattedEventDate,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status Pill or Trash Action
              if (event.isRegistrationClosed) ...[
                StatusPill(
                  label: 'Registration Closed',
                  type: StatusPillType.neutral,
                ),
              ] else if (event.isRegistered) ...[
                StatusPill.registered(),
              ],

              if (isCreatorOrAdmin) ...[
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: AppColors.textLight,
                  ),
                  tooltip: 'Delete Event',
                  onPressed: onDelete,
                ),
              ],
            ],
          ),
          AppSpacing.gapV12,

          // Location & Registration Counter Footer
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              AppSpacing.gapH4,
              Expanded(
                child: Text(
                  event.location,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  border: Border.all(color: AppColors.border, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.people_outline_rounded,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    AppSpacing.gapH4,
                    Text(
                      '${event.registeredCount} registered',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
