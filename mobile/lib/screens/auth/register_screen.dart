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
import '../../widgets/otp_input_row.dart';
import '../../widgets/password_strength_bar.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  late final PageController _pageController;
  final _usnController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Step 3 OTP Timer & Resend Cooldown
  Timer? _countdownTimer;
  int _otpRemainingSeconds = 300; // 5:00 minutes expiration
  Timer? _resendCooldownTimer;
  int _resendCooldownSeconds = 30; // 30s resend cooldown

  String _otpCode = '';
  String _selectedChannel = 'email'; // 'email' | 'phone'
  bool _showUsnConfirmation = false;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _usnController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _countdownTimer?.cancel();
    _resendCooldownTimer?.cancel();
    super.dispose();
  }

  void _startOtpTimers() {
    _countdownTimer?.cancel();
    _resendCooldownTimer?.cancel();

    setState(() {
      _otpRemainingSeconds = 300;
      _resendCooldownSeconds = 30;
      _otpCode = '';
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpRemainingSeconds > 0) {
        setState(() => _otpRemainingSeconds--);
      } else {
        timer.cancel();
      }
    });

    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldownSeconds > 0) {
        setState(() => _resendCooldownSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _navigateToPage(int page) {
    setState(() => _inlineError = null);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showStyledSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.ibmPlexSans(
            color: isSuccess ? AppColors.secondary : Colors.white,
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
  }

  // ---------------------------------------------------------------------------
  // Action Handlers
  // ---------------------------------------------------------------------------

  void _handleRolePicked(String role) {
    ref.read(registrationWizardProvider.notifier).setRole(role);
    _navigateToPage(1);
  }

  Future<void> _handleVerifyUsn() async {
    final usn = _usnController.text.trim();
    if (usn.isEmpty) {
      setState(() => _inlineError = 'Please enter your USN / Student Seat Number');
      return;
    }

    setState(() => _inlineError = null);
    final success =
        await ref.read(registrationWizardProvider.notifier).verifyUsn(usn);

    if (success) {
      setState(() => _showUsnConfirmation = true);
    } else {
      final error = ref.read(registrationWizardProvider).errorMessage;
      setState(() => _inlineError = error ?? 'USN verification failed.');
    }
  }

  Future<void> _handleSendOtp() async {
    final success = await ref
        .read(registrationWizardProvider.notifier)
        .sendOtp(_selectedChannel);

    if (success) {
      _startOtpTimers();
      _navigateToPage(3);
    } else {
      final error = ref.read(registrationWizardProvider).errorMessage;
      _showStyledSnackBar(error ?? 'Failed to dispatch OTP code');
    }
  }

  Future<void> _handleResendOtp() async {
    if (_resendCooldownSeconds > 0) return;
    await _handleSendOtp();
    _showStyledSnackBar('New verification code sent to your registered $_selectedChannel');
  }

  Future<void> _handleVerifyOtp() async {
    if (_otpCode.length != 6) {
      setState(() => _inlineError = 'Please enter the complete 6-digit code');
      return;
    }

    setState(() => _inlineError = null);
    final success =
        await ref.read(registrationWizardProvider.notifier).verifyOtp(_otpCode);

    if (success) {
      _countdownTimer?.cancel();
      _resendCooldownTimer?.cancel();
      _navigateToPage(4);
    } else {
      final error = ref.read(registrationWizardProvider).errorMessage;
      setState(() => _inlineError = error ?? 'Invalid verification code');
    }
  }

  Future<void> _handleSetupPassword() async {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.length < 8) {
      setState(() => _inlineError = 'Password must be at least 8 characters');
      return;
    }
    if (password != confirm) {
      setState(() => _inlineError = 'Passwords do not match');
      return;
    }

    setState(() => _inlineError = null);
    final success = await ref
        .read(registrationWizardProvider.notifier)
        .setupPassword(password);

    if (success) {
      _navigateToPage(5); // Success Screen
    } else {
      final wizardState = ref.read(registrationWizardProvider);
      if (wizardState.currentStep == 2) {
        // Token expired backtrack to Step 2
        _showStyledSnackBar(
          'Your verification expired, please request a new code',
        );
        _navigateToPage(2);
      } else {
        setState(() => _inlineError = wizardState.errorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wizard = ref.watch(registrationWizardProvider);
    final int stepNumber = (wizard.currentStep == 0)
        ? 0
        : (wizard.currentStep > 4 ? 4 : wizard.currentStep);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Alumni & Student Onboarding'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (wizard.currentStep > 0 && wizard.currentStep < 5) {
              final prev = wizard.currentStep - 1;
              ref.read(registrationWizardProvider.notifier).goToStep(prev);
              _navigateToPage(prev);
            } else {
              context.pop();
            }
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(42.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      stepNumber == 0
                          ? 'Choose Affiliation'
                          : 'Step $stepNumber of 4',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      wizard.role == 'alumni' ? 'Alumni Registry' : 'Student Registry',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              LinearProgressIndicator(
                value: stepNumber / 4.0,
                minHeight: 3.5,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Wizard controls paging
              children: [
                _buildRolePickerStep(),
                _buildUsnStep(wizard),
                _buildSendOtpStep(wizard),
                _buildVerifyOtpStep(wizard),
                _buildPasswordSetupStep(wizard),
                _buildSuccessStep(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 0: Role Picker Prelude
  // ---------------------------------------------------------------------------
  Widget _buildRolePickerStep() {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV12,
          Text(
            'Select Your Affiliation',
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapV4,
          Text(
            'We verify records against the official university registry.',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.gapV24,

          // Student Option Card
          _RoleOptionCard(
            title: "I'm a Student",
            subtitle: 'Enrolled undergraduate or postgraduate collegiate scholar',
            icon: Icons.school_outlined,
            badgeText: 'STUDENT REGISTRY',
            onTap: () => _handleRolePicked('student'),
          ),
          AppSpacing.gapV16,

          // Alumni Option Card
          _RoleOptionCard(
            title: "I'm an Alumnus",
            subtitle: 'Graduated alumni of the university across all class years',
            icon: Icons.workspace_premium_outlined,
            badgeText: 'CONVOCATION ALUMNI',
            onTap: () => _handleRolePicked('alumni'),
          ),
          AppSpacing.gapV32,

          // Faculty Link
          Center(
            child: TextButton.icon(
              onPressed: () => context.push('/register/faculty'),
              icon: const Icon(Icons.account_balance_outlined, size: 18),
              label: const Text('Faculty & Academic Staff Onboarding'),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1: USN Verification
  // ---------------------------------------------------------------------------
  Widget _buildUsnStep(RegistrationWizardState wizard) {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV12,
          Text(
            'University Seat Verification',
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapV4,
          Text(
            'Enter your USN as recorded in the registry.',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.gapV24,

          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'University Seat Number (USN)',
                  hint: 'e.g. 1MS18CS042',
                  controller: _usnController,
                  prefixIcon: Icons.badge_outlined,
                ),
                if (_inlineError != null) ...[
                  AppSpacing.gapV12,
                  Text(
                    _inlineError!,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 12,
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                AppSpacing.gapV24,

                if (!_showUsnConfirmation)
                  PrimaryButton(
                    text: 'Verify USN with Registry',
                    isLoading: wizard.isLoading,
                    icon: Icons.verified_outlined,
                    onPressed: _handleVerifyUsn,
                  )
                else ...[
                  // Welcome Confirmation Banner
                  Container(
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: AppColors.goldLight,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                      border: Border.all(color: AppColors.secondary, width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.success, size: 20),
                            AppSpacing.gapH8,
                            Expanded(
                              child: Text(
                                'Record Found in Registry',
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.gapV8,
                        Text(
                          "Welcome, ${wizard.fullName} — let's verify it's you.",
                          style: GoogleFonts.fraunces(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapV20,
                  PrimaryButton(
                    text: 'Continue to Verification',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => _navigateToPage(2),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2: Select Channel & Send OTP
  // ---------------------------------------------------------------------------
  Widget _buildSendOtpStep(RegistrationWizardState wizard) {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV12,
          Text(
            'Select Verification Channel',
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapV4,
          Text(
            'We will send a one-time verification code to your registered contact on file.',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.gapV24,

          // Selectable Channel 1: Email
          _ChannelSelectCard(
            title: 'Send to Registered Email',
            subtitle: 'Dispatches OTP to the official email recorded in registry',
            icon: Icons.mail_outline_rounded,
            isSelected: _selectedChannel == 'email',
            onTap: () => setState(() => _selectedChannel = 'email'),
          ),
          AppSpacing.gapV16,

          // Selectable Channel 2: Phone
          _ChannelSelectCard(
            title: 'Send to Registered Phone',
            subtitle: 'Dispatches SMS code to the registered mobile number',
            icon: Icons.phone_android_rounded,
            isSelected: _selectedChannel == 'phone',
            onTap: () => setState(() => _selectedChannel = 'phone'),
          ),
          AppSpacing.gapV24,

          PrimaryButton(
            text: 'Send Verification Code',
            icon: Icons.send_rounded,
            isLoading: wizard.isLoading,
            onPressed: _handleSendOtp,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 3: Verify OTP (6-box input + live MM:SS countdown)
  // ---------------------------------------------------------------------------
  Widget _buildVerifyOtpStep(RegistrationWizardState wizard) {
    final bool isExpired = _otpRemainingSeconds == 0;
    final bool canResend = _resendCooldownSeconds == 0;

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV12,
          Text(
            'Enter Verification Code',
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapV4,
          Text(
            'A 6-digit code was sent to your registered $_selectedChannel.',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.gapV24,

          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OtpInputRow(
                  length: 6,
                  hasError: _inlineError != null,
                  onChanged: (val) {
                    setState(() {
                      _otpCode = val;
                      _inlineError = null;
                    });
                  },
                  onCompleted: (val) {
                    setState(() => _otpCode = val);
                    _handleVerifyOtp();
                  },
                ),
                if (_inlineError != null) ...[
                  AppSpacing.gapV12,
                  Text(
                    _inlineError!,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 12,
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                AppSpacing.gapV20,

                // Timer Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: isExpired ? AppColors.error : AppColors.secondary,
                    ),
                    AppSpacing.gapH6,
                    Text(
                      isExpired
                          ? 'Code Expired'
                          : 'Code expires in ${_formatTimer(_otpRemainingSeconds)}',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isExpired ? AppColors.error : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapV20,

                PrimaryButton(
                  text: 'Verify Code',
                  isLoading: wizard.isLoading,
                  onPressed: _handleVerifyOtp,
                ),
                AppSpacing.gapV16,

                // Resend Button
                Center(
                  child: TextButton.icon(
                    onPressed: canResend ? _handleResendOtp : null,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(
                      canResend
                          ? 'Resend OTP Code'
                          : 'Resend OTP in ${_resendCooldownSeconds}s',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: canResend
                            ? AppColors.primary
                            : AppColors.textSecondary.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 4: Password Setup with Strength Meter
  // ---------------------------------------------------------------------------
  Widget _buildPasswordSetupStep(RegistrationWizardState wizard) {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV12,
          Text(
            'Secure Your Account',
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapV4,
          Text(
            'Create a password to access your alumni profile and portal.',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.gapV24,

          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'New Password',
                  hint: 'Min. 8 characters',
                  controller: _passwordController,
                  isPassword: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  onChanged: (_) => setState(() {}),
                ),
                PasswordStrengthBar(password: _passwordController.text),
                AppSpacing.gapV16,

                AppTextField(
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  controller: _confirmPasswordController,
                  isPassword: true,
                  prefixIcon: Icons.lock_reset_rounded,
                ),

                if (_inlineError != null) ...[
                  AppSpacing.gapV12,
                  Text(
                    _inlineError!,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 12,
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                AppSpacing.gapV24,

                PrimaryButton(
                  text: 'Complete Account Setup',
                  isLoading: wizard.isLoading,
                  icon: Icons.check_rounded,
                  onPressed: _handleSetupPassword,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 5: Success & Redirection to /login
  // ---------------------------------------------------------------------------
  Widget _buildSuccessStep() {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV32,
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.successBg,
                border: Border.all(color: AppColors.success, width: 2.0),
              ),
              child: const Center(
                child: Icon(Icons.check_circle_rounded,
                    size: 42, color: AppColors.success),
              ),
            ),
          ),
          AppSpacing.gapV24,

          Text(
            'Account Created Successfully!',
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapV8,
          Text(
            'Your institutional record has been verified and your profile is configured. Please sign in with your credentials to enter the platform.',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapV32,

          PrimaryButton(
            text: 'Proceed to Sign In',
            icon: Icons.login_rounded,
            onPressed: () {
              ref.read(registrationWizardProvider.notifier).reset();
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper Subwidgets
// ---------------------------------------------------------------------------

class _RoleOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String badgeText;
  final VoidCallback onTap;

  const _RoleOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badgeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: AppColors.goldLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              border: Border.all(color: AppColors.secondary, width: 1.2),
            ),
            child: Icon(icon, size: 24, color: AppColors.primary),
          ),
          AppSpacing.gapH16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badgeText,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                    letterSpacing: 0.5,
                  ),
                ),
                AppSpacing.gapV4,
                Text(
                  title,
                  style: GoogleFonts.fraunces(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                AppSpacing.gapV4,
                Text(
                  subtitle,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.secondary),
        ],
      ),
    );
  }
}

class _ChannelSelectCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChannelSelectCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      stripeColor: isSelected ? AppColors.secondary : AppColors.border,
      backgroundColor: isSelected ? AppColors.goldLight.withOpacity(0.3) : AppColors.surface,
      borderColor: isSelected ? AppColors.secondary : AppColors.border,
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
          AppSpacing.gapH16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                AppSpacing.gapV2,
                Text(
                  subtitle,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Radio<bool>(
            value: true,
            groupValue: isSelected,
            activeColor: AppColors.secondary,
            onChanged: (_) => onTap(),
          ),
        ],
      ),
    );
  }
}
