import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

enum StatusPillType {
  success, // Verified, Approved (Forest green #2F5D4E)
  warning, // Pending, Review (Warm gold/amber)
  error,   // Rejected, Closed (Muted crimson)
  info,    // General info (Royal blue)
  neutral, // Role tags, categories (Ink navy)
}

/// Convocation Status & Verification Pill
///
/// Designed with subtle tinted backgrounds and contrasting serif/sans typography.
class StatusPill extends StatelessWidget {
  final String label;
  final StatusPillType type;
  final IconData? icon;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const StatusPill({
    super.key,
    required this.label,
    this.type = StatusPillType.neutral,
    this.icon,
    this.fontSize = 11.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
  });

  /// Factory for "Verified" / "Approved" badge
  factory StatusPill.verified({String label = 'Verified', Key? key}) {
    return StatusPill(
      key: key,
      label: label,
      type: StatusPillType.success,
      icon: Icons.check_circle_rounded,
    );
  }

  /// Factory for "Pending Approval" badge
  factory StatusPill.pending({String label = 'Pending Approval', Key? key}) {
    return StatusPill(
      key: key,
      label: label,
      type: StatusPillType.warning,
      icon: Icons.schedule_rounded,
    );
  }

  /// Factory for User Role badge (Student, Alumni, Faculty, Admin)
  factory StatusPill.role(String role, {Key? key}) {
    return StatusPill(
      key: key,
      label: role.toUpperCase(),
      type: StatusPillType.neutral,
      icon: Icons.school_outlined,
    );
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;

    switch (type) {
      case StatusPillType.success:
        bg = AppColors.successBg;
        fg = AppColors.success;
        border = AppColors.success.withOpacity(0.3);
        break;
      case StatusPillType.warning:
        bg = AppColors.warningBg;
        fg = const Color(0xFF92400E);
        border = AppColors.warning.withOpacity(0.4);
        break;
      case StatusPillType.error:
        bg = AppColors.errorBg;
        fg = AppColors.error;
        border = AppColors.error.withOpacity(0.3);
        break;
      case StatusPillType.info:
        bg = AppColors.infoBg;
        fg = AppColors.info;
        border = AppColors.info.withOpacity(0.3);
        break;
      case StatusPillType.neutral:
        bg = AppColors.goldLight;
        fg = AppColors.primary;
        border = AppColors.secondary.withOpacity(0.4);
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        border: Border.all(
          color: border,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 1, color: fg),
            const SizedBox(width: 4.0),
          ],
          Text(
            label,
            style: GoogleFonts.ibmPlexSans(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
