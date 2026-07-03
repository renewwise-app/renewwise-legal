import 'package:flutter/material.dart';

import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/widgets/common/renew_wise_primary_button.dart';

/// Premium empty state — Package 6B design system.
class RenewWiseEmptyState extends StatelessWidget {
  const RenewWiseEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.divider),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 56,
                color: AppColors.primary.withAlpha(200),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              title,
              style: RenewWiseTypography.cardTitle.copyWith(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: RenewWiseTypography.secondary.copyWith(height: 1.45),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.section),
              RenewWisePrimaryButton(
                label: actionLabel!,
                icon: actionIcon ?? Icons.add_rounded,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
