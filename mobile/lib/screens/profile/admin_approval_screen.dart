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

class AdminApprovalScreen extends ConsumerStatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  ConsumerState<AdminApprovalScreen> createState() =>
      _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends ConsumerState<AdminApprovalScreen> {
  final Set<String> _approvingIds = {};
  final Set<String> _removedIds = {};

  Future<void> _handleApprove(AlumniSearchResult alumni) async {
    setState(() => _approvingIds.add(alumni.id));

    final success =
        await ref.read(pendingAlumniProvider.notifier).approveAlumni(alumni.id);

    if (!mounted) return;

    if (success) {
      setState(() {
        _approvingIds.remove(alumni.id);
        _removedIds.add(alumni.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${alumni.fullName} has been approved and activated.',
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
      setState(() => _approvingIds.remove(alumni.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to approve alumni. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(pendingAlumniProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Moderation Portal'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: pendingAsync.when(
        loading: () => ListView.builder(
          padding: AppSpacing.pagePadding,
          itemCount: 3,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: LoadingSkeleton.card(height: 140),
          ),
        ),
        error: (err, _) => EmptyState(
          icon: Icons.admin_panel_settings_outlined,
          title: 'Unable to Load Queue',
          message: 'Failed to retrieve pending alumni approvals.',
          actionText: 'Retry',
          onAction: () => ref.read(pendingAlumniProvider.notifier).loadPending(),
        ),
        data: (pendingList) {
          final visibleList =
              pendingList.where((item) => !_removedIds.contains(item.id)).toList();

          if (visibleList.isEmpty) {
            return const EmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'Queue is Clear',
              message: 'All alumni registrations have been reviewed and approved.',
            );
          }

          return ListView.builder(
            padding: AppSpacing.pagePadding,
            itemCount: visibleList.length,
            itemBuilder: (context, index) {
              final alumni = visibleList[index];
              final isApproving = _approvingIds.contains(alumni.id);

              return AnimatedOpacity(
                duration: const Duration(milliseconds: 350),
                opacity: _removedIds.contains(alumni.id) ? 0.0 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MedallionBadge.fromGradYear(
                              alumni.graduationYear,
                              size: 44,
                            ),
                            AppSpacing.gapH12,
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
                                  ),
                                  AppSpacing.gapV2,
                                  Text(
                                    alumni.email,
                                    style: GoogleFonts.ibmPlexSans(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (alumni.designation != null &&
                                      alumni.company != null) ...[
                                    AppSpacing.gapV4,
                                    Text(
                                      '${alumni.designation} at ${alumni.company}',
                                      style: GoogleFonts.ibmPlexSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.gapV12,
                        const Divider(),
                        AppSpacing.gapV12,

                        Row(
                          children: [
                            if (alumni.branch != null)
                              Text(
                                'Dept: ${alumni.branch}',
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            const Spacer(),
                            SizedBox(
                              height: 36,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusXs,
                                    ),
                                  ),
                                ),
                                icon: isApproving
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.0,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.check_rounded,
                                        size: 16,
                                      ),
                                label: Text(
                                  isApproving ? 'Approving...' : 'Approve',
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onPressed: isApproving
                                    ? null
                                    : () => _handleApprove(alumni),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
