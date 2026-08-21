import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api/services/auth_service.dart';
import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/password_strength_bar.dart';
import '../../widgets/primary_button.dart';

class FacultyRegisterScreen extends ConsumerStatefulWidget {
  const FacultyRegisterScreen({super.key});

  @override
  ConsumerState<FacultyRegisterScreen> createState() =>
      _FacultyRegisterScreenState();
}

class _FacultyRegisterScreenState extends ConsumerState<FacultyRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _designationController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isSubmittedSuccess = false;
  String? _contactValidationError;
  String? _inlineError;

  @override
  void dispose() {
    _employeeIdController.dispose();
    _fullNameController.dispose();
    _departmentController.dispose();
    _designationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleFacultyRegister() async {
    setState(() {
      _contactValidationError = null;
      _inlineError = null;
    });

    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    // Client-side rule: At least one of email or phone_number must be filled
    if (email.isEmpty && phone.isEmpty) {
      setState(() {
        _contactValidationError =
            'Please provide at least one contact method (Email or Phone Number).';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    if (password != confirm) {
      setState(() => _inlineError = 'Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.registerFaculty(
        employeeId: _employeeIdController.text.trim(),
        fullName: _fullNameController.text.trim(),
        department: _departmentController.text.trim(),
        designation: _designationController.text.trim(),
        password: password,
        email: email.isNotEmpty ? email : null,
        phoneNumber: phone.isNotEmpty ? phone : null,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSubmittedSuccess = true;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _inlineError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _inlineError = 'Faculty registration submission failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Faculty Onboarding'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _isSubmittedSuccess
                  ? _buildSuccessView()
                  : _buildRegistrationForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Faculty Registry Onboarding',
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapV4,
          Text(
            'Join the academic and research community. Submissions are reviewed by administration.',
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
                  label: 'Employee / Faculty ID *',
                  hint: 'e.g. FAC-2023-089',
                  controller: _employeeIdController,
                  prefixIcon: Icons.badge_outlined,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Employee ID is required' : null,
                ),
                AppSpacing.gapV16,

                AppTextField(
                  label: 'Full Legal Name & Title *',
                  hint: 'e.g. Dr. Julian Hayes',
                  controller: _fullNameController,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Full Name is required' : null,
                ),
                AppSpacing.gapV16,

                AppTextField(
                  label: 'Academic Department *',
                  hint: 'e.g. Computer Science & Engineering',
                  controller: _departmentController,
                  prefixIcon: Icons.account_balance_outlined,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Department is required' : null,
                ),
                AppSpacing.gapV16,

                AppTextField(
                  label: 'Official Designation *',
                  hint: 'e.g. Associate Professor & Lab Lead',
                  controller: _designationController,
                  prefixIcon: Icons.work_outline_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Designation is required' : null,
                ),
                AppSpacing.gapV20,

                const Divider(),
                AppSpacing.gapV16,

                Text(
                  'Contact Information (Provide at least one)',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                AppSpacing.gapV12,

                AppTextField(
                  label: 'Faculty Email',
                  hint: 'professor@university.edu',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline_rounded,
                ),
                AppSpacing.gapV12,

                AppTextField(
                  label: 'Mobile Phone Number',
                  hint: '+1 (555) 019-2834',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_android_rounded,
                ),

                if (_contactValidationError != null) ...[
                  AppSpacing.gapV8,
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 16, color: AppColors.error),
                        AppSpacing.gapH8,
                        Expanded(
                          child: Text(
                            _contactValidationError!,
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
                ],
                AppSpacing.gapV20,

                const Divider(),
                AppSpacing.gapV16,

                AppTextField(
                  label: 'Account Password *',
                  hint: 'Min. 8 characters',
                  controller: _passwordController,
                  isPassword: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Password is required';
                    if (v.length < 8) return 'Password must be at least 8 characters';
                    return null;
                  },
                ),
                PasswordStrengthBar(password: _passwordController.text),
                AppSpacing.gapV16,

                AppTextField(
                  label: 'Confirm Password *',
                  hint: 'Re-enter password',
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
                  text: 'Submit Faculty Registration',
                  isLoading: _isLoading,
                  icon: Icons.send_rounded,
                  onPressed: _handleFacultyRegister,
                ),
              ],
            ),
          ),
          AppSpacing.gapV24,

          Center(
            child: TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Already have credentials? Sign In'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSpacing.gapV32,
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.goldLight,
              border: Border.all(color: AppColors.secondary, width: 2.0),
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

        Text(
          'Registration Submitted',
          style: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        AppSpacing.gapV8,
        Text(
          'Registration submitted — pending admin approval. You will receive access once institutional verification is finalized by the administration council.',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        AppSpacing.gapV32,

        PrimaryButton(
          text: 'Return to Sign In',
          icon: Icons.login_rounded,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
