import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

enum PasswordStrength {
  empty(0, '', Colors.transparent),
  weak(1, 'Weak', AppColors.error),
  fair(2, 'Fair', AppColors.warning),
  good(3, 'Good', AppColors.secondary),
  strong(4, 'Strong & Secure', AppColors.success);

  final int level;
  final String label;
  final Color color;

  const PasswordStrength(this.level, this.label, this.color);

  static PasswordStrength evaluate(String password) {
    if (password.isEmpty) return PasswordStrength.empty;

    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]')) && password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    if (password.length < 8) {
      return PasswordStrength.weak;
    }

    switch (score) {
      case 4:
        return PasswordStrength.strong;
      case 3:
        return PasswordStrength.good;
      case 2:
        return PasswordStrength.fair;
      case 1:
      default:
        return PasswordStrength.weak;
    }
  }
}

class PasswordStrengthBar extends StatelessWidget {
  final String password;

  const PasswordStrengthBar({
    super.key,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    final strength = PasswordStrength.evaluate(password);

    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSpacing.gapV8,
        Row(
          children: List.generate(4, (index) {
            final isFilled = index < strength.level;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 3 ? 6.0 : 0.0),
                decoration: BoxDecoration(
                  color: isFilled ? strength.color : AppColors.border,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            );
          }),
        ),
        AppSpacing.gapV6,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Strength: ${strength.label}',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: strength.color,
              ),
            ),
            if (password.length < 8)
              Text(
                'Min. 8 characters required',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
