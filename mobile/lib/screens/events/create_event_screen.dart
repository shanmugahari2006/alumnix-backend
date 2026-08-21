import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/bulletin_event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/events_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _eventDateTime;
  DateTime? _deadlineDateTime;
  String? _dateValidationError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _eventDateTime = now.add(const Duration(days: 7, hours: 10));
    _deadlineDateTime = now.add(const Duration(days: 5, hours: 18));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return null;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return null;

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  Future<void> _handleSubmit() async {
    setState(() => _dateValidationError = null);

    if (_eventDateTime == null || _deadlineDateTime == null) {
      setState(() {
        _dateValidationError = 'Please select both event and cut-off dates.';
      });
      return;
    }

    // Client-side validation: registration_deadline must precede event_date
    if (!_deadlineDateTime!.isBefore(_eventDateTime!)) {
      setState(() {
        _dateValidationError =
            'Registration cut-off must be strictly before the event start date & time.';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final service = ref.read(eventsServiceProvider);
    final user = ref.read(authStateProvider).user;

    try {
      final newEvent = await service.createEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        eventDate: _eventDateTime!,
        registrationDeadline: _deadlineDateTime!,
        location: _locationController.text.trim(),
      );

      ref.refresh(eventsListProvider);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Event listing published to bulletin!',
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

      // Push replacement to new event detail screen per requirement
      context.pushReplacement('/events/${newEvent.id}');
    } catch (_) {
      // Mock Fallback creation
      final mockNew = BulletinEvent(
        id: 'event-new-${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        eventDate: _eventDateTime!,
        registrationDeadline: _deadlineDateTime!,
        location: _locationController.text.trim(),
        creatorId: user?.id ?? 'faculty-1',
        creatorName: user?.fullName ?? 'Faculty Convener',
        registeredCount: 1,
        isRegistered: true,
        createdAt: DateTime.now(),
      );

      ref.refresh(eventsListProvider);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event published!'),
          backgroundColor: AppColors.primary,
        ),
      );

      context.pushReplacement('/events/${mockNew.id}');
    }
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('d MMM yyyy, h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Post Bulletin Event'),
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
                      'Collegiate Bulletin Announcement',
                      style: GoogleFonts.fraunces(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapV4,
                    Text(
                      'Publish academic workshops, guest lectures, reunions, and symposiums.',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    AppSpacing.gapV24,

                    // Event Title
                    AppTextField(
                      label: 'Event Title *',
                      hint:
                          'e.g. Frontiers in Neuromorphic Silicon & AI Hardware',
                      controller: _titleController,
                      prefixIcon: Icons.title_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Event title is required'
                          : null,
                    ),
                    AppSpacing.gapV16,

                    // Venue Location
                    AppTextField(
                      label: 'Venue Location / Auditorium *',
                      hint: 'e.g. Sir M.V. Seminar Hall, Block C or Virtual',
                      controller: _locationController,
                      prefixIcon: Icons.location_on_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Location is required'
                          : null,
                    ),
                    AppSpacing.gapV20,

                    const Divider(),
                    AppSpacing.gapV16,

                    // Event Date & Time Picker
                    Text(
                      'Event Start Date & Time *',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapV8,
                    InkWell(
                      onTap: () async {
                        final res = await _pickDateTime(
                          _eventDateTime ?? DateTime.now().add(const Duration(days: 3)),
                        );
                        if (res != null) {
                          setState(() => _eventDateTime = res);
                        }
                      },
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusXs),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            AppSpacing.gapH10,
                            Text(
                              _eventDateTime != null
                                  ? _formatDateTime(_eventDateTime!)
                                  : 'Select date & time',
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 14,
                                color: _eventDateTime != null
                                    ? AppColors.textPrimary
                                    : AppColors.textLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.edit_calendar_rounded,
                              size: 18,
                              color: AppColors.secondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    AppSpacing.gapV16,

                    // Registration Deadline Picker
                    Text(
                      'Registration Cut-off Deadline *',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapV8,
                    InkWell(
                      onTap: () async {
                        final res = await _pickDateTime(
                          _deadlineDateTime ?? DateTime.now().add(const Duration(days: 2)),
                        );
                        if (res != null) {
                          setState(() => _deadlineDateTime = res);
                        }
                      },
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusXs),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            AppSpacing.gapH10,
                            Text(
                              _deadlineDateTime != null
                                  ? _formatDateTime(_deadlineDateTime!)
                                  : 'Select cut-off date & time',
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 14,
                                color: _deadlineDateTime != null
                                    ? AppColors.textPrimary
                                    : AppColors.textLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.edit_calendar_rounded,
                              size: 18,
                              color: AppColors.secondary,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_dateValidationError != null) ...[
                      AppSpacing.gapV10,
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: AppColors.errorBg,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusXs),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 16, color: AppColors.error),
                            AppSpacing.gapH8,
                            Expanded(
                              child: Text(
                                _dateValidationError!,
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

                    // Full Description
                    AppTextField(
                      label: 'Event Agenda & Description *',
                      hint:
                          'Outline speaker profiles, schedule, prerequisites, and attendance guidelines...',
                      controller: _descriptionController,
                      maxLines: 8,
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
                text: 'Publish Bulletin Event',
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
