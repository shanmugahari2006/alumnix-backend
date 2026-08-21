import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/medallion_badge.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import '../../widgets/status_pill.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final isAlumni = user?.role == UserRole.alumni;
    final isAdmin = user?.role == UserRole.admin;
    final alumniProfile = user?.alumniProfile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header Card
            AppCard(
              child: Column(
                children: [
                  Center(
                    child: alumniProfile?.graduationYear != null
                        ? MedallionBadge.fromGradYear(
                            alumniProfile!.graduationYear,
                            size: 72,
                          )
                        : Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.goldLight,
                              border: Border.all(
                                color: AppColors.secondary,
                                width: 2.0,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.person_rounded,
                                size: 36,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                  ),
                  AppSpacing.gapV16,
                  Text(
                    user?.fullName ?? 'Distinguished Member',
                    style: GoogleFonts.fraunces(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.gapV4,
                  if (alumniProfile?.designation != null ||
                      alumniProfile?.company != null) ...[
                    Text(
                      [alumniProfile?.designation, alumniProfile?.company]
                          .where((e) => e != null && e.isNotEmpty)
                          .join(' at '),
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.gapV4,
                  ],
                  Text(
                    user?.email ?? 'member@university.edu',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.gapV12,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StatusPill.role(user?.role.displayName ?? 'Student'),
                      AppSpacing.gapH8,
                      StatusPill.verified(),
                    ],
                  ),
                ],
              ),
            ),
            AppSpacing.gapV16,

            // Alumni Edit Profile Action (Alumni role only)
            if (isAlumni) ...[
              PrimaryButton(
                text: 'Edit My Profile',
                icon: Icons.edit_outlined,
                onPressed: () => context.push('/profile/edit'),
              ),
              AppSpacing.gapV16,
            ],

            // Admin Moderation Queue (Admin role only)
            if (isAdmin) ...[
              Container(
                decoration: BoxDecoration(
                  color: AppColors.goldLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: AppColors.secondary, width: 1.2),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                  title: Text(
                    'Admin Moderation Portal',
                    style: GoogleFonts.fraunces(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Review and approve pending alumni accounts',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  onTap: () => context.push('/profile/admin-approvals'),
                ),
              ),
              AppSpacing.gapV16,
            ],

            // Institutional Details
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Institutional Registry',
                    style: GoogleFonts.fraunces(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapV12,
                  _ProfileItem(
                    icon: Icons.badge_outlined,
                    title: 'Account Role',
                    value: user?.role.displayName ?? 'Student',
                  ),
                  const Divider(height: 16),
                  _ProfileItem(
                    icon: Icons.verified_outlined,
                    title: 'Verification Status',
                    value: 'Identity Confirmed',
                  ),
                  if (alumniProfile?.location != null &&
                      alumniProfile!.location!.isNotEmpty) ...[
                    const Divider(height: 16),
                    _ProfileItem(
                      icon: Icons.location_on_outlined,
                      title: 'Location',
                      value: alumniProfile.location!,
                    ),
                  ],
                  if (alumniProfile?.skills != null &&
                      alumniProfile!.skills.isNotEmpty) ...[
                    const Divider(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Skills',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        AppSpacing.gapV8,
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: alumniProfile.skills.map((s) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.goldLight,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusXs),
                                border: Border.all(
                                  color: AppColors.secondary.withOpacity(0.4),
                                ),
                              ),
                              child: Text(
                                s,
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            AppSpacing.gapV24,

            // Sign Out
            SecondaryButton(
              text: 'Sign Out of Alumnix',
              icon: Icons.logout_rounded,
              borderColor: AppColors.error,
              textColor: AppColors.error,
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    title: Text(
                      'Sign Out',
                      style: GoogleFonts.fraunces(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    content: Text(
                      'Are you sure you want to log out of your Alumnix session?',
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref.read(authStateProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.secondary),
        AppSpacing.gapH12,
        Text(
          title,
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
