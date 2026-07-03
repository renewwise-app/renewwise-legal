import 'package:flutter/material.dart';

import 'package:renew_wise/models/life_insights_models.dart';
import 'package:renew_wise/models/renewal_currency.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/utils/date_utils.dart';
import 'package:renew_wise/widgets/common/app_empty_state.dart';
import 'package:renew_wise/widgets/common/renew_wise_inline_empty_state.dart';

class InsightsSummaryCard extends StatelessWidget {
  const InsightsSummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
    this.animate = true,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: animate ? 0.96 : 1, end: 1),
      duration: AppMotion.duration,
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant.withAlpha(120),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 22, color: AppColors.primary),
                const Spacer(),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class InsightsMetricTile extends StatelessWidget {
  const InsightsMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.onTap,
  });

  final String label;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        title: Text(label),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(160),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class InsightsHeatmap extends StatelessWidget {
  const InsightsHeatmap({
    super.key,
    required this.days,
    required this.year,
    required this.month,
    required this.onDayTap,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  final List<DayInsights> days;
  final int year;
  final int month;
  final ValueChanged<DayInsights> onDayTap;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    final firstWeekday = DateTime(year, month, 1).weekday;
    final leading = firstWeekday - 1;
    final cells = <Widget>[
      for (var i = 0; i < leading; i++)
        const SizedBox(width: 36, height: 36),
      ...days.map((d) => _DayCell(day: d, onTap: () => onDayTap(d))),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: onPrevMonth,
                ),
                Expanded(
                  child: Text(
                    '${RenewalDateUtils.monthName(month)} $year',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: onNextMonth,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: cells,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _LegendDot(color: AppColors.teal, label: 'Reminder'),
                _LegendDot(color: AppColors.success, label: 'Completed'),
                _LegendDot(color: AppColors.critical, label: 'Overdue'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.onTap});

  final DayInsights day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (day.kind) {
      DayCellKind.reminder => AppColors.teal,
      DayCellKind.completed => AppColors.success,
      DayCellKind.overdue => AppColors.critical,
      DayCellKind.mixed => AppColors.gold,
      DayCellKind.none => scheme.surfaceContainerHighest,
    };
    final fg = day.kind == DayCellKind.none
        ? scheme.onSurfaceVariant
        : Colors.white;

    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: day.kind == DayCellKind.none ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Text(
              '${day.date.day}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
        ),
      ],
    );
  }
}

class InsightsSpendingChart extends StatelessWidget {
  const InsightsSpendingChart({
    super.key,
    required this.periods,
    required this.currency,
    required this.onPeriodTap,
    this.animate = true,
  });

  final List<SpendingPeriodStat> periods;
  final RenewalCurrency currency;
  final ValueChanged<SpendingPeriodStat> onPeriodTap;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    if (periods.isEmpty) {
      return const RenewWiseInlineEmptyState(
        icon: Icons.bar_chart_outlined,
        message: 'No spending data yet.',
        subtitle: 'Track a few expenses to unlock spending insights.',
      );
    }
    final maxAmount = periods
        .map((p) => p.amount)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < periods.length; i++)
                Expanded(
                  child: _Bar(
                    period: periods[i],
                    maxAmount: maxAmount,
                    currency: currency,
                    onTap: () => onPeriodTap(periods[i]),
                    delay: animate ? Duration(milliseconds: 80 * i) : Duration.zero,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatefulWidget {
  const _Bar({
    required this.period,
    required this.maxAmount,
    required this.currency,
    required this.onTap,
    required this.delay,
  });

  final SpendingPeriodStat period;
  final double maxAmount;
  final RenewalCurrency currency;
  final VoidCallback onTap;
  final Duration delay;

  @override
  State<_Bar> createState() => _BarState();
}

class _BarState extends State<_Bar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppMotion.duration,
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future<void>.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fraction = widget.maxAmount > 0
        ? (widget.period.amount / widget.maxAmount).clamp(0.08, 1.0)
        : 0.08;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedBuilder(
                animation: _anim,
                builder: (context, child) => FractionallySizedBox(
                  heightFactor: fraction * _anim.value,
                  child: child,
                ),
                child: Material(
                  color: AppColors.primary.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.period.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

IconData categoryGroupIcon(CategoryAnalyticsGroup group) {
  return switch (group) {
    CategoryAnalyticsGroup.insurance => Icons.shield_outlined,
    CategoryAnalyticsGroup.medical => Icons.medical_services_outlined,
    CategoryAnalyticsGroup.vehicle => Icons.directions_car_outlined,
    CategoryAnalyticsGroup.subscriptions => Icons.subscriptions_outlined,
    CategoryAnalyticsGroup.property => Icons.home_outlined,
    CategoryAnalyticsGroup.identity => Icons.badge_outlined,
    CategoryAnalyticsGroup.others => Icons.category_outlined,
  };
}

class InsightsAchievementChip extends StatelessWidget {
  const InsightsAchievementChip({super.key, required this.achievement});

  final AchievementInsight achievement;

  @override
  Widget build(BuildContext context) {
    final achieved = achievement.achieved;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: achieved
            ? AppColors.primary.withAlpha(20)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: achieved
              ? AppColors.primary.withAlpha(76)
              : Theme.of(context).colorScheme.outlineVariant.withAlpha(120),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _iconFor(achievement.iconName),
            color: achieved
                ? AppColors.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: achieved
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  achievement.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String name) => switch (name) {
        'calendar_today' => Icons.calendar_today_outlined,
        'verified' => Icons.verified_outlined,
        'shield' => Icons.shield_outlined,
        _ => Icons.check_circle_outline,
      };
}

class InsightsEmptyState extends StatelessWidget {
  const InsightsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      icon: Icons.insights_outlined,
      title: 'Not enough data yet.',
      subtitle:
          'Keep using RenewWise and meaningful insights will appear here over time.',
    );
  }
}
