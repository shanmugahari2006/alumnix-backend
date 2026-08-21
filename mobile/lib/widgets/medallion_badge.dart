import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';

/// Signature "Medallion" Badge
///
/// A circular outlined avatar-adjacent badge (44x44, 2px gold border,
/// Fraunces serif typography rendering graduation year formatted e.g. "'21").
/// Used throughout directory cards, profile headers, and list views.
class MedallionBadge extends StatelessWidget {
  final String? year;
  final double size;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool showApostrophe;
  final Color? borderColor;
  final Color? backgroundColor;
  final Color? textColor;

  const MedallionBadge({
    super.key,
    required this.year,
    this.size = 44.0,
    this.onTap,
    this.tooltip,
    this.showApostrophe = true,
    this.borderColor,
    this.backgroundColor,
    this.textColor,
  });

  /// Factory for full 4-digit year format (e.g. 2021 -> '21)
  factory MedallionBadge.fromGradYear(
    int? gradYear, {
    Key? key,
    double size = 44.0,
    VoidCallback? onTap,
    String? tooltip,
  }) {
    if (gradYear == null || gradYear <= 0) {
      return MedallionBadge(
        key: key,
        year: '--',
        size: size,
        onTap: onTap,
        tooltip: tooltip,
        showApostrophe: false,
      );
    }
    final yearStr = gradYear.toString();
    final shortYear = yearStr.length >= 2 ? yearStr.substring(yearStr.length - 2) : yearStr;
    return MedallionBadge(
      key: key,
      year: shortYear,
      size: size,
      onTap: onTap,
      tooltip: tooltip ?? 'Class of $gradYear',
      showApostrophe: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayText = (year == null || year!.isEmpty)
        ? '--'
        : (showApostrophe && !year!.startsWith("'") && year != '--' ? "'$year" : year!);

    final effectiveBorder = borderColor ?? AppColors.secondary;
    final effectiveBg = backgroundColor ?? AppColors.goldLight;
    final effectiveText = textColor ?? AppColors.primary;

    Widget medallion = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: effectiveBg,
        border: Border.all(
          color: effectiveBorder,
          width: 2.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x101B2A4A),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          displayText,
          style: GoogleFonts.fraunces(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
            color: effectiveText,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );

    if (tooltip != null) {
      medallion = Tooltip(
        message: tooltip!,
        child: medallion,
      );
    }

    if (onTap != null) {
      medallion = GestureDetector(
        onTap: onTap,
        child: medallion,
      );
    }

    return medallion;
  }
}
