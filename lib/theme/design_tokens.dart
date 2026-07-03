import 'package:flutter/material.dart';

/// Shared spacing, radii, motion, and typography scale for RenewWise 1.0.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const page = 20.0;
  static const section = 28.0;
  static const divider = 32.0;
}

abstract final class AppRadius {
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const card = 24.0;
  static const homeCard = 28.0;
  static const pill = 999.0;

  static BorderRadius get cardBorder => BorderRadius.circular(card);
  static BorderRadius get buttonBorder => BorderRadius.circular(md);
  static BorderRadius get inputBorder => BorderRadius.circular(md);
  static BorderRadius get dialogBorder => BorderRadius.circular(lg);
}

abstract final class AppMotion {
  static const duration = Duration(milliseconds: 280);
  static const curve = Curves.easeOutCubic;
  static const snackDuration = Duration(seconds: 2);
  static const cardSlide = 12.0;
}

abstract final class AppIconSize {
  static const sm = 20.0;
  static const md = 24.0;
  static const lg = 36.0;
  static const empty = 72.0;
}

abstract final class AppTypography {
  static const appTitleSize = 28.0;
  static const screenTitleSize = 20.0;
  static const sectionTitleSize = 16.0;
  static const cardTitleSize = 15.0;
  static const bodySize = 16.0;
  static const captionSize = 14.0;
  static const buttonSize = 16.0;
}
