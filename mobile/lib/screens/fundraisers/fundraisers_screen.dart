import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/fundraiser.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fundraisers_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_skeleton.dart';

class FundraisersScreen extends ConsumerWidget {
  const FundraisersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fundraisersAsync = ref.watch(fundraisersListProvider);
    final authState = ref.watch(authStateProvider);
    final userRole = authState.user?.role;
    final canLaunch = userRole == UserRole.student || userRole == UserRole.admin;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: canLaunch
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/fundraisers/create'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.rocket_launch_outlined,
                  color: AppColors.secondary),
              label: Text(
                'Launch Campaign',
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
          await ref.read(fundraisersListProvider.notifier).loadFundraisers();
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
                      'Startup Fundraising',
                      style: GoogleFonts.fraunces(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapV4,
                    Text(
                      'Seed collegiate innovation. Back student & alumni ventures.',
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

            // 2-Column Responsive Grid of Campaigns
            fundraisersAsync.when(
              loading: () => SliverPadding(
                padding: AppSpacing.pagePadding,
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12.0,
                    crossAxisSpacing: 12.0,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => LoadingSkeleton.card(height: 220),
                    childCount: 4,
                  ),
                ),
              ),
              error: (err, _) => SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Unable to Load Campaigns',
                  message: 'Failed to retrieve active startup fundraisers.',
                  actionText: 'Retry',
                  onAction: () =>
                      ref.read(fundraisersListProvider.notifier).loadFundraisers(),
                ),
              ),
              data: (campaigns) {
                if (campaigns.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.rocket_outlined,
                      title: 'No Active Campaigns',
                      message:
                          'Be the first founder to pitch an innovation to alumni backers.',
                      actionText: canLaunch ? 'Launch Campaign' : null,
                      onAction: canLaunch
                          ? () => context.push('/fundraisers/create')
                          : null,
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 80.0),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12.0,
                      crossAxisSpacing: 12.0,
                      childAspectRatio: 0.68,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final campaign = campaigns[index];
                        return _CampaignGridCard(campaign: campaign);
                      },
                      childCount: campaigns.length,
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

class _CampaignGridCard extends StatelessWidget {
  final Fundraiser campaign;

  const _CampaignGridCard({required this.campaign});

  String _formatCompact(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(0)}K';
    }
    return '₹${amount.toInt()}';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12.0),
      onTap: () => context.push('/fundraisers/${campaign.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Startup Name Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.goldLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              border: Border.all(
                color: AppColors.secondary.withOpacity(0.4),
                width: 0.8,
              ),
            ),
            child: Text(
              campaign.startupName,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AppSpacing.gapV8,

          // Campaign Title (Fraunces)
          Expanded(
            child: Text(
              campaign.title,
              style: GoogleFonts.fraunces(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.25,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AppSpacing.gapV10,

          // Slim Progress Bar (Navy Track, Forest Green Fill)
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: campaign.progressRatio,
              minHeight: 5.0,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.success, // Forest Green
              ),
            ),
          ),
          AppSpacing.gapV8,

          // Metrics & Percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${campaign.percentFunded}%',
                style: GoogleFonts.fraunces(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
              Text(
                '${_formatCompact(campaign.raisedAmount)} / ${_formatCompact(campaign.targetAmount)}',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
