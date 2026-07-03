import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:renew_wise/models/renewal_category.dart';
import 'package:renew_wise/models/renewal_currency.dart';
import 'package:renew_wise/models/smart_analytics_models.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/utils/empty_state_guidance.dart';
import 'package:renew_wise/widgets/common/renew_wise_inline_empty_state.dart';
import 'package:renew_wise/utils/date_utils.dart';

class SmartAnalyticsFilterBar extends StatelessWidget {
  const SmartAnalyticsFilterBar({
    super.key,
    required this.filter,
    required this.onFilterChanged,
    required this.onPickCustomRange,
    this.showCategoryFilters = true,
  });

  final SmartAnalyticsFilterState filter;
  final ValueChanged<SmartAnalyticsFilterState> onFilterChanged;
  final VoidCallback onPickCustomRange;
  final bool showCategoryFilters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Analytics Filters', style: RenewWiseTypography.sectionTitle),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SmartAnalyticsDateFilter.values.map((f) {
            return FilterChip(
              label: Text(f.label),
              selected: filter.dateFilter == f,
              selectedColor: AppColors.primary.withAlpha(28),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                fontWeight: filter.dateFilter == f
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: filter.dateFilter == f
                    ? AppColors.primary
                    : RenewWisePalette.textSecondary,
              ),
              onSelected: (_) {
                if (f == SmartAnalyticsDateFilter.customRange) {
                  onPickCustomRange();
                } else {
                  onFilterChanged(filter.copyWith(dateFilter: f));
                }
              },
            );
          }).toList(),
        ),
        if (showCategoryFilters) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('All Categories'),
                selected: filter.category == null,
                onSelected: (_) =>
                    onFilterChanged(filter.copyWith(clearCategory: true)),
              ),
              ...RenewalCategory.values.map(
                (c) => FilterChip(
                  label: Text(c.label),
                  selected: filter.category == c,
                  onSelected: (_) =>
                      onFilterChanged(filter.copyWith(category: c)),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class SmartAnalyticsTopInsightsCard extends StatelessWidget {
  const SmartAnalyticsTopInsightsCard({
    super.key,
    required this.insights,
  });

  final List<String> insights;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEEF2FF), Color(0xFFF5F3FF)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.homeCard),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: RenewWisePalette.purple.withAlpha(28),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.auto_awesome_outlined,
                  color: RenewWisePalette.purple,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOP INSIGHTS',
                      style: RenewWiseTypography.sectionTitle.copyWith(
                        letterSpacing: 0.6,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Key takeaways from your data',
                      style: RenewWiseTypography.secondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (insights.isEmpty)
            const SmartAnalyticsEmptyState(
              icon: Icons.insights_outlined,
              message: 'Insights will appear here',
              subtitle: EmptyStateGuidance.smartInsights,
            )
          else
            ...insights.map(
              (insight) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        insight,
                        style: RenewWiseTypography.tileEventCount.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SmartAnalyticsSpendingSection extends StatelessWidget {
  const SmartAnalyticsSpendingSection({
    super.key,
    required this.snapshot,
  });

  final SmartAnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    if (!snapshot.hasSpendingAnalytics) {
      return const SmartAnalyticsEmptyState(
        icon: Icons.pie_chart_outline_rounded,
        message: 'No expenses yet',
        subtitle: EmptyStateGuidance.spendingAnalysis,
      );
    }

    final fmt = snapshot.currency.formatAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ConclusionText(text: snapshot.spendingConclusion!),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: SmartAnalyticsPieChart(slices: snapshot.categorySlices),
        ),
        const SizedBox(height: 16),
        Text('Category Breakdown', style: RenewWiseTypography.sectionTitle),
        const SizedBox(height: 10),
        ...snapshot.categorySlices.map(
          (slice) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _BreakdownRow(
              color: slice.color,
              label: slice.category.label,
              amount: fmt(slice.amount),
              percentage: '${slice.percentage.toStringAsFixed(1)}%',
            ),
          ),
        ),
      ],
    );
  }
}

class SmartAnalyticsPlannedVsActualSection extends StatelessWidget {
  const SmartAnalyticsPlannedVsActualSection({
    super.key,
    required this.snapshot,
  });

  final SmartAnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final data = snapshot.plannedVsActual;
    if (data == null || (data.planned <= 0 && data.actual <= 0)) {
      return const SmartAnalyticsEmptyState(
        icon: Icons.compare_arrows_rounded,
        message: 'Not enough data yet.',
        subtitle: 'Add reminders and expenses to compare planned vs actual.',
      );
    }

    final fmt = snapshot.currency.formatAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (snapshot.plannedVsActualConclusion != null) ...[
          _ConclusionText(text: snapshot.plannedVsActualConclusion!),
          const SizedBox(height: 16),
        ],
        _MetricTile(label: 'Planned Expenses', value: fmt(data.planned)),
        const SizedBox(height: 8),
        _MetricTile(label: 'Actual Expenses', value: fmt(data.actual)),
        const SizedBox(height: 8),
        _MetricTile(
          label: 'Difference',
          value: fmt(data.difference.abs()),
          subtitle: data.isUnderBudget ? 'Under budget' : 'Over budget',
          valueColor: data.isUnderBudget ? RenewWisePalette.green : AppColors.critical,
        ),
        const SizedBox(height: 16),
        SmartAnalyticsComparisonChart(
          planned: data.planned,
          actual: data.actual,
          currency: snapshot.currency,
        ),
      ],
    );
  }
}

class SmartAnalyticsGoalProgressSection extends StatelessWidget {
  const SmartAnalyticsGoalProgressSection({
    super.key,
    required this.snapshot,
  });

  final SmartAnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final progress = snapshot.goalProgress;
    if (progress == null) {
      return const SmartAnalyticsEmptyState(
        icon: Icons.flag_outlined,
        message: 'No goal progress yet.',
        subtitle: 'Generate a savings plan to see goal progress analytics.',
      );
    }

    final fmt = snapshot.currency.formatAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MetricTile(label: 'Goal Amount', value: fmt(progress.goalAmount)),
        const SizedBox(height: 8),
        _MetricTile(
          label: 'Estimated Savings',
          value: fmt(progress.estimatedSavings),
        ),
        const SizedBox(height: 8),
        _MetricTile(
          label: 'Remaining Amount',
          value: fmt(progress.remainingAmount),
        ),
        const SizedBox(height: 8),
        _MetricTile(
          label: 'Completion Percentage',
          value: '${progress.completionPercent.toStringAsFixed(0)}%',
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: (progress.completionPercent / 100).clamp(0, 1),
            backgroundColor: const Color(0xFFE2E8F0),
            color: progress.isOnTrack ? RenewWisePalette.green : AppColors.gold,
          ),
        ),
        const SizedBox(height: 16),
        _ConclusionText(text: progress.conclusion),
      ],
    );
  }
}

class SmartAnalyticsYearlyTrendSection extends StatefulWidget {
  const SmartAnalyticsYearlyTrendSection({
    super.key,
    required this.snapshot,
  });

  final SmartAnalyticsSnapshot snapshot;

  @override
  State<SmartAnalyticsYearlyTrendSection> createState() =>
      _SmartAnalyticsYearlyTrendSectionState();
}

class _SmartAnalyticsYearlyTrendSectionState
    extends State<SmartAnalyticsYearlyTrendSection> {
  YearlyMonthStat? _selected;

  @override
  Widget build(BuildContext context) {
    if (!widget.snapshot.hasYearlyAnalytics) {
      return const SmartAnalyticsEmptyState(
        icon: Icons.bar_chart_rounded,
        message: 'No yearly trend yet',
        subtitle: EmptyStateGuidance.yearlyTrend,
      );
    }

    final fmt = widget.snapshot.currency.formatAmount;
    final months = widget.snapshot.yearlyMonths;
    final maxAmount = months
        .map((m) => m.totalAmount)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.snapshot.yearlyConclusion != null) ...[
          _ConclusionText(text: widget.snapshot.yearlyConclusion!),
          const SizedBox(height: 16),
        ],
        SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: months.map((month) {
              return Expanded(
                child: _MonthBar(
                  month: month,
                  maxAmount: maxAmount,
                  selected: _selected?.month == month.month,
                  onTap: () {
                    setState(() => _selected = month);
                    if (month.totalAmount > 0) {
                      _showMonthDetail(context, month, fmt);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        _MetricTile(
          label: 'Average Monthly Expense',
          value: fmt(
            months.fold<double>(0, (sum, m) => sum + m.totalAmount) /
                months.where((m) => m.totalAmount > 0).length.clamp(1, 12),
          ),
        ),
      ],
    );
  }

  Future<void> _showMonthDetail(
    BuildContext context,
    YearlyMonthStat month,
    String Function(double) fmt,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: ListView(
            controller: controller,
            children: [
              Text(
                '${RenewalDateUtils.monthName(month.month)} ${month.year}',
                style: RenewWiseTypography.cardTitle,
              ),
              const SizedBox(height: 8),
              Text(
                'Total: ${fmt(month.totalAmount)}',
                style: RenewWiseTypography.tileEventCount.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text('Reminders', style: RenewWiseTypography.sectionTitle),
              const SizedBox(height: 8),
              if (month.reminders.isEmpty)
                Text('No planned reminders', style: RenewWiseTypography.secondary)
              else
                ...month.reminders.map(
                  (r) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(r.category.icon, size: 20),
                    title: Text(r.title),
                    trailing: Text(fmt(r.amount ?? 0)),
                  ),
                ),
              const SizedBox(height: 16),
              Text('Recorded Expenses', style: RenewWiseTypography.sectionTitle),
              const SizedBox(height: 8),
              if (month.expenses.isEmpty)
                Text('No recorded expenses', style: RenewWiseTypography.secondary)
              else
                ...month.expenses.map(
                  (e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(e.category.icon, size: 20),
                    title: Text(e.category.label),
                    subtitle: Text(RenewalDateUtils.formatDisplayDate(e.date)),
                    trailing: Text(fmt(e.amount)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SmartAnalyticsThisMonthSection extends StatelessWidget {
  const SmartAnalyticsThisMonthSection({
    super.key,
    required this.overview,
  });

  final ThisMonthOverview? overview;

  @override
  Widget build(BuildContext context) {
    if (overview == null) {
      return const SmartAnalyticsEmptyState(
        icon: Icons.calendar_month_rounded,
        message: 'No monthly overview yet',
        subtitle: EmptyStateGuidance.smartInsights,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MetricTile(label: 'Status', value: overview!.status),
        const SizedBox(height: 10),
        _MetricTile(label: 'Expected Spending', value: overview!.expectedSpending),
        const SizedBox(height: 10),
        _MetricTile(label: 'Expected Savings', value: overview!.expectedSavings),
        const SizedBox(height: 10),
        _MetricTile(
          label: 'Highest Expense Category',
          value: overview!.highestCategory,
        ),
        const SizedBox(height: 10),
        _MetricTile(
          label: 'Next Important Reminder',
          value: overview!.nextReminder,
        ),
      ],
    );
  }
}

class SmartAnalyticsEmptyState extends StatelessWidget {
  const SmartAnalyticsEmptyState({
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
    return RenewWiseInlineEmptyState(
      icon: icon,
      message: message,
      subtitle: subtitle,
    );
  }
}

class SmartAnalyticsPieChart extends StatelessWidget {
  const SmartAnalyticsPieChart({super.key, required this.slices});

  final List<AnalyticsCategorySlice> slices;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PiePainter(slices: slices),
      child: Center(
        child: Text(
          '${slices.length} categories',
          style: RenewWiseTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter({required this.slices});

  final List<AnalyticsCategorySlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    if (slices.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const stroke = 24.0;
    var start = -math.pi / 2;

    for (final slice in slices) {
      final sweep = (slice.percentage / 100) * 2 * math.pi;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - stroke / 2),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) =>
      oldDelegate.slices != slices;
}

class SmartAnalyticsComparisonChart extends StatelessWidget {
  const SmartAnalyticsComparisonChart({
    super.key,
    required this.planned,
    required this.actual,
    required this.currency,
  });

  final double planned;
  final double actual;
  final RenewalCurrency currency;

  @override
  Widget build(BuildContext context) {
    final max = math.max(planned, actual);
    if (max <= 0) return const SizedBox.shrink();

    return Column(
      children: [
        _CompareBar(
          label: 'Planned',
          amount: planned,
          max: max,
          color: AppColors.primary,
          currency: currency,
        ),
        const SizedBox(height: 10),
        _CompareBar(
          label: 'Actual',
          amount: actual,
          max: max,
          color: RenewWisePalette.purple,
          currency: currency,
        ),
      ],
    );
  }
}

class _CompareBar extends StatelessWidget {
  const _CompareBar({
    required this.label,
    required this.amount,
    required this.max,
    required this.color,
    required this.currency,
  });

  final String label;
  final double amount;
  final double max;
  final Color color;
  final RenewalCurrency currency;

  @override
  Widget build(BuildContext context) {
    final fraction = (amount / max).clamp(0.05, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: RenewWiseTypography.secondary)),
            Text(
              currency.formatAmount(amount),
              style: RenewWiseTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            minHeight: 12,
            value: fraction,
            backgroundColor: const Color(0xFFE2E8F0),
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.month,
    required this.maxAmount,
    required this.selected,
    required this.onTap,
  });

  final YearlyMonthStat month;
  final double maxAmount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fraction = maxAmount > 0
        ? (month.totalAmount / maxAmount).clamp(0.08, 1.0)
        : 0.08;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: month.totalAmount > 0 ? fraction : 0.08,
                child: Material(
                  color: selected
                      ? RenewWisePalette.orange
                      : AppColors.primary.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            month.label,
            style: RenewWiseTypography.caption.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _ConclusionText extends StatelessWidget {
  const _ConclusionText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withAlpha(40)),
      ),
      child: Text(
        text,
        style: RenewWiseTypography.tileEventCount.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    this.subtitle,
    this.valueColor,
  });

  final String label;
  final String value;
  final String? subtitle;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: RenewWiseTypography.secondary)),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                textAlign: TextAlign.end,
                style: RenewWiseTypography.tileEventCount.copyWith(
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? RenewWisePalette.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: RenewWiseTypography.caption),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.color,
    required this.label,
    required this.amount,
    required this.percentage,
  });

  final Color color;
  final String label;
  final String amount;
  final String percentage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: RenewWiseTypography.secondary)),
        Text(
          amount,
          style: RenewWiseTypography.tileEventCount.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 10),
        Text(percentage, style: RenewWiseTypography.caption),
      ],
    );
  }
}
