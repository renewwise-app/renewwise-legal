import 'package:flutter/material.dart';

import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/widgets/common/app_interactive.dart';
import 'package:renew_wise/widgets/common/app_motion.dart';

/// Large tappable dashboard summary card with ripple and chevron.
class DashboardSummaryCard extends StatelessWidget {
  const DashboardSummaryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.actionLabel = 'Review',
    this.compact = false,
    this.hero = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
  final String actionLabel;
  final bool compact;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = hero
        ? const EdgeInsets.all(20)
        : compact
            ? const EdgeInsets.all(16)
            : const EdgeInsets.all(20);
    final iconSize = hero ? 56.0 : compact ? 44.0 : 52.0;
    final iconGlyph = hero ? 28.0 : compact ? 22.0 : 26.0;

    final card = AppInteractiveCard(
      hero: hero,
      onTap: onTap,
      color: hero ? accentColor.withAlpha(14) : null,
      border: BorderSide(
        color: hero
            ? accentColor.withAlpha(80)
            : theme.colorScheme.outlineVariant.withAlpha(120),
        width: hero ? 1.5 : 1,
      ),
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: accentColor.withAlpha(hero ? 32 : 22),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: accentColor, size: iconGlyph),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: (hero
                            ? theme.textTheme.titleLarge
                            : theme.textTheme.titleMedium)
                        ?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: hero ? 6 : 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                      fontWeight: hero ? FontWeight.w500 : null,
                    ),
                    maxLines: hero ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 8),
                    Text(
                      actionLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: accentColor.withAlpha(180),
              size: hero ? 28 : 24,
            ),
          ],
        ),
      ),
    );

    if (hero) return card;

    return AppFadeSlideIn(child: card);
  }
}
