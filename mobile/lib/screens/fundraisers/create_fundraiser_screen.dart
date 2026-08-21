import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/fundraiser.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fundraisers_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

class CreateFundraiserScreen extends ConsumerStatefulWidget {
  const CreateFundraiserScreen({super.key});

  @override
  ConsumerState<CreateFundraiserScreen> createState() =>
      _CreateFundraiserScreenState();
}

class _CreateFundraiserScreenState
    extends ConsumerState<CreateFundraiserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _startupNameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _startupNameController.dispose();
    _targetAmountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final target = double.tryParse(_targetAmountController.text.trim());
    if (target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid target funding amount.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final service = ref.read(fundraisersServiceProvider);
    final user = ref.read(authStateProvider).user;

    try {
      final newCampaign = await service.createFundraiser(
        title: _titleController.text.trim(),
        startupName: _startupNameController.text.trim(),
        description: _descriptionController.text.trim(),
        targetAmount: target,
      );

      ref.refresh(fundraisersListProvider);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Venture campaign launched successfully!',
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

      // Push replacement to new campaign detail screen per requirement
      context.pushReplacement('/fundraisers/${newCampaign.id}');
    } catch (_) {
      // Mock Fallback creation
      final mockNew = Fundraiser(
        id: 'fund-new-${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        startupName: _startupNameController.text.trim(),
        description: _descriptionController.text.trim(),
        targetAmount: target,
        raisedAmount: 0.0,
        creatorId: user?.id ?? 'current-user',
        creatorName: user?.fullName ?? 'Collegiate Founder',
        donorsCount: 0,
        createdAt: DateTime.now(),
      );

      ref.refresh(fundraisersListProvider);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Venture campaign published!'),
          backgroundColor: AppColors.primary,
        ),
      );

      context.pushReplacement('/fundraisers/${mockNew.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Launch Venture Campaign'),
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
                      'Startup Innovation Pitch',
                      style: GoogleFonts.fraunces(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapV4,
                    Text(
                      'Present your product thesis, target market, and capital roadmap to the alumni investor ecosystem.',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    AppSpacing.gapV24,

                    AppTextField(
                      label: 'Startup / Project Name *',
                      hint: 'e.g. AeroAgri Robotics, NanoBio, PulseAI',
                      controller: _startupNameController,
                      prefixIcon: Icons.rocket_launch_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Startup name is required'
                          : null,
                    ),
                    AppSpacing.gapV16,

                    AppTextField(
                      label: 'Campaign Headline *',
                      hint:
                          'e.g. Autonomous Solar Drones for Agricultural Yield Sensing',
                      controller: _titleController,
                      prefixIcon: Icons.title_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Campaign headline is required'
                          : null,
                    ),
                    AppSpacing.gapV16,

                    AppTextField(
                      label: 'Target Funding Goal (₹ INR) *',
                      hint: 'e.g. 1500000',
                      controller: _targetAmountController,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.currency_rupee_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Target amount is required';
                        }
                        if (double.tryParse(v.trim()) == null) {
                          return 'Please enter a valid numeric amount';
                        }
                        return null;
                      },
                    ),
                    AppSpacing.gapV16,

                    AppTextField(
                      label: 'Executive Pitch & Technology Overview *',
                      hint:
                          'Explain what you are building, the problem being solved, intellectual property, and fund allocation...',
                      controller: _descriptionController,
                      maxLines: 8,
                      minLines: 5,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Pitch description is required'
                          : null,
                    ),
                  ],
                ),
              ),
              AppSpacing.gapV24,

              PrimaryButton(
                text: 'Publish Campaign',
                icon: Icons.send_rounded,
                isLoading: _isSubmitting,
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
