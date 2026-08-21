import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _inlineError;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _inlineError = null;
    });

    final success = await ref.read(authStateProvider.notifier).login(
          identifier: _identifierController.text.trim(),
          password: _passwordController.text.trim(),
        );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    final authState = ref.read(authStateProvider);

    if (success) {
      context.go('/directory');
    } else {
      if (authState.isAlumniPending) {
        context.push('/account-pending?type=alumni');
      } else if (authState.isFacultyPending) {
        context.push('/account-pending?type=faculty');
      } else {
        setState(() {
          _inlineError = authState.errorMessage ?? 'Invalid email/phone or password.';
        });
      }
    }
  }

  void _fillDemoAccount(String type) {
    if (type == 'alumni') {
      _identifierController.text = 'eleanor.vance@stanford.alumni.edu';
      _passwordController.text = 'password123';
    } else if (type == 'faculty') {
      _identifierController.text = 'julian.hayes@oxford.alumni.edu';
      _passwordController.text = 'password123';
    } else {
      _identifierController.text = 'demo.student@stanford.edu';
      _passwordController.text = 'password123';
    }
    setState(() => _inlineError = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Convocation Crest & Wordmark
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                          border: Border.all(
                            color: AppColors.secondary,
                            width: 2.0,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.cardShadow,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.school_rounded,
                            color: AppColors.secondary,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    AppSpacing.gapV16,
                    Text(
                      'ALUMNIX',
                      style: GoogleFonts.fraunces(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Collegial Heritage & Alumni Network',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.gapV32,

                    // Card Container
                    Container(
                      padding: AppSpacing.cardPadding,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border.all(
                          color: AppColors.border,
                          width: 1.0,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Sign In',
                            style: GoogleFonts.fraunces(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          AppSpacing.gapV4,
                          Text(
                            'Enter your credentials to enter the portal.',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          AppSpacing.gapV24,

                          // Single Input for Email or Phone Number
                          AppTextField(
                            label: 'Email or Phone Number',
                            hint: 'name@university.edu or +1234567890',
                            controller: _identifierController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.person_outline_rounded,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Please enter your email or phone number';
                              }
                              return null;
                            },
                          ),
                          AppSpacing.gapV16,

                          AppTextField(
                            label: 'Password',
                            hint: '••••••••',
                            controller: _passwordController,
                            isPassword: true,
                            prefixIcon: Icons.lock_outline_rounded,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Password is required';
                              }
                              return null;
                            },
                          ),

                          // Standard Inline Error under Password Field
                          if (_inlineError != null) ...[
                            AppSpacing.gapV12,
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    size: 16, color: AppColors.error),
                                AppSpacing.gapH6,
                                Expanded(
                                  child: Text(
                                    _inlineError!,
                                    style: GoogleFonts.ibmPlexSans(
                                      fontSize: 12,
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          AppSpacing.gapV24,

                          PrimaryButton(
                            text: 'Sign In to Portal',
                            isLoading: _isLoading,
                            onPressed: _handleLogin,
                          ),
                          AppSpacing.gapV16,

                          // Quick Demo Credentials
                          Text(
                            'Quick Demo Credentials:',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          AppSpacing.gapV8,
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              ActionChip(
                                label: const Text('Alumni Demo'),
                                onPressed: () => _fillDemoAccount('alumni'),
                                labelStyle: const TextStyle(fontSize: 11),
                                backgroundColor: AppColors.goldLight,
                                side: const BorderSide(
                                    color: AppColors.secondary, width: 0.8),
                              ),
                              ActionChip(
                                label: const Text('Student Demo'),
                                onPressed: () => _fillDemoAccount('student'),
                                labelStyle: const TextStyle(fontSize: 11),
                                backgroundColor: AppColors.background,
                                side: const BorderSide(color: AppColors.border),
                              ),
                              ActionChip(
                                label: const Text('Faculty Demo'),
                                onPressed: () => _fillDemoAccount('faculty'),
                                labelStyle: const TextStyle(fontSize: 11),
                                backgroundColor: AppColors.background,
                                side: const BorderSide(color: AppColors.border),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.gapV24,

                    // Registration Links
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "New to the network?",
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/register'),
                          child: const Text('Register (Student / Alumni)'),
                        ),
                      ],
                    ),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => context.push('/register/faculty'),
                        icon: const Icon(Icons.school_outlined, size: 16),
                        label: const Text('Faculty Onboarding Portal'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
