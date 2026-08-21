import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

/// Dynamic Skill Chip Input Widget
///
/// Allows users to type custom skill names and press enter/comma or tap '+'
/// to create chips, and tap 'x' to remove chips.
class SkillChipInput extends StatefulWidget {
  final List<String> initialSkills;
  final ValueChanged<List<String>> onSkillsChanged;
  final String label;
  final String hint;

  const SkillChipInput({
    super.key,
    this.initialSkills = const [],
    required this.onSkillsChanged,
    this.label = 'Skills & Core Competencies',
    this.hint = 'Type skill (e.g. PyTorch, Distributed Systems) and tap +',
  });

  @override
  State<SkillChipInput> createState() => _SkillChipInputState();
}

class _SkillChipInputState extends State<SkillChipInput> {
  late List<String> _skills;
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _skills = List<String>.from(widget.initialSkills);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _addSkill() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Support comma-separated items
    final splits = text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);

    setState(() {
      for (final s in splits) {
        if (!_skills.any((item) => item.toLowerCase() == s.toLowerCase())) {
          _skills.add(s);
        }
      }
      _textController.clear();
    });

    widget.onSkillsChanged(_skills);
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.removeWhere((item) => item.toLowerCase() == skill.toLowerCase());
    });
    widget.onSkillsChanged(_skills);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.ibmPlexSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        AppSpacing.gapV8,

        // Input Field with Add Button
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                onSubmitted: (_) => _addSkill(),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  prefixIcon: const Icon(
                    Icons.psychology_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
            ),
            AppSpacing.gapH8,
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              ),
              child: IconButton(
                icon: const Icon(Icons.add_rounded, color: AppColors.secondary),
                onPressed: _addSkill,
              ),
            ),
          ],
        ),

        // Display Added Skill Chips
        if (_skills.isNotEmpty) ...[
          AppSpacing.gapV12,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skills.map((skill) {
              return Chip(
                label: Text(
                  skill,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
                deleteIcon: const Icon(Icons.close_rounded, size: 14),
                deleteIconColor: AppColors.textSecondary,
                onDeleted: () => _removeSkill(skill),
                backgroundColor: AppColors.goldLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  side: BorderSide(
                    color: AppColors.secondary.withOpacity(0.5),
                    width: 0.8,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
