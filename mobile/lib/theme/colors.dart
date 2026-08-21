import 'package:flutter/material.dart';

/// Convocation Design System Colors
class AppColors {
  AppColors._();

  // Core Palette
  static const Color primary = Color(0xFF1B2A4A); // Deep ink navy
  static const Color secondary = Color(0xFFC9A15C); // Warm gold
  static const Color accent = Color(0xFFC9A15C); // Warm gold alias
  static const Color background = Color(0xFFF7F5F0); // Off-white paper
  static const Color surface = Color(0xFFFFFFFF); // Clean white card surface
  
  // Text Colors
  static const Color textPrimary = Color(0xFF22283A); // Dark charcoal navy
  static const Color textSecondary = Color(0xFF5B6472); // Muted slate gray
  static const Color textLight = Color(0xFF8C95A6); // Subtle helper text
  
  // Semantic State Colors
  static const Color success = Color(0xFF2F5D4E); // Forest green ("approved", "verified")
  static const Color successBg = Color(0xFFEAF3EF); // Soft green tint
  static const Color error = Color(0xFFB3403A); // Muted crimson red
  static const Color errorBg = Color(0xFFFBEBEA); // Soft error tint
  static const Color warning = Color(0xFFD97706); // Warm amber
  static const Color warningBg = Color(0xFFFEF3C7); // Soft amber tint
  static const Color info = Color(0xFF1D4ED8); // Royal blue
  static const Color infoBg = Color(0xFFEFF6FF); // Soft blue tint
  
  // Accents & Borders
  static const Color border = Color(0xFFE3DFD3); // Hairline warm beige border
  static const Color divider = Color(0xFFE3DFD3);
  static const Color goldLight = Color(0xFFFAF4E8); // Gold parchment background
  static const Color goldDark = Color(0xFF9E7835); // Deep metallic gold
  static const Color navyLight = Color(0xFF283D6A); // Slightly lighter navy for hover/active
  static const Color cardShadow = Color(0x081B2A4A); // Subtle navy ambient shadow
}
