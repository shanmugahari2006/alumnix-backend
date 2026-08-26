import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _identifierFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Timer? _countdownTimer;
  int _remainingSeconds = 300; // 5 minutes code expiration

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(forgotPasswordProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    setState(() => _remainingSeconds = 300);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTimer() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _handleSendCode() async {
    if (!_identifierFormKey.currentState!.validate()) return;
    
    final identifier = _identifierController.text.trim();
    final success = await ref.read(forgotPasswordProvider.notifier).sendRecoveryCode(identifier);
    
    if (success && mounted) {
      _startTimer();
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await ref.read(forgotPasswordProvider.notifier).resetPassword(
          code: _codeController.text.trim(),
          newPassword: _newPasswordController.text.trim(),
        );

    if (success && mounted) {
      _countdownTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
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
                  // Crest & Wordmark
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        border: Border.all(
                          color: AppColors.secondary,
                          width: 2.0,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.lock_reset_rounded,
                          color: AppColors.secondary,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapV16,
                  Text(
                    'ALUMNIX',
                    style: GoogleFonts.fraunces(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.gapV24,

                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          state.step == 0
                              ? 'Password Recovery'
                              : state.step == 1
                                  ? 'Reset Password'
                                  : 'Success!',
                          style: GoogleFonts.fraunces(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        AppSpacing.gapV4,
                        Text(
                          state.step == 0
                              ? 'Enter your registered email or phone number to receive a recovery code.'
                              : state.step == 1
                                  ? 'Enter the 6-digit recovery code sent to your account along with your new password.'
                                  : 'Your password has been changed. You can now sign in with your new credentials.',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        AppSpacing.gapV20,

                        // Messages / Errors
                        if (state.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                              border: Border.all(color: AppColors.error, width: 0.5),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
                                AppSpacing.gapH8,
                                Expanded(
                                  child: Text(
                                    state.errorMessage!,
                                    style: GoogleFonts.ibmPlexSans(
                                      fontSize: 12,
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.gapV16,
                        ],
                        if (state.successMessage != null && state.step != 2) ...[
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                              border: Border.all(color: AppColors.success, width: 0.5),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.success),
                                AppSpacing.gapH8,
                                Expanded(
                                  child: Text(
                                    state.successMessage!,
                                    style: GoogleFonts.ibmPlexSans(
                                      fontSize: 12,
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.gapV16,
                        ],

                        // Step 0 Form
                        if (state.step == 0)
                          Form(
                            key: _identifierFormKey,
                            child: Column(
                              children: [
                                AppTextField(
                                  label: 'Email or Phone Number',
                                  hint: 'you@example.com or +91...',
                                  controller: _identifierController,
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: Icons.email_outlined,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Please enter email or phone number';
                                    }
                                    return null;
                                  },
                                ),
                                AppSpacing.gapV24,
                                PrimaryButton(
                                  text: 'Send Recovery Code',
                                  isLoading: state.isLoading,
                                  onPressed: _handleSendCode,
                                ),
                              ],
                            ),
                          ),

                        // Step 1 Form
                        if (state.step == 1)
                          Form(
                            key: _resetFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Code expires in:',
                                      style: GoogleFonts.ibmPlexSans(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      _formatTimer(),
                                      style: GoogleFonts.ibmPlexSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: _remainingSeconds < 60
                                            ? AppColors.error
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                AppSpacing.gapV12,
                                AppTextField(
                                  label: 'Recovery Code',
                                  hint: '000000',
                                  controller: _codeController,
                                  keyboardType: TextInputType.number,
                                  prefixIcon: Icons.pin_outlined,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Please enter the 6-digit code';
                                    }
                                    return null;
                                  },
                                ),
                                AppSpacing.gapV16,
                                AppTextField(
                                  label: 'New Password',
                                  hint: 'At least 8 characters',
                                  controller: _newPasswordController,
                                  isPassword: true,
                                  prefixIcon: Icons.lock_outline_rounded,
                                  validator: (v) {
                                    if (v == null || v.trim().length < 8) {
                                      return 'Password must be at least 8 characters';
                                    }
                                    return null;
                                  },
                                ),
                                AppSpacing.gapV16,
                                AppTextField(
                                  label: 'Confirm Password',
                                  hint: '••••••••',
                                  controller: _confirmPasswordController,
                                  isPassword: true,
                                  prefixIcon: Icons.lock_outline_rounded,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Please confirm your password';
                                    }
                                    return null;
                                  },
                                ),
                                AppSpacing.gapV24,
                                PrimaryButton(
                                  text: 'Reset Password',
                                  isLoading: state.isLoading,
                                  onPressed: _handleResetPassword,
                                ),
                                AppSpacing.gapV12,
                                TextButton(
                                  onPressed: () {
                                    ref.read(forgotPasswordProvider.notifier).reset();
                                  },
                                  child: Text(
                                    'Change Email / Phone',
                                    style: GoogleFonts.ibmPlexSans(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Step 2 Finished
                        if (state.step == 2)
                          Column(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.success,
                                size: 48,
                              ),
                              AppSpacing.gapV16,
                              SecondaryButton(
                                text: 'Back to Sign In',
                                onPressed: () {
                                  context.pop();
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
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
