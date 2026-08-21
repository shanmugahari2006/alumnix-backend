import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/job.dart';
import '../../../providers/jobs_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/primary_button.dart';

class ApplyJobSheet extends ConsumerStatefulWidget {
  final Job job;
  final VoidCallback onAppliedSuccess;

  const ApplyJobSheet({
    super.key,
    required this.job,
    required this.onAppliedSuccess,
  });

  @override
  ConsumerState<ApplyJobSheet> createState() => _ApplyJobSheetState();
}

class _ApplyJobSheetState extends ConsumerState<ApplyJobSheet> {
  final _coverNoteController = TextEditingController();
  PlatformFile? _selectedFile;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _coverNoteController.dispose();
    super.dispose();
  }

  Future<void> _pickResumeFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          _errorMessage = null;
        });
      }
    } catch (_) {
      setState(() {
        _errorMessage = 'Unable to pick file. Please try again.';
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  Future<void> _handleSubmit() async {
    if (_selectedFile == null) {
      setState(() {
        _errorMessage = 'Please attach your resume (PDF document).';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final jobsService = ref.read(jobsServiceProvider);

    try {
      // 1. Upload resume to storage and obtain public/secure URL
      final resumeUrl =
          await jobsService.uploadResume(_selectedFile!.name);

      // 2. Submit application to backend
      await jobsService.applyForJob(
        jobId: widget.job.id,
        resumeUrl: resumeUrl,
        coverNote: _coverNoteController.text.trim().isNotEmpty
            ? _coverNoteController.text.trim()
            : null,
      );

      // 3. Mark applied in Riverpod state
      ref.read(appliedJobsProvider.notifier).markApplied(widget.job.id);

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      Navigator.pop(context);

      widget.onAppliedSuccess();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.secondary, size: 20),
              AppSpacing.gapH8,
              Expanded(
                child: Text(
                  'Application submitted successfully for ${widget.job.title}!',
                  style: GoogleFonts.ibmPlexSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            side: const BorderSide(color: AppColors.secondary, width: 1.0),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Failed to submit application. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 20.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusMd),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Submit Application',
                        style: GoogleFonts.fraunces(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      AppSpacing.gapV2,
                      Text(
                        'Applying to ${widget.job.title} at ${widget.job.company}',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            AppSpacing.gapV16,
            const Divider(),
            AppSpacing.gapV16,

            // Resume File Upload Section
            Text(
              'Resume / Curriculum Vitae (PDF) *',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            AppSpacing.gapV8,

            InkWell(
              onTap: _isSubmitting ? null : _pickResumeFile,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: _selectedFile != null
                      ? AppColors.goldLight.withOpacity(0.4)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  border: Border.all(
                    color: _selectedFile != null
                        ? AppColors.secondary
                        : AppColors.border,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXs),
                        border: Border.all(
                          color: AppColors.border,
                          width: 0.8,
                        ),
                      ),
                      child: Icon(
                        _selectedFile != null
                            ? Icons.picture_as_pdf_rounded
                            : Icons.upload_file_rounded,
                        color: _selectedFile != null
                            ? AppColors.error
                            : AppColors.primary,
                        size: 24,
                      ),
                    ),
                    AppSpacing.gapH12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedFile != null
                                ? _selectedFile!.name
                                : 'Select PDF Resume',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          AppSpacing.gapV2,
                          Text(
                            _selectedFile != null
                                ? _formatFileSize(_selectedFile!.size)
                                : 'PDF documents up to 10MB',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _selectedFile != null ? 'Change' : 'Browse',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapV16,

            // Optional Cover Note
            AppTextField(
              label: 'Cover Note (Optional)',
              hint:
                  'Briefly share why you are interested in this opportunity...',
              controller: _coverNoteController,
              maxLines: 4,
              minLines: 2,
            ),

            if (_errorMessage != null) ...[
              AppSpacing.gapV12,
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 16, color: AppColors.error),
                  AppSpacing.gapH6,
                  Expanded(
                    child: Text(
                      _errorMessage!,
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

            // Submit Button
            PrimaryButton(
              text: 'Submit Application',
              icon: Icons.send_rounded,
              isLoading: _isSubmitting,
              onPressed: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
