import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/job.dart';
import '../../providers/jobs_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/medallion_badge.dart';
import '../../widgets/status_pill.dart';

class ApplicantTrackingScreen extends ConsumerWidget {
  final String jobId;

  const ApplicantTrackingScreen({super.key, required this.jobId});

  Future<void> _launchResume(BuildContext context, String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri != null) {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open resume document.')),
        );
      }
    }
  }

  Future<void> _updateCandidateStatus(
    BuildContext context,
    WidgetRef ref,
    String applicationId,
    String newStatus,
    String candidateName,
  ) async {
    final success = await ref
        .read(jobApplicationsProvider(jobId).notifier)
        .updateStatus(applicationId, newStatus);

    if (!context.mounted) return;

    if (success) {
      final statusLabel =
          newStatus == 'shortlisted' ? 'Shortlisted' : (newStatus == 'rejected' ? 'Rejected' : 'Applied');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$candidateName marked as $statusLabel.',
            style: GoogleFonts.ibmPlexSans(
              color: newStatus == 'shortlisted'
                  ? AppColors.secondary
                  : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            side: const BorderSide(color: AppColors.secondary, width: 1.0),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update candidate status. Action was rolled back.',
            style: GoogleFonts.ibmPlexSans(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(jobApplicationsProvider(jobId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Applicant Pipeline'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: applicationsAsync.when(
        loading: () => ListView.builder(
          padding: AppSpacing.pagePadding,
          itemCount: 3,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: LoadingSkeleton.card(height: 180),
          ),
        ),
        error: (err, _) => EmptyState(
          icon: Icons.person_off_outlined,
          title: 'Unable to Load Applicants',
          message: 'Failed to retrieve submitted candidates.',
          actionText: 'Retry',
          onAction: () =>
              ref.read(jobApplicationsProvider(jobId).notifier).loadApplications(),
        ),
        data: (applicants) {
          if (applicants.isEmpty) {
            return const EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No Applications Received',
              message:
                  'No candidates have applied to this opportunity yet.',
            );
          }

          return ListView.builder(
            padding: AppSpacing.pagePadding,
            itemCount: applicants.length,
            itemBuilder: (context, index) {
              final app = applicants[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 14.0),
                child: _ApplicantCard(
                  application: app,
                  onStatusChanged: (newStatus) => _updateCandidateStatus(
                    context,
                    ref,
                    app.id,
                    newStatus,
                    app.studentName,
                  ),
                  onViewResume: () => _launchResume(context, app.resumeUrl),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  final JobApplicationDetail application;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onViewResume;

  const _ApplicantCard({
    required this.application,
    required this.onStatusChanged,
    required this.onViewResume,
  });

  @override
  Widget build(BuildContext context) {
    final status = application.status.toLowerCase();
    final appliedDate =
        DateFormat('MMM dd, yyyy').format(application.createdAt);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MedallionBadge.fromGradYear(
                application.studentGradYear,
                size: 44,
              ),
              AppSpacing.gapH12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.studentName,
                      style: GoogleFonts.fraunces(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapV2,
                    Text(
                      '${application.studentBranch} • USN: ${application.studentUsn}',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Applied on $appliedDate',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH8,

              // Status Indicator Pill
              _buildStatusPill(status),
            ],
          ),

          if (application.coverNote != null &&
              application.coverNote!.isNotEmpty) ...[
            AppSpacing.gapV12,
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                border: Border.all(color: AppColors.border, width: 0.8),
              ),
              child: Text(
                '"${application.coverNote}"',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],

          AppSpacing.gapV16,
          const Divider(),
          AppSpacing.gapV12,

          // Resume Link Action & Status Segmented Buttons
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onViewResume,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.border, width: 1.0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  ),
                ),
                icon: const Icon(Icons.picture_as_pdf_outlined,
                    size: 16, color: AppColors.error),
                label: Text(
                  'View Resume',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapV12,

          // Segmented Button Status Selector
          SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(
                value: 'applied',
                label: Text('Applied'),
                icon: Icon(Icons.inbox_outlined, size: 14),
              ),
              ButtonSegment<String>(
                value: 'shortlisted',
                label: Text('Shortlist'),
                icon: Icon(Icons.check_circle_outline, size: 14),
              ),
              ButtonSegment<String>(
                value: 'rejected',
                label: Text('Reject'),
                icon: Icon(Icons.cancel_outlined, size: 14),
              ),
            ],
            selected: {status},
            onSelectionChanged: (newSelection) {
              if (newSelection.isNotEmpty) {
                onStatusChanged(newSelection.first);
              }
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.selected)) {
                  if (status == 'shortlisted') return AppColors.successBg;
                  if (status == 'rejected') return AppColors.errorBg;
                  return AppColors.goldLight;
                }
                return Colors.transparent;
              }),
              foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.selected)) {
                  if (status == 'shortlisted') return AppColors.success;
                  if (status == 'rejected') return AppColors.error;
                  return AppColors.primary;
                }
                return AppColors.textSecondary;
              }),
              textStyle: MaterialStateProperty.all(
                GoogleFonts.ibmPlexSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    if (status == 'shortlisted') {
      return StatusPill(
        label: 'Shortlisted',
        type: StatusPillType.success,
        icon: Icons.check_circle_rounded,
      );
    } else if (status == 'rejected') {
      return StatusPill(
        label: 'Rejected',
        type: StatusPillType.error,
        icon: Icons.cancel_rounded,
      );
    }
    return StatusPill(
      label: 'Applied',
      type: StatusPillType.neutral,
      icon: Icons.inbox_rounded,
    );
  }
}
