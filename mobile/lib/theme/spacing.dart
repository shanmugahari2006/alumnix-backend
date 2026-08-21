import 'package:flutter/material.dart';

/// Convocation Design System Spacing Scale
class AppSpacing {
  AppSpacing._();

  // Numerical Spacing Scale
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // Border Radii
  static const double radiusXs = 3.0; // Buttons & interactive chips
  static const double radiusSm = 4.0; // Cards (sharp hairline aesthetic)
  static const double radiusMd = 8.0; // Modals & Dialogs
  static const double radiusLg = 12.0;
  static const double radiusFull = 999.0; // Badges, Medallions, Avatars

  // Common Insets
  static const EdgeInsets pagePadding = EdgeInsets.all(md);
  static const EdgeInsets pagePaddingHorizontal = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets cardPaddingDense = EdgeInsets.all(sm);
  static const EdgeInsets modalPadding = EdgeInsets.all(lg);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: lg, vertical: 12.0);
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(horizontal: md, vertical: 14.0);

  // Common Gap Helpers
  static const SizedBox gapH4 = SizedBox(width: xs);
  static const SizedBox gapH6 = SizedBox(width: 6.0);
  static const SizedBox gapH8 = SizedBox(width: sm);
  static const SizedBox gapH10 = SizedBox(width: 10.0);
  static const SizedBox gapH12 = SizedBox(width: 12.0);
  static const SizedBox gapH16 = SizedBox(width: md);
  static const SizedBox gapH24 = SizedBox(width: lg);
  static const SizedBox gapH32 = SizedBox(width: xl);

  static const SizedBox gapV2 = SizedBox(height: xxs);
  static const SizedBox gapV4 = SizedBox(height: xs);
  static const SizedBox gapV6 = SizedBox(height: 6.0);
  static const SizedBox gapV8 = SizedBox(height: sm);
  static const SizedBox gapV10 = SizedBox(height: 10.0);
  static const SizedBox gapV12 = SizedBox(height: 12.0);
  static const SizedBox gapV14 = SizedBox(height: 14.0);
  static const SizedBox gapV16 = SizedBox(height: md);
  static const SizedBox gapV20 = SizedBox(height: 20.0);
  static const SizedBox gapV24 = SizedBox(height: lg);
  static const SizedBox gapV32 = SizedBox(height: xl);
  static const SizedBox gapV48 = SizedBox(height: xxl);
}
