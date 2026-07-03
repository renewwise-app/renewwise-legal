import 'package:flutter/material.dart';

/// Available brand colour palettes for RenewWise.
enum AppBrandVariant {
  green,
  blue,
}

/// Central brand colour registry.
///
/// [active] defaults to [AppBrandVariant.green] — the RenewWise brand theme.
/// Set to [AppBrandVariant.blue] to run the blue theme experiment.
abstract final class BrandTheme {
  /// Active brand palette. Green is the production default.
  static AppBrandVariant active = AppBrandVariant.green;

  static BrandPalette get colors => switch (active) {
        AppBrandVariant.green => green,
        AppBrandVariant.blue => blue,
      };

  static void setActive(AppBrandVariant variant) {
    active = variant;
  }

  /// Original RenewWise green brand palette.
  static const green = BrandPalette(
    primary: Color(0xFF10B981),
    primaryDark: Color(0xFF047857),
    mint: Color(0xFFD1FAE5),
    accent: Color(0xFF14B8A6),
    softStart: Color(0xFFE8FBF3),
    softEnd: Color(0xFFD1FAE5),
  );

  /// Premium blue brand palette — calm, professional, finance-grade.
  static const blue = BrandPalette(
    primary: Color(0xFF2563EB),
    primaryDark: Color(0xFF1E40AF),
    mint: Color(0xFFDBEAFE),
    accent: Color(0xFF3B82F6),
    softStart: Color(0xFFEFF6FF),
    softEnd: Color(0xFFDBEAFE),
  );
}

/// Brand-only colours for a single palette variant.
///
/// Semantic colours (success, warning, error) live in [AppColors] and stay fixed.
final class BrandPalette {
  const BrandPalette({
    required this.primary,
    required this.primaryDark,
    required this.mint,
    required this.accent,
    required this.softStart,
    required this.softEnd,
  });

  final Color primary;
  final Color primaryDark;
  final Color mint;
  final Color accent;
  final Color softStart;
  final Color softEnd;

  List<Color> get logoGradient => [primary, primaryDark];
}
