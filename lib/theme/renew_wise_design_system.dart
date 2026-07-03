import 'package:flutter/material.dart';

import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/brand_theme.dart';

/// Locked RenewWise visual language — Home Screen is the master reference.
abstract final class RenewWisePalette {
  static const pageBackground = Color(0xFFF8FAFC);
  static const listBackground = Color(0xFFF7F8FA);
  static const cardSurface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textCaption = Color(0xFF64748B);

  /// Official accent palette (pastel family) — used for charts and card variety.
  static const green = Color(0xFF10B981);
  static const blue = Color(0xFF3B82F6);
  static const purple = Color(0xFF8B5CF6);
  static const orange = Color(0xFFF97316);

  /// Brand-aware soft fills — follow [BrandTheme.active].
  static Color get brandSoftStart => BrandTheme.colors.softStart;
  static Color get brandSoftEnd => BrandTheme.colors.softEnd;

  static const greenSoftStart = Color(0xFFE8FBF3);
  static const greenSoftEnd = Color(0xFFD1FAE5);
  static const blueSoftStart = Color(0xFFEFF6FF);
  static const blueSoftEnd = Color(0xFFDBEAFE);
  static const purpleSoftStart = Color(0xFFF3EFFE);
  static const purpleSoftEnd = Color(0xFFEDE9FE);
  static const orangeSoftStart = Color(0xFFFFF7ED);
  static const orangeSoftEnd = Color(0xFFFFEDD5);
}

abstract final class RenewWiseTypography {
  static const screenTitle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: RenewWisePalette.textPrimary,
    letterSpacing: -0.8,
    height: 1.05,
  );

  static const sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: RenewWisePalette.textPrimary,
    letterSpacing: -0.3,
    height: 1.1,
  );

  static const primaryValue = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.1,
  );

  static const secondary = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w500,
    color: RenewWisePalette.textSecondary,
    height: 1.45,
  );

  static const caption = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: RenewWisePalette.textCaption,
    height: 1.35,
  );

  static const cardTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: RenewWisePalette.textPrimary,
    letterSpacing: -0.3,
    height: 1.1,
  );

  /// Home tile event count — ~75% of [tileTitle], secondary to title.
  static const tileEventCount = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: Color(0xFF334155),
    height: 1.35,
  );

  /// Home tile amount — slightly smaller than [tileEventCount], no "Due" suffix.
  static const tileAmount = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.25,
  );

  /// Home and insight tile descriptions — readable at a glance.
  static const tileDescription = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: RenewWisePalette.textSecondary,
    height: 1.4,
  );

  /// Locked vertical rhythm inside Home dashboard tiles.
  static const tileTitleToEventCount = 12.0;
  static const tileEventCountToAmount = 12.0;
  static const tileAmountToStatusChip = 14.0;
  static const tileStatusChipToAction = 18.0;

  static const actionLink = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    height: 1.15,
  );
}

abstract final class RenewWiseShadows {
  static List<BoxShadow> homeCard(Color accent, {bool pressed = false}) {
    return [
      BoxShadow(
        color: accent.withAlpha(pressed ? 48 : 36),
        blurRadius: pressed ? 24 : 20,
        offset: Offset(0, pressed ? 12 : 10),
      ),
      BoxShadow(
        color: Colors.black.withAlpha(pressed ? 14 : 10),
        blurRadius: pressed ? 12 : 8,
        offset: Offset(0, pressed ? 4 : 2),
      ),
    ];
  }

  static List<BoxShadow> listCard({bool pressed = false}) => [
        BoxShadow(
          color: Colors.black.withAlpha(pressed ? 18 : 10),
          blurRadius: pressed ? 22 : 18,
          offset: Offset(0, pressed ? 8 : 6),
        ),
      ];

  static List<BoxShadow> fab({double scale = 1}) => [
        BoxShadow(
          color: AppColors.primary.withAlpha((90 * scale).round()),
          blurRadius: 18 * scale,
          offset: Offset(0, 8 * scale),
        ),
      ];
}

/// Home tile watermark motion timings — Design Lock v1.0.
abstract final class RenewWiseHomeMotion {
  static const wave = Duration(seconds: 6);
  static const bars = Duration(seconds: 5);
  static const calendar = Duration(seconds: 8);
  static const searchDrift = Duration(seconds: 7);
  static const statusPulse = Duration(seconds: 3);
  static const fabBreath = Duration(milliseconds: 3500);
  static const shellFade = Duration(milliseconds: 280);
}
