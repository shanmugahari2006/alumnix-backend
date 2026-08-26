import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/alumni_profile.dart';
import '../../providers/alumni_provider.dart';
import '../../providers/chat_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/medallion_badge.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import '../../widgets/status_pill.dart';

class AlumniDetailScreen extends ConsumerWidget {
  final String id;

  const AlumniDetailScreen({super.key, required this.id});

  Future<void> _launchLinkedIn(BuildContext context, String? urlString) async {
    if (urlString == null || urlString.trim().isEmpty) return;

    var formatted = urlString.trim();
    if (!formatted.startsWith('http://') && !formatted.startsWith('https://')) {
      formatted = 'https://$formatted';
    }

    final uri = Uri.tryParse(formatted);
    if (uri != null) {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open LinkedIn profile.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alumniAsync = ref.watch(alumniDetailProvider(id));

    return alumniAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: const Text('Alumni Profile', style: TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
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
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: const Text('Profile'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: EmptyState(
          icon: Icons.person_off_outlined,
          title: 'Profile Unavailable',
          message: 'Unable to retrieve this alumni profile.',
          actionText: 'Go Back',
          onAction: () => context.pop(),
        ),
      ),
      data: (alumni) {
        if (alumni == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              title: const Text('Profile Not Found'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ),
            body: const EmptyState(
              title: 'Not Found',
              message: 'Alumni record was not found.',
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          // Navy AppBar with alumnus's name
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              alumni.fullName,
              style: GoogleFonts.fraunces(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Profile Card with Large Medallion
                AppCard(
                  child: Column(
                    children: [
                      Center(
                        child: MedallionBadge.fromGradYear(
                          alumni.graduationYear,
                          size: 76,
                        ),
                      ),
                      AppSpacing.gapV16,
                      Text(
                        alumni.fullName,
                        style: GoogleFonts.fraunces(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      AppSpacing.gapV4,
                      if (alumni.designation != null || alumni.company != null)
                        Text(
                          [alumni.designation, alumni.company]
                              .where((e) => e != null && e.isNotEmpty)
                              .join(' at '),
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      AppSpacing.gapV12,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          StatusPill.verified(),
                          AppSpacing.gapH8,
                          StatusPill(
                            label: 'Class of ${alumni.graduationYear}',
                            type: StatusPillType.neutral,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapV16,

                // Bio / Statement (if present)
                if (alumni.bio != null && alumni.bio!.trim().isNotEmpty) ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About',
                          style: GoogleFonts.fraunces(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        AppSpacing.gapV8,
                        Text(
                          alumni.bio!,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapV16,
                ],

                // Academic & Location Info
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Academic Heritage & Location',
                        style: GoogleFonts.fraunces(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      AppSpacing.gapV12,
                      _DetailInfoRow(
                        icon: Icons.school_outlined,
                        label: 'Department',
                        value: alumni.branch ?? 'Computer Science & Eng.',
                      ),
                      const Divider(height: 16),
                      _DetailInfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Convocation Year',
                        value: alumni.graduationYear.toString(),
                      ),
                      if (alumni.location != null) ...[
                        const Divider(height: 16),
                        _DetailInfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Current City',
                          value: alumni.location!,
                        ),
                      ],
                      if (alumni.linkedinUrl != null &&
                          alumni.linkedinUrl!.isNotEmpty) ...[
                        const Divider(height: 16),
                        Row(
                          children: [
                            const Icon(
                              Icons.link_rounded,
                              size: 18,
                              color: AppColors.secondary,
                            ),
                            AppSpacing.gapH12,
                            Text(
                              'Professional Profile',
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () => _launchLinkedIn(
                                context,
                                alumni.linkedinUrl,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'LinkedIn Profile',
                                    style: GoogleFonts.ibmPlexSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.open_in_new_rounded,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                AppSpacing.gapV16,

                // Skills Card
                if (alumni.skills.isNotEmpty) ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Areas of Expertise',
                          style: GoogleFonts.fraunces(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        AppSpacing.gapV12,
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: alumni.skills.map((skill) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.goldLight,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusXs),
                                border: Border.all(
                                  color: AppColors.secondary.withOpacity(0.4),
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                skill,
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapV24,
                ],

                // Connect Action Buttons
                PrimaryButton(
                  text: 'Request Mentorship Connection',
                  icon: Icons.handshake_outlined,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Mentorship request sent to ${alumni.fullName}!',
                          style: GoogleFonts.ibmPlexSans(color: Colors.white),
                        ),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                ),
                AppSpacing.gapV12,
                SecondaryButton(
                  text: 'Send Direct Message',
                  icon: Icons.email_outlined,
                  onPressed: () async {
                    final conv = await ref
                        .read(conversationsProvider.notifier)
                        .startConversation(alumni.id);
                    if (conv != null && context.mounted) {
                      context.push('/chat/${conv.id}');
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        AppSpacing.gapH12,
        Text(
          label,
          style: GoogleFonts.ibmPlexSans(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.ibmPlexSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
