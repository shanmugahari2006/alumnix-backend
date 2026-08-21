import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/alumni_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/secondary_button.dart';

/// Directory Filtering BottomSheet Modal
class DirectoryFilterModal extends ConsumerStatefulWidget {
  const DirectoryFilterModal({super.key});

  @override
  ConsumerState<DirectoryFilterModal> createState() =>
      _DirectoryFilterModalState();
}

class _DirectoryFilterModalState extends ConsumerState<DirectoryFilterModal> {
  late String? _selectedBranch;
  late RangeValues _yearRange;
  late TextEditingController _locationController;
  late List<String> _selectedSkills;

  static const double _minYear = 2005.0;
  static const double _maxYear = 2026.0;

  final List<String> _branchOptions = [
    'All',
    'Computer Science',
    'Information Science',
    'Electrical Engineering',
    'Biotechnology',
    'Economics & Computing',
    'Product Design',
    'Mechanical Engineering',
  ];

  final List<String> _popularSkills = [
    'Machine Learning',
    'Distributed Systems',
    'Cloud Computing',
    'VLSI Design',
    'Quantum Computing',
    'CRISPR',
    'Quantitative Finance',
    'Product Design',
    'Kubernetes',
    'FinTech',
    'Bioinformatics',
    'Robotics',
  ];

  @override
  void initState() {
    super.initState();
    final filter = ref.read(directoryFilterProvider);
    _selectedBranch = filter.branch ?? 'All';
    _yearRange = RangeValues(
      filter.startYear.clamp(_minYear, _maxYear),
      filter.endYear.clamp(_minYear, _maxYear),
    );
    _locationController = TextEditingController(text: filter.location ?? '');
    _selectedSkills = List<String>.from(filter.selectedSkills);
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _toggleSkill(String skill) {
    setState(() {
      if (_selectedSkills.contains(skill)) {
        _selectedSkills.remove(skill);
      } else {
        _selectedSkills.add(skill);
      }
    });
  }

  void _reset() {
    setState(() {
      _selectedBranch = 'All';
      _yearRange = const RangeValues(_minYear, _maxYear);
      _locationController.clear();
      _selectedSkills.clear();
    });
  }

  void _apply() {
    ref.read(directoryFilterProvider.notifier).updateFilters(
          branch: _selectedBranch == 'All' ? null : _selectedBranch,
          startYear: _yearRange.start,
          endYear: _yearRange.end,
          location: _locationController.text.trim().isNotEmpty
              ? _locationController.text.trim()
              : null,
          selectedSkills: _selectedSkills,
        );

    // Trigger fresh load in directory notifier
    ref.read(alumniDirectoryNotifierProvider.notifier).loadInitial(refresh: true);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusMd),
        ),
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 16.0, 16.0, 12.0),
            child: Row(
              children: [
                const Icon(
                  Icons.tune_rounded,
                  color: AppColors.secondary,
                  size: 22,
                ),
                AppSpacing.gapH12,
                Text(
                  'Directory Filters',
                  style: GoogleFonts.fraunces(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),

          // Scrollable Filter Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Academic Branch Dropdown
                  Text(
                    'Academic Department / Branch',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapV8,
                  DropdownButtonFormField<String>(
                    value: _selectedBranch,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.school_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    items: _branchOptions.map((branch) {
                      return DropdownMenuItem(
                        value: branch,
                        child: Text(
                          branch,
                          style: GoogleFonts.ibmPlexSans(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedBranch = val),
                  ),
                  AppSpacing.gapV24,

                  // 2. Graduation Year Range Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Graduation Year Range',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        "${_yearRange.start.toInt()} – ${_yearRange.end.toInt()}",
                        style: GoogleFonts.fraunces(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapV4,
                  RangeSlider(
                    values: _yearRange,
                    min: _minYear,
                    max: _maxYear,
                    divisions: (_maxYear - _minYear).toInt(),
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.border,
                    labels: RangeLabels(
                      _yearRange.start.toInt().toString(),
                      _yearRange.end.toInt().toString(),
                    ),
                    onChanged: (values) => setState(() => _yearRange = values),
                  ),
                  AppSpacing.gapV20,

                  // 3. Location Text Field
                  AppTextField(
                    label: 'Geographic Location',
                    hint: 'e.g. San Francisco, Boston, London, Remote',
                    controller: _locationController,
                    prefixIcon: Icons.location_on_outlined,
                  ),
                  AppSpacing.gapV24,

                  // 4. Skills Multi-Select Chips
                  Text(
                    'Skills & Specializations',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapV4,
                  Text(
                    'Tap chips to filter alumni by domain expertise',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppSpacing.gapV12,

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _popularSkills.map((skill) {
                      final isSelected = _selectedSkills.contains(skill);
                      return FilterChip(
                        label: Text(skill),
                        selected: isSelected,
                        onSelected: (_) => _toggleSkill(skill),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.background,
                        checkmarkColor: Colors.white,
                        labelStyle: GoogleFonts.ibmPlexSans(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1.0),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    text: 'Reset Filters',
                    onPressed: _reset,
                  ),
                ),
                AppSpacing.gapH12,
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    text: 'Apply Filters',
                    icon: Icons.check_rounded,
                    onPressed: _apply,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
