import 'package:flutter/material.dart';

import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/renewal_currency.dart';
import 'package:renew_wise/theme/brand_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/utils/home_events_scope.dart';
import 'package:renew_wise/widgets/home/home_card_watermarks.dart';
import 'package:renew_wise/widgets/home/home_summary_badge.dart';

/// Pastel theme for a home dashboard card.
class HomeDashboardCardTheme {
  const HomeDashboardCardTheme({
    required this.accent,
    required this.gradientStart,
    required this.gradientEnd,
    required this.watermarkIcon,
    required this.watermarkKind,
  });

  final Color accent;
  final Color gradientStart;
  final Color gradientEnd;
  final IconData watermarkIcon;
  final HomeWatermarkKind watermarkKind;

  static HomeDashboardCardTheme get today => HomeDashboardCardTheme(
        accent: BrandTheme.colors.primary,
        gradientStart: BrandTheme.colors.softStart,
        gradientEnd: BrandTheme.colors.softEnd,
        watermarkIcon: Icons.waves_rounded,
        watermarkKind: HomeWatermarkKind.wave,
      );

  /// Completed-reminder cards — always green regardless of brand variant.
  static const completed = HomeDashboardCardTheme(
    accent: RenewWisePalette.green,
    gradientStart: RenewWisePalette.greenSoftStart,
    gradientEnd: RenewWisePalette.greenSoftEnd,
    watermarkIcon: Icons.check_circle_outline_rounded,
    watermarkKind: HomeWatermarkKind.wave,
  );

  static const week = HomeDashboardCardTheme(
    accent: RenewWisePalette.blue,
    gradientStart: RenewWisePalette.blueSoftStart,
    gradientEnd: RenewWisePalette.blueSoftEnd,
    watermarkIcon: Icons.bar_chart_rounded,
    watermarkKind: HomeWatermarkKind.bars,
  );

  static const month = HomeDashboardCardTheme(
    accent: RenewWisePalette.purple,
    gradientStart: RenewWisePalette.purpleSoftStart,
    gradientEnd: RenewWisePalette.purpleSoftEnd,
    watermarkIcon: Icons.calendar_month_outlined,
    watermarkKind: HomeWatermarkKind.calendar,
  );

  static const customSearch = HomeDashboardCardTheme(
    accent: RenewWisePalette.orange,
    gradientStart: RenewWisePalette.orangeSoftStart,
    gradientEnd: RenewWisePalette.orangeSoftEnd,
    watermarkIcon: Icons.manage_search_rounded,
    watermarkKind: HomeWatermarkKind.search,
  );
}

/// Premium pastel summary card for the Home dashboard grid.
class HomePremiumSummaryCard extends StatelessWidget {
  const HomePremiumSummaryCard({
    super.key,
    required this.title,
    required this.theme,
    required this.icon,
    required this.onTap,
    this.eventCount,
    this.dueAmountLabel,
    this.badge,
    this.actionLabel = 'View →',
    this.supportingText,
  });

  final String title;
  final HomeDashboardCardTheme theme;
  final IconData icon;
  final VoidCallback onTap;
  final int? eventCount;
  final String? dueAmountLabel;
  final HomeSummaryBadge? badge;
  final String actionLabel;
  final String? supportingText;

  @override
  Widget build(BuildContext context) {
    final cardTheme = theme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        splashColor: cardTheme.accent.withAlpha(24),
        highlightColor: cardTheme.accent.withAlpha(12),
        child: Ink(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cardTheme.gradientStart, cardTheme.gradientEnd],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: RenewWiseShadows.homeCard(cardTheme.accent),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              HomeCardWatermark(
                kind: cardTheme.watermarkKind,
                accent: cardTheme.accent,
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Row(
                      children: [
                        _IconTile(icon: icon, accent: cardTheme.accent),
                        const Spacer(),
                        _ChevronBubble(accent: cardTheme.accent),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      title,
                      style: RenewWiseTypography.cardTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (eventCount != null) ...[
                      _MetricRow(
                        icon: Icons.event_note_outlined,
                        label:
                            '$eventCount Event${eventCount == 1 ? '' : 's'}',
                        accent: cardTheme.accent,
                        style: RenewWiseTypography.tileEventCount,
                      ),
                      const SizedBox(
                        height: RenewWiseTypography.tileEventCountToAmount,
                      ),
                    ],
                    if (dueAmountLabel != null) ...[
                      _MetricRow(
                        icon: Icons.payments_outlined,
                        label: dueAmountLabel!,
                        accent: cardTheme.accent,
                        style: RenewWiseTypography.tileAmount.copyWith(
                          color: cardTheme.accent,
                        ),
                      ),
                      if (badge != null)
                        const SizedBox(
                          height: RenewWiseTypography.tileAmountToStatusChip,
                        ),
                    ],
                    if (supportingText != null) ...[
                      Text(
                        supportingText!,
                        style: RenewWiseTypography.tileDescription,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (badge != null) ...[
                      _StatusBadge(badge: badge!),
                      const SizedBox(
                        height: RenewWiseTypography.tileStatusChipToAction,
                      ),
                    ] else if (eventCount != null || dueAmountLabel != null)
                      const SizedBox(
                        height: RenewWiseTypography.tileStatusChipToAction,
                      ),
                    Text(
                      actionLabel,
                      style: RenewWiseTypography.actionLink.copyWith(
                        color: cardTheme.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
      child: Icon(
        Icons.chevron_right_rounded,
        color: accent,
        size: 18,
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.accent,
    required this.style,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: accent.withAlpha(180)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.badge});

  final HomeSummaryBadge badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badge.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: badge.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            badge.label,
            style: RenewWiseTypography.caption.copyWith(
              color: const Color(0xFF334155),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Summary dashboard card for Home period sections.
class HomeSummaryCard extends StatelessWidget {
  const HomeSummaryCard({
    super.key,
    required this.title,
    required this.summary,
    required this.currency,
    required this.scope,
    required this.renewals,
    required this.theme,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final HomePeriodSummary summary;
  final RenewalCurrency currency;
  final HomeEventsScope scope;
  final List<Renewal> renewals;
  final HomeDashboardCardTheme theme;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badge = HomeSummaryBadgeUtils.forScope(
      scope: scope,
      renewals: renewals,
      highPriorityCount: summary.highPriorityCount,
    );

    final amountLabel = summary.dueTotal > 0 || summary.eventCount > 0
        ? currency.formatAmount(summary.dueTotal)
        : null;

    return HomePremiumSummaryCard(
      title: title,
      theme: theme,
      icon: icon,
      onTap: onTap,
      eventCount: summary.eventCount,
      dueAmountLabel: amountLabel,
      badge: badge,
    );
  }
}

/// Custom Search entry card on the Home dashboard.
class HomeCustomSearchCard extends StatelessWidget {
  const HomeCustomSearchCard({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HomePremiumSummaryCard(
      title: 'Custom Search',
      theme: HomeDashboardCardTheme.customSearch,
      icon: Icons.date_range_outlined,
      onTap: onTap,
      supportingText: 'Find reminders between any two dates.',
      actionLabel: 'Search →',
    );
  }
}
