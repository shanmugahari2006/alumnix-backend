import 'dart:async';
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
import '../../widgets/primary_button.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final String id;

  const EventDetailScreen({super.key, required this.id});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  Timer? _countdownTimer;
  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();
    // Live update countdown banner every 30 seconds
    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleRegister(BulletinEvent event) async {
    setState(() => _isRegistering = true);

    final success = await ref
        .read(eventsListProvider.notifier)
        .registerOptimistic(event.id);

    if (!mounted) return;
    setState(() => _isRegistering = false);

    if (success) {
      ref.refresh(eventDetailProvider(widget.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Seat reserved for "${event.title}"!',
            style: GoogleFonts.ibmPlexSans(
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            side: const BorderSide(color: AppColors.secondary, width: 1.0),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration failed. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleDelete(BulletinEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        title: Text(
          'Delete Event Listing',
          style: GoogleFonts.fraunces(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to permanently cancel and delete "${event.title}"?',
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

      if (mounted) {
        if (success) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Event "${event.title}" has been deleted.',
                style: GoogleFonts.ibmPlexSans(color: Colors.white),
              ),
              backgroundColor: AppColors.primary,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete event.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(widget.id));
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return eventAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Event Bulletin'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: AppSpacing.pagePadding,
            child: LoadingSkeleton.card(height: 300),
          ),
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Event'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: EmptyState(
          icon: Icons.event_busy_outlined,
          title: 'Event Not Found',
          message: 'This bulletin event is unavailable or was removed.',
          actionText: 'Back to Events',
          onAction: () => context.pop(),
        ),
      ),
      data: (event) {
        if (event == null) {
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
              message: 'Bulletin record was not found.',
            ),
          );
        }

        final isCreatorOrAdmin = user != null &&
            (user.id == event.creatorId || user.role == UserRole.admin);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Event Overview'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (isCreatorOrAdmin)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Delete Event',
                  onPressed: () => _handleDelete(event),
                ),
            ],
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
                            Text(
                              event.title,
                              style: GoogleFonts.fraunces(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                height: 1.3,
                              ),
                            ),
                            AppSpacing.gapV8,

                            Text(
                              'Organized by ${event.creatorName}',
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            AppSpacing.gapV16,
                            const Divider(),
                            AppSpacing.gapV16,

                            // Schedule & Location Rows
                            _EventDetailRow(
                              icon: Icons.calendar_today_rounded,
                              label: 'Date & Time',
                              value: event.formattedEventDate,
                            ),
                            AppSpacing.gapV12,
                            _EventDetailRow(
                              icon: Icons.location_on_outlined,
                              label: 'Venue Location',
                              value: event.location,
                            ),
                            AppSpacing.gapV12,
                            _EventDetailRow(
                              icon: Icons.people_outline_rounded,
                              label: 'Attendance',
                              value: '${event.registeredCount} Registered',
                            ),
                            AppSpacing.gapV12,
                            _EventDetailRow(
                              icon: Icons.timer_outlined,
                              label: 'Registration Cut-off',
                              value: event.formattedDeadline,
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.gapV14,

                      // Dynamic Registration Deadline Countdown Banner
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        decoration: BoxDecoration(
                          color: event.isRegistrationClosed
                              ? AppColors.border.withOpacity(0.5)
                              : AppColors.goldLight,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusXs),
                          border: Border.all(
                            color: event.isRegistrationClosed
                                ? AppColors.border
                                : AppColors.secondary,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              event.isRegistrationClosed
                                  ? Icons.lock_clock_outlined
                                  : Icons.hourglass_top_rounded,
                              color: event.isRegistrationClosed
                                  ? AppColors.textSecondary
                                  : AppColors.primary,
                              size: 20,
                            ),
                            AppSpacing.gapH10,
                            Expanded(
                              child: Text(
                                event.countdownString,
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: event.isRegistrationClosed
                                      ? AppColors.textSecondary
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.gapV16,

                      // Full Description Card
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Event Agenda & Guidelines',
                              style: GoogleFonts.fraunces(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            AppSpacing.gapV12,
                            Text(
                              event.description,
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

              // Bottom-Pinned Registration Action Bar
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
                  child: _buildRegisterButton(event),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRegisterButton(BulletinEvent event) {
    // 1. Already Registered -> Disabled Forest Green
    if (event.isRegistered) {
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
            "You're Registered ✓",
            style: GoogleFonts.ibmPlexSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ),
      );
    }

    // 2. Deadline Passed -> Disabled Gray
    if (event.isRegistrationClosed) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.border,
            foregroundColor: AppColors.textSecondary,
            disabledBackgroundColor: AppColors.border,
            disabledForegroundColor: AppColors.textSecondary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            ),
          ),
          icon: const Icon(Icons.lock_clock_outlined, size: 18),
          label: Text(
            'Registration Closed',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // 3. Open & Not Registered -> "Register"
    return PrimaryButton(
      text: 'Register for Event',
      icon: Icons.event_available_rounded,
      isLoading: _isRegistering,
      onPressed: () => _handleRegister(event),
    );
  }
}

class _EventDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _EventDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.secondary),
        AppSpacing.gapH12,
        Text(
          label,
          style: GoogleFonts.ibmPlexSans(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
