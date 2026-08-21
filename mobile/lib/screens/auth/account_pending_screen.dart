import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/primary_button.dart';

enum AccountPendingType {
  alumni,
  faculty,
}

class AccountPendingScreen extends StatelessWidget {
  final AccountPendingType type;

  const AccountPendingScreen({
    super.key,
    this.type = AccountPendingType.alumni,
  });

  @override
  Widget build(BuildContext context) {
    final isAlumni = type == AccountPendingType.alumni;
    final title = isAlumni ? 'Alumni Account Under Review' : 'Faculty Verification Pending';
    final message = isAlumni
        ? "Your alumni account is awaiting approval. You'll be notified once it's approved."
        : "Your faculty account is still awaiting admin approval.";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Account Status'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Calm Navy & Gold Status Emblem (NOT error red)
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.goldLight,
                        border: Border.all(
                          color: AppColors.secondary,
                          width: 2.0,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x101B2A4A),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.hourglass_top_rounded,
                          size: 38,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapV24,

                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.fraunces(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        AppSpacing.gapV12,
                        Text(
                          message,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        AppSpacing.gapV24,
                        const Divider(),
                        AppSpacing.gapV16,
                        Row(
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              size: 18,
                              color: AppColors.secondary,
                            ),
                            AppSpacing.gapH12,
                            Expanded(
                              child: Text(
                                'Our administrative council reviews credentials within 24-48 hours to maintain platform integrity.',
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapV24,

                  PrimaryButton(
                    text: 'Return to Sign In',
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => context.go('/login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
