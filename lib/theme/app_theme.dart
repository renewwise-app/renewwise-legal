import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:renew_wise/theme/brand_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/widgets/common/app_motion.dart';

// ─────────────────────────── Color palette ───────────────────────────────────

abstract final class AppColors {
  // ── Brand (variant-aware via [BrandTheme]) ───────────────────────────────
  static Color get primary => BrandTheme.colors.primary;
  static const navy = Color(0xFF0F172A); // Deep Navy — headings / depth
  static Color get mint => BrandTheme.colors.mint;
  static Color get teal => BrandTheme.colors.accent;

  // ── Semantic (fixed — never follow brand variant) ────────────────────────
  static const success = Color(0xFF10B981); // Success Green
  static const warning = Color(0xFFF59E0B); // Warning Amber
  static const critical = Color(0xFFEF4444); // Critical Red
  static const gold = warning; // backward compat

  // ── Neutral ───────────────────────────────────────────────────────────────
  static const background = Color(0xFFF8FAFC); // Page background
  static const white = Color(0xFFFFFFFF);
  static const gray = Color(0xFF64748B); // Neutral Gray — secondary text
  static const textSecondary = gray;
  static const cardBackground = Color(0xFFF1F5F9);
  static const cardBorder = Color(0xFFE2E8F0);

  // ── Backward-compat aliases ───────────────────────────────────────────────
  static Color get primaryGreen => primary;
  static const textPrimary = navy;
  static const appBarForeground = navy;
}

// ─────────────────────────── Theme ───────────────────────────────────────────

abstract final class AppTheme {
  static ThemeData get dark {
    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: AppTypography.screenTitleSize,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
        iconTheme: IconThemeData(size: AppIconSize.md, color: cs.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cs.surfaceContainer,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorder,
          side: BorderSide(color: cs.outlineVariant.withAlpha(120)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant.withAlpha(120),
        space: AppSpacing.divider,
        thickness: 1,
      ),
      iconTheme: IconThemeData(size: AppIconSize.md, color: cs.onSurface),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.inverseSurface,
        contentTextStyle: GoogleFonts.inter(
          color: cs.onInverseSurface,
          fontSize: AppTypography.bodySize,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorder),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.dialogBorder),
        titleTextStyle: GoogleFonts.inter(
          fontSize: AppTypography.screenTitleSize,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: AppTypography.bodySize,
          color: cs.onSurfaceVariant,
          height: 1.45,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest.withAlpha(180),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputBorder,
          borderSide: BorderSide(color: cs.outline.withAlpha(120)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBorder,
          borderSide: BorderSide(color: cs.outline.withAlpha(80)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBorder,
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBorder,
          borderSide: BorderSide(color: cs.error),
        ),
        labelStyle: GoogleFonts.inter(color: cs.onSurfaceVariant),
        hintStyle: GoogleFonts.inter(color: cs.onSurfaceVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: cs.surfaceContainerHighest,
          disabledForegroundColor: cs.onSurfaceVariant.withAlpha(140),
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorder),
          textStyle: GoogleFonts.inter(
            fontSize: AppTypography.buttonSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          splashFactory: InkRipple.splashFactory,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.onSurface,
          disabledForegroundColor: cs.onSurfaceVariant.withAlpha(120),
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorder),
          side: BorderSide(color: cs.outline.withAlpha(140)),
          textStyle: GoogleFonts.inter(
            fontSize: AppTypography.buttonSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.onSurface,
          textStyle: GoogleFonts.inter(
            fontSize: AppTypography.bodySize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: cs.primary.withAlpha(28),
      ),
    );
    return base.copyWith(
      textTheme: _textTheme(GoogleFonts.interTextTheme(base.textTheme)),
    );
  }

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        surface: AppColors.background,
        primary: AppColors.primary,
        error: AppColors.critical,
        onSurface: AppColors.navy,
        onSurfaceVariant: AppColors.gray,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.appBarForeground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: AppTypography.screenTitleSize,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
        iconTheme: const IconThemeData(
          size: AppIconSize.md,
          color: AppColors.navy,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorder,
          side: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.cardBorder,
        space: AppSpacing.divider,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(
        size: AppIconSize.md,
        color: AppColors.navy,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
        contentTextStyle: GoogleFonts.inter(
          color: AppColors.white,
          fontSize: AppTypography.bodySize,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorder),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.dialogBorder),
        titleTextStyle: GoogleFonts.inter(
          fontSize: AppTypography.screenTitleSize,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: AppTypography.bodySize,
          color: AppColors.textSecondary,
          height: 1.45,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputBorder,
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBorder,
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBorder,
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBorder,
          borderSide: const BorderSide(color: AppColors.critical),
        ),
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
        hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.cardBorder,
          disabledForegroundColor: AppColors.textSecondary.withAlpha(160),
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorder),
          textStyle: GoogleFonts.inter(
            fontSize: AppTypography.buttonSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          splashFactory: InkRipple.splashFactory,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          disabledForegroundColor: AppColors.textSecondary.withAlpha(120),
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorder),
          side: const BorderSide(color: AppColors.cardBorder),
          textStyle: GoogleFonts.inter(
            fontSize: AppTypography.buttonSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.navy,
          textStyle: GoogleFonts.inter(
            fontSize: AppTypography.bodySize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withAlpha(28),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: AppColors.primary, size: AppIconSize.md);
          }
          return IconThemeData(color: AppColors.gray.withAlpha(220), size: AppIconSize.md);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: AppTypography.captionSize,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.gray,
          );
        }),
      ),
    );

    return base.copyWith(
      textTheme: _textTheme(GoogleFonts.interTextTheme(base.textTheme)),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: AppTypography.appTitleSize,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: AppTypography.screenTitleSize,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: AppTypography.sectionTitleSize,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: AppTypography.cardTitleSize,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: AppTypography.bodySize,
        height: 1.45,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: AppTypography.bodySize,
        height: 1.45,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: AppTypography.captionSize,
        height: 1.4,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: AppTypography.buttonSize,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
