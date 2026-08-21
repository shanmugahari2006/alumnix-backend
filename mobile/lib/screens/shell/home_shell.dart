import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/medallion_badge.dart';

/// App Shell Widget providing persistent Bottom Navigation for 5 tabs
class HomeShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShell({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    final tabs = [
      _ShellTabItem(
        label: 'Directory',
        icon: Icons.people_outline_rounded,
        selectedIcon: Icons.people_rounded,
      ),
      _ShellTabItem(
        label: 'Jobs',
        icon: Icons.work_outline_rounded,
        selectedIcon: Icons.work_rounded,
      ),
      _ShellTabItem(
        label: 'Stories',
        icon: Icons.auto_stories_outlined,
        selectedIcon: Icons.auto_stories_rounded,
      ),
      _ShellTabItem(
        label: 'Fundraisers',
        icon: Icons.volunteer_activism_outlined,
        selectedIcon: Icons.volunteer_activism_rounded,
      ),
      _ShellTabItem(
        label: 'Events',
        icon: Icons.event_outlined,
        selectedIcon: Icons.event_rounded,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: AppColors.secondary,
                size: 18,
              ),
            ),
            AppSpacing.gapH8,
            RichText(
              text: TextSpan(
                style: GoogleFonts.fraunces(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: -0.3,
                ),
                children: const [
                  TextSpan(text: 'ALUMNIX'),
                  TextSpan(
                    text: ' .',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () => context.push('/profile'),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  children: [
                    if (user?.alumniProfile?.graduationYear != null)
                      MedallionBadge.fromGradYear(
                        user!.alumniProfile!.graduationYear,
                        size: 34,
                      )
                    else
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.goldLight,
                          border: Border.all(
                            color: AppColors.secondary,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.person_outline_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.border,
            height: 1.0,
          ),
        ),
      ),
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.border,
              width: 1.0,
            ),
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
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(tabs.length, (index) {
                final isSelected = navigationShell.currentIndex == index;
                final tab = tabs[index];

                return Expanded(
                  child: InkWell(
                    onTap: () => _onTap(index),
                    splashColor: AppColors.goldLight,
                    highlightColor: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Top gold underline indicator when selected
                        Container(
                          height: 3.0,
                          width: 28.0,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.secondary : Colors.transparent,
                            borderRadius: BorderRadius.circular(2.0),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          isSelected ? tab.selectedIcon : tab.icon,
                          size: 22,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tab.label,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellTabItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  _ShellTabItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}
