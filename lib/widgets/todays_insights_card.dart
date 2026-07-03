import 'package:flutter/material.dart';

import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/widgets/common/app_interactive.dart';

/// Surfaces the nearest upcoming reminder on the home screen.
class NextReminderCard extends StatelessWidget {
  const NextReminderCard({
    super.key,
    required this.renewal,
    this.onTap,
  });

  final Renewal renewal;
  final VoidCallback? onTap;

  static String dueLabel(Renewal renewal) {
    final days = renewal.daysRemaining;
    if (days < 0) {
      final n = days.abs();
      return n == 1 ? 'Overdue by 1 day' : 'Overdue by $n days';
    }
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return 'Due in $days days';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = renewal.daysRemaining;
    final accent = days < 0
        ? AppColors.critical
        : days <= 7
            ? AppColors.gold
            : AppColors.primary;

    return AppInteractiveCard(
      onTap: onTap,
      color: accent.withAlpha(14),
      border: BorderSide(color: accent.withAlpha(60)),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withAlpha(28),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                renewal.category.icon,
                color: accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Reminder',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    renewal.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dueLabel(renewal),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: accent.withAlpha(180),
            ),
          ],
        ),
      ),
    );
  }
}
