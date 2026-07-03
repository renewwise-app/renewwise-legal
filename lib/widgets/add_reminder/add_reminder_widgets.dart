import 'package:flutter/material.dart';

import 'package:renew_wise/models/reminder_workflow_type.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/widgets/common/feature_purpose_subtitle.dart';

class ReminderTypeSelectionStep extends StatelessWidget {
  const ReminderTypeSelectionStep({
    super.key,
    required this.onSelected,
  });

  final ValueChanged<ReminderWorkflowType> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        6,
        AppSpacing.page,
        12,
      ),
      children: [
        Text(
          'What type of reminder would you like to create?',
          style: RenewWiseTypography.screenTitle.copyWith(fontSize: 24),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Choose the path that best matches what you need.',
          style: RenewWiseTypography.secondary,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ...ReminderWorkflowType.values.map(
          (type) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ReminderTypeCard(
              type: type,
              onTap: () => onSelected(type),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReminderTypeCard extends StatelessWidget {
  const _ReminderTypeCard({
    required this.type,
    required this.onTap,
  });

  final ReminderWorkflowType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = switch (type) {
      ReminderWorkflowType.oneTime => RenewWisePalette.green,
      ReminderWorkflowType.recurring => RenewWisePalette.blue,
      ReminderWorkflowType.renewal => RenewWisePalette.purple,
    };
    final gradientStart = switch (type) {
      ReminderWorkflowType.oneTime => RenewWisePalette.brandSoftStart,
      ReminderWorkflowType.recurring => RenewWisePalette.blueSoftStart,
      ReminderWorkflowType.renewal => RenewWisePalette.purpleSoftStart,
    };
    final gradientEnd = switch (type) {
      ReminderWorkflowType.oneTime => RenewWisePalette.brandSoftEnd,
      ReminderWorkflowType.recurring => RenewWisePalette.blueSoftEnd,
      ReminderWorkflowType.renewal => RenewWisePalette.purpleSoftEnd,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.homeCard),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [gradientStart, gradientEnd],
            ),
            borderRadius: BorderRadius.circular(AppRadius.homeCard),
            boxShadow: RenewWiseShadows.homeCard(accent),
            border: Border.all(color: accent.withAlpha(30)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: RenewWisePalette.cardSurface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withAlpha(40),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(type.icon, color: accent, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.title,
                        style: RenewWiseTypography.cardTitle.copyWith(
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        type.description,
                        style: RenewWiseTypography.secondary.copyWith(
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        type.examples,
                        style: RenewWiseTypography.caption.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddReminderQuestionCard extends StatelessWidget {
  const AddReminderQuestionCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.heading,
    this.subtitle,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final String heading;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RenewWisePalette.cardSurface,
      elevation: 0,
      borderRadius: BorderRadius.circular(AddReminderTokens.cardRadius),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AddReminderTokens.cardPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AddReminderTokens.cardRadius),
          border: Border.all(color: AppColors.primary.withAlpha(16)),
          boxShadow: RenewWiseShadows.homeCard(AppColors.primary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: AddReminderTokens.iconTileSize,
                  height: AddReminderTokens.iconTileSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        iconColor.withAlpha(36),
                        iconColor.withAlpha(14),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    icon,
                    size: AddReminderTokens.sectionIconSize,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(heading, style: AddReminderStyles.heading),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitle!, style: AddReminderStyles.helper),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class AddReminderInputShell extends StatelessWidget {
  const AddReminderInputShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            RenewWisePalette.brandSoftStart.withAlpha(170),
            RenewWisePalette.cardSurface,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withAlpha(22)),
      ),
      child: child,
    );
  }
}

class AddReminderDocumentProtectionHint extends StatelessWidget {
  const AddReminderDocumentProtectionHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: RenewWisePalette.blueSoftStart.withAlpha(120),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withAlpha(20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 18,
            color: AppColors.primary.withAlpha(200),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Optional — protect attached documents using your phone\'s fingerprint or screen lock.',
              style: AddReminderStyles.helper.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddReminderAmbientBackground extends StatelessWidget {
  const AddReminderAmbientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            RenewWisePalette.brandSoftStart,
            RenewWisePalette.pageBackground,
            RenewWisePalette.pageBackground,
          ],
          stops: const [0, 0.42, 1],
        ),
      ),
    );
  }
}

class AddReminderHeader extends StatelessWidget {
  const AddReminderHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.subtitle,
  });

  final String title;
  final VoidCallback onBack;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
      child: Column(
        children: [
          Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Ink(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: RenewWisePalette.cardSurface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: RenewWiseShadows.listCard(),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      size: AppIconSize.sm,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: RenewWiseTypography.cardTitle.copyWith(fontSize: 18),
                ),
              ),
              const SizedBox(width: 44),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: FeaturePurposeSubtitle(subtitle!),
            ),
          ],
        ],
      ),
    );
  }
}

class AddReminderProgressIndicator extends StatelessWidget {
  const AddReminderProgressIndicator({
    super.key,
    required this.labels,
    required this.activeIndex,
  });

  final List<String> labels;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Column(
        children: [
          Row(
            children: List.generate(labels.length, (i) {
              final active = i == activeIndex;
              final done = i < activeIndex;
              final accent = active || done
                  ? AppColors.primary
                  : RenewWisePalette.textCaption;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: i == 0 ? 0 : 4,
                    right: i == labels.length - 1 ? 0 : 4,
                  ),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RenewWiseTypography.caption.copyWith(
                      color: accent,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(labels.length * 2 - 1, (i) {
              if (i.isOdd) {
                final segmentIndex = i ~/ 2;
                final filled = activeIndex > segmentIndex;
                return Expanded(
                  child: AnimatedContainer(
                    duration: AppMotion.duration,
                    height: 2,
                    decoration: BoxDecoration(
                      color: filled
                          ? AppColors.primary
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                );
              }
              final stepIndex = i ~/ 2;
              final active = stepIndex == activeIndex;
              final done = stepIndex < activeIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: active || done
                      ? AppColors.primary
                      : RenewWisePalette.cardSurface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active || done
                        ? AppColors.primary
                        : const Color(0xFFE2E8F0),
                    width: active ? 2 : 1.5,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class AddReminderFooter extends StatelessWidget {
  const AddReminderFooter({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryEnabled = true,
    this.onBack,
    this.onSkip,
    this.skipLabel = 'Skip',
    this.helperText,
    this.showSaveIcon = false,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool primaryEnabled;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final String skipLabel;
  final String? helperText;
  final bool showSaveIcon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: RenewWisePalette.cardSurface.withAlpha(235),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (onBack != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onBack,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('← Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (onSkip != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onSkip,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: RenewWisePalette.textSecondary,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(skipLabel),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: onBack != null || onSkip != null ? 1 : 2,
                  child: FilledButton.icon(
                    onPressed: primaryEnabled ? onPrimary : null,
                    icon: showSaveIcon
                        ? const Icon(Icons.check_rounded, size: 20)
                        : const SizedBox.shrink(),
                    label: Text(primaryLabel),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (helperText != null) ...[
              const SizedBox(height: 10),
              Text(
                helperText!,
                textAlign: TextAlign.center,
                style: AddReminderStyles.helper,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

abstract final class AddReminderTokens {
  static const cardRadius = AppRadius.homeCard;
  static const cardPadding = 18.0;
  static const iconTileSize = 52.0;
  static const sectionIconSize = 26.0;
}

abstract final class AddReminderStyles {
  static final heading = RenewWiseTypography.sectionTitle.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  static final helper = RenewWiseTypography.secondary.copyWith(
    fontSize: 13,
    height: 1.35,
  );

  static final input = RenewWiseTypography.secondary.copyWith(
    color: RenewWisePalette.textPrimary,
    fontWeight: FontWeight.w600,
    fontSize: 15,
  );
}

abstract final class AddReminderFieldDecoration {
  static InputDecoration field({
    String? hint,
    String? errorText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      hintText: hint,
      errorText: errorText,
      suffixIcon: suffixIcon,
      hintStyle: RenewWiseTypography.secondary.copyWith(
        color: RenewWisePalette.textCaption,
        fontWeight: FontWeight.w500,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: AppColors.primary.withAlpha(120)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.critical),
      ),
    );
  }
}
