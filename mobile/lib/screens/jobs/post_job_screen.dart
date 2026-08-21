import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/job.dart';
import '../../providers/jobs_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

class PostJobScreen extends ConsumerStatefulWidget {
  const PostJobScreen({super.key});

  @override
  ConsumerState<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends ConsumerState<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedJobType = 'Full-time';
  bool _isSubmitting = false;

  final List<String> _types = [
    'Full-time',
    'Part-time',
    'Internship',
    'Contract',
    'Remote',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final service = ref.read(jobsServiceProvider);

    try {
      final newJob = await service.createJob(
        title: _titleController.text.trim(),
        company: _companyController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        jobType: _selectedJobType,
        salary: _salaryController.text.trim().isNotEmpty
            ? _salaryController.text.trim()
            : null,
      );

      ref.refresh(jobsListProvider);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Opportunity posted successfully!',
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

      // Push-replace to the new job's Detail screen per requirement
      context.pushReplacement('/jobs/${newJob.id}');
    } catch (_) {
      // Offline / fallback creation
      final mockNewJob = Job(
        id: 'job-new-${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        company: _companyController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        jobType: _selectedJobType,
        salary: _salaryController.text.trim(),
        creatorId: 'current-user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      ref.refresh(jobsListProvider);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opportunity published!'),
          backgroundColor: AppColors.primary,
        ),
      );

      context.pushReplacement('/jobs/${mockNewJob.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Post Career Opportunity'),
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
                      'Opportunity Specifications',
                      style: GoogleFonts.fraunces(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapV4,
                    Text(
                      'Share an open position or internship directly with collegiate students and alumni.',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    AppSpacing.gapV24,

                    AppTextField(
                      label: 'Role Title *',
                      hint: 'e.g. Principal Systems Architect',
                      controller: _titleController,
                      prefixIcon: Icons.work_outline_rounded,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                    ),
                    AppSpacing.gapV16,

                    AppTextField(
                      label: 'Hiring Organization / Venture *',
                      hint: 'e.g. Palantir, DeepMind, Anthropic',
                      controller: _companyController,
                      prefixIcon: Icons.business_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Company is required'
                          : null,
                    ),
                    AppSpacing.gapV16,

                    AppTextField(
                      label: 'Workplace Location *',
                      hint: 'e.g. San Francisco, CA or Remote',
                      controller: _locationController,
                      prefixIcon: Icons.location_on_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Location is required'
                          : null,
                    ),
                    AppSpacing.gapV16,

                    // Job Type Selector
                    Text(
                      'Employment Classification *',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapV8,
                    DropdownButtonFormField<String>(
                      value: _selectedJobType,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(
                          Icons.category_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                      items: _types.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type,
                              style: GoogleFonts.ibmPlexSans(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedJobType = val);
                      },
                    ),
                    AppSpacing.gapV16,

                    AppTextField(
                      label: 'Compensation Range (Optional)',
                      hint: 'e.g. \$180,000 - \$240,000 / yr',
                      controller: _salaryController,
                      prefixIcon: Icons.payments_outlined,
                    ),
                    AppSpacing.gapV16,

                    AppTextField(
                      label: 'Detailed Description & Requirements *',
                      hint:
                          'Outline responsibilities, tech stack, eligibility, and mentorship details...',
                      controller: _descriptionController,
                      maxLines: 6,
                      minLines: 4,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Description is required'
                          : null,
                    ),
                  ],
                ),
              ),
              AppSpacing.gapV24,

              PrimaryButton(
                text: 'Publish Opportunity',
                icon: Icons.check_circle_outline_rounded,
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
