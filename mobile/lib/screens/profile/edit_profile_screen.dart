import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/alumni_profile.dart';
import '../../providers/alumni_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/skill_chip_input.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _companyController;
  late TextEditingController _designationController;
  late TextEditingController _locationController;
  late TextEditingController _linkedinController;
  late List<String> _skills;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).user;
    final alumniProfile = user?.alumniProfile;

    _companyController = TextEditingController(text: alumniProfile?.company ?? '');
    _designationController =
        TextEditingController(text: alumniProfile?.designation ?? '');
    _locationController =
        TextEditingController(text: alumniProfile?.location ?? '');
    _linkedinController =
        TextEditingController(text: alumniProfile?.linkedinUrl ?? '');
    _skills = List<String>.from(alumniProfile?.skills ?? []);
  }

  @override
  void dispose() {
    _companyController.dispose();
    _designationController.dispose();
    _locationController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final service = ref.read(alumniServiceProvider);

    try {
      final updatedProfile = await service.updateProfile(
        company: _companyController.text.trim(),
        designation: _designationController.text.trim(),
        location: _locationController.text.trim(),
        linkedinUrl: _linkedinController.text.trim(),
        skills: _skills,
      );

      // Refresh auth profile
      final currentUser = ref.read(authStateProvider).user;
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(
          alumniProfile: updatedProfile,
        );
        ref.read(secureStorageProvider).saveUser(updatedUser);
      }

      // Trigger directory refresh
      ref.read(alumniDirectoryNotifierProvider.notifier).loadInitial(refresh: true);

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile attributes updated successfully!',
            style: GoogleFonts.ibmPlexSans(
              color: AppColors.secondary,
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

      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update profile. Please try again.',
            style: GoogleFonts.ibmPlexSans(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Alumni Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Professional Identity',
                      style: GoogleFonts.fraunces(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapV4,
                    Text(
                      'Keep your organization, role, and skills current for student and peer networking.',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    AppSpacing.gapV24,

                    AppTextField(
                      label: 'Current Company / Venture',
                      hint: 'e.g. Anthropic AI, Palantir, Apple',
                      controller: _companyController,
                      prefixIcon: Icons.business_rounded,
                    ),
                    AppSpacing.gapV16,

                    AppTextField(
                      label: 'Official Designation',
                      hint: 'e.g. Senior Machine Learning Engineer',
                      controller: _designationController,
                      prefixIcon: Icons.work_outline_rounded,
                    ),
                    AppSpacing.gapV16,

                    AppTextField(
                      label: 'Current Geographic Location',
                      hint: 'e.g. San Francisco, CA or London, UK',
                      controller: _locationController,
                      prefixIcon: Icons.location_on_outlined,
                    ),
                    AppSpacing.gapV16,

                    AppTextField(
                      label: 'LinkedIn Profile URL',
                      hint: 'https://linkedin.com/in/username',
                      controller: _linkedinController,
                      keyboardType: TextInputType.url,
                      prefixIcon: Icons.link_rounded,
                    ),
                    AppSpacing.gapV20,

                    const Divider(),
                    AppSpacing.gapV16,

                    // Interactive Skill Chip Input
                    SkillChipInput(
                      initialSkills: _skills,
                      onSkillsChanged: (skills) {
                        _skills = skills;
                      },
                    ),
                  ],
                ),
              ),
              AppSpacing.gapV24,

              PrimaryButton(
                text: 'Save & Update Profile',
                icon: Icons.save_outlined,
                isLoading: _isSaving,
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
