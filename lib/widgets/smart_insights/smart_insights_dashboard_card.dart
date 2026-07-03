import 'package:flutter/material.dart';

import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/widgets/home/home_card_watermarks.dart';
import 'package:renew_wise/widgets/home/home_summary_card.dart';

/// Tappable Smart Insights dashboard card — matches Home premium card style.
class SmartInsightsDashboardCard extends StatelessWidget {
  const SmartInsightsDashboardCard({
    super.key,
    required this.title,
    required this.theme,
    required this.icon,
    required this.summaryLines,
    required this.onTap,
  });

  final String title;
  final HomeDashboardCardTheme theme;
  final IconData icon;
  final List<String> summaryLines;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        splashColor: theme.accent.withAlpha(24),
        highlightColor: theme.accent.withAlpha(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 196),
          child: Ink(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [theme.gradientStart, theme.gradientEnd],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: RenewWiseShadows.homeCard(theme.accent),
            ),
            child: Stack(
            fit: StackFit.expand,
            children: [
              HomeCardWatermark(
                kind: theme.watermarkKind,
                accent: theme.accent,
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _IconTile(icon: icon, accent: theme.accent),
                        const Spacer(),
                        _ChevronBubble(accent: theme.accent),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      title,
                      style: RenewWiseTypography.cardTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...summaryLines.map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          line,
                          style: RenewWiseTypography.tileDescription,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Explore →',
                      style: RenewWiseTypography.actionLink.copyWith(
                        color: theme.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: RenewWisePalette.cardSurface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: accent.withAlpha(45),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: accent, size: 22),
    );
  }
}

class _ChevronBubble extends StatelessWidget {
  const _ChevronBubble({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: accent.withAlpha(28),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.chevron_right_rounded, color: accent, size: 18),
    );
  }
}
