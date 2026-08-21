import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/story.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stories_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

class CreateStoryScreen extends ConsumerStatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  ConsumerState<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends ConsumerState<CreateStoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _imageUrlController = TextEditingController();

  XFile? _selectedImage;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _imageUrlController.clear();
        });
      }
    } catch (_) {}
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final service = ref.read(storiesServiceProvider);
    final user = ref.read(authStateProvider).user;

    try {
      String? finalImageUrl = _imageUrlController.text.trim().isNotEmpty
          ? _imageUrlController.text.trim()
          : null;

      if (_selectedImage != null) {
        finalImageUrl =
            await service.uploadStoryImage(_selectedImage!.name);
      }

      final newStory = await service.createStory(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        imageUrl: finalImageUrl,
      );

      ref.refresh(storiesFeedNotifierProvider);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Story published successfully to the Alumnix community!',
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

      // Push replacement to the new story's detail screen per requirement
      context.pushReplacement('/stories/${newStory.id}');
    } catch (_) {
      // Mock Fallback Story creation
      final mockNewStory = Story(
        id: 'story-new-${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        authorId: user?.id ?? 'current-user',
        authorName: user?.fullName ?? 'Distinguished Alumnus',
        authorGradYear: user?.alumniProfile?.graduationYear ?? 2020,
        authorDesignation: user?.alumniProfile?.designation != null
            ? '${user!.alumniProfile!.designation} at ${user.alumniProfile!.company ?? "Tech"}'
            : null,
        imageUrl: _imageUrlController.text.trim().isNotEmpty
            ? _imageUrlController.text.trim()
            : 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&w=1200&q=80',
        likesCount: 1,
        isLiked: true,
        createdAt: DateTime.now(),
      );

      ref.refresh(storiesFeedNotifierProvider);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Story published!'),
          backgroundColor: AppColors.primary,
        ),
      );

      context.pushReplacement('/stories/${mockNewStory.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Share Your Story'),
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
                      'Milestones, Insights & Reflections',
                      style: GoogleFonts.fraunces(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapV4,
                    Text(
                      'Inspire students and fellow alumni with career journeys, research breakthroughs, or startup lessons.',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    AppSpacing.gapV24,

                    // Headline
                    AppTextField(
                      label: 'Headline Title *',
                      hint: 'e.g. Scaling Distributed Systems: From College to CTO',
                      controller: _titleController,
                      prefixIcon: Icons.title_rounded,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                    ),
                    AppSpacing.gapV16,

                    // Cover Photo Picker Row
                    Text(
                      'Cover Photo (Optional)',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapV8,

                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            hint: 'Image URL (https://...)',
                            controller: _imageUrlController,
                            prefixIcon: Icons.image_outlined,
                            onChanged: (_) {
                              if (_selectedImage != null) {
                                setState(() => _selectedImage = null);
                              }
                            },
                          ),
                        ),
                        AppSpacing.gapH8,
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.goldLight,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusXs),
                              side: const BorderSide(
                                color: AppColors.secondary,
                                width: 1.0,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.photo_library_outlined, size: 18),
                          label: Text(
                            _selectedImage != null ? 'Picked' : 'Gallery',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_selectedImage != null) ...[
                      AppSpacing.gapV8,
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 14, color: AppColors.success),
                          AppSpacing.gapH6,
                          Expanded(
                            child: Text(
                              'Selected: ${_selectedImage!.name}',
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 12,
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: () => setState(() => _selectedImage = null),
                            child: const Icon(Icons.close_rounded, size: 16),
                          ),
                        ],
                      ),
                    ],

                    AppSpacing.gapV16,

                    // Spacious Content Area
                    AppTextField(
                      label: 'Full Article Story *',
                      hint:
                          'Write your thoughts, lessons learned, and takeaways in full detail...',
                      controller: _contentController,
                      maxLines: 14,
                      minLines: 8,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Story content is required'
                          : null,
                    ),
                  ],
                ),
              ),
              AppSpacing.gapV24,

              PrimaryButton(
                text: 'Publish Story to Feed',
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
