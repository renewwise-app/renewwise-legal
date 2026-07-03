import 'package:flutter/material.dart';

import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';

/// Compact empty state for cards, sections, and inline panels.
class RenewWiseInlineEmptyState extends StatelessWidget {
  const RenewWiseInlineEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
  });

  final IconData icon;
  final String message;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: RenewWisePalette.brandSoftStart.withAlpha(90),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withAlpha(20)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.primary.withAlpha(180)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: RenewWiseTypography.secondary.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: RenewWiseTypography.caption.copyWith(
                color: RenewWisePalette.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
