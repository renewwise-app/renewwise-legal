import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:renew_wise/models/spending_insights_models.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';

class InsightsPageHeader extends StatelessWidget {
  const InsightsPageHeader({
    super.key,
    required this.selectedYear,
    required this.availableYears,
    required this.onYearChanged,
  });

  final int selectedYear;
  final List<int> availableYears;
  final ValueChanged<int> onYearChanged;

  @override
  Widget build(BuildContext context) {
    final nowYear = DateTime.now().year;
    final yearLabel = selectedYear == nowYear
        ? 'This Year'
        : selectedYear.toString();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Life Insights', style: RenewWiseTypography.screenTitle),
              const SizedBox(height: 8),
              Text(
                'Understand your spending. Make better decisions.',
                style: RenewWiseTypography.secondary,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _YearSelectorChip(
          label: yearLabel,
          availableYears: availableYears,
          selectedYear: selectedYear,
          onChanged: onYearChanged,
        ),
      ],
    );
  }
}

class _YearSelectorChip extends StatelessWidget {
  const _YearSelectorChip({
    required this.label,
    required this.availableYears,
    required this.selectedYear,
    required this.onChanged,
  });

  final String label;
  final List<int> availableYears;
  final int selectedYear;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RenewWisePalette.cardSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () async {
          final picked = await showModalBottomSheet<int>(
            context: context,
            showDragHandle: true,
            backgroundColor: Colors.white,
            builder: (ctx) {
              final nowYear = DateTime.now().year;
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Text(
                        'Select year',
                        style: RenewWiseTypography.cardTitle,
                      ),
                    ),
                    ...availableYears.map(
                      (year) => ListTile(
                        title: Text(
                          year == nowYear ? 'This Year ($year)' : '$year',
                          style: RenewWiseTypography.tileEventCount.copyWith(
                            fontWeight: year == selectedYear
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: year == selectedYear
                                ? AppColors.primary
                                : const Color(0xFF334155),
                          ),
                        ),
                        trailing: year == selectedYear
                            ? Icon(
                                Icons.check_rounded,
                                color: AppColors.primary,
                              )
                            : null,
                        onTap: () => Navigator.pop(ctx, year),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          );
          if (picked != null) onChanged(picked);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: RenewWiseShadows.listCard(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: RenewWiseTypography.tileEventCount.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class InsightsCategoryTabs extends StatelessWidget {
  const InsightsCategoryTabs({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final SpendingInsightCategory selected;
  final ValueChanged<SpendingInsightCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      SpendingInsightCategory.allOverview,
      ...SpendingInsightCategory.filterTabs,
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isSelected = tab == selected;
          return FilterChip(
            avatar: Icon(
              tab.icon,
              size: 18,
              color: isSelected ? AppColors.primary : RenewWisePalette.textSecondary,
            ),
            label: Text(tab.label),
            selected: isSelected,
            showCheckmark: false,
            selectedColor: RenewWisePalette.brandSoftEnd,
            side: BorderSide(
              color: isSelected ? AppColors.primary.withAlpha(80) : const Color(0xFFE2E8F0),
            ),
            labelStyle: RenewWiseTypography.tileEventCount.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : const Color(0xFF334155),
            ),
            onSelected: (_) => onSelected(tab),
          );
        },
      ),
    );
  }
}

class InsightsSmartSummaryCard extends StatelessWidget {
  const InsightsSmartSummaryCard({
    super.key,
    required this.snapshot,
  });

  final SpendingInsightsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final currency = snapshot.currency;
    String fmt(double value) => currency.formatAmount(value);

    final diff = snapshot.differenceAmount;
    final diffLabel = diff >= 0
        ? '+${fmt(diff)}'
        : '-${fmt(diff.abs())}';
    final pctLabel = snapshot.differencePercent >= 0
        ? '+${snapshot.differencePercent.abs().toStringAsFixed(1)}%'
        : '-${snapshot.differencePercent.abs().toStringAsFixed(1)}%';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            RenewWisePalette.brandSoftStart,
            RenewWisePalette.brandSoftEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.homeCard),
        boxShadow: RenewWiseShadows.homeCard(AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            snapshot.headlineInsight,
            style: RenewWiseTypography.cardTitle.copyWith(
              fontSize: 20,
              height: 1.25,
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          _SummaryMetricRow(
            label: 'Total spent this year',
            value: fmt(snapshot.totalSpentThisYear),
          ),
          const SizedBox(height: 10),
          _SummaryMetricRow(
            label: 'Difference vs last year',
            value: diffLabel,
            valueColor: diff > 0
                ? const Color(0xFFDC2626)
                : diff < 0
                    ? RenewWisePalette.green
                    : RenewWisePalette.textPrimary,
          ),
          const SizedBox(height: 10),
          _SummaryMetricRow(
            label: 'Percentage change',
            value: pctLabel,
            valueColor: diff > 0
                ? const Color(0xFFDC2626)
                : diff < 0
                    ? RenewWisePalette.green
                    : RenewWisePalette.textPrimary,
          ),
        ],
      ),
    );
  }
}

class _SummaryMetricRow extends StatelessWidget {
  const _SummaryMetricRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: RenewWiseTypography.secondary),
        ),
        Text(
          value,
          style: RenewWiseTypography.tileEventCount.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor ?? RenewWisePalette.textPrimary,
          ),
        ),
      ],
    );
  }
}

class InsightsSectionTitle extends StatelessWidget {
  const InsightsSectionTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: RenewWiseTypography.sectionTitle);
  }
}

class InsightsMoneyGoesCard extends StatelessWidget {
  const InsightsMoneyGoesCard({
    super.key,
    required this.snapshot,
  });

  final SpendingInsightsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final breakdown = snapshot.categoryBreakdown;
    String fmt(double value) => snapshot.currency.formatAmount(value);

    return _InsightsPremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (breakdown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No spending recorded for this period.',
                style: RenewWiseTypography.secondary,
              ),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 132,
                  height: 132,
                  child: InsightsDoughnutChart(slices: breakdown),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      for (final slice in breakdown.take(5))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _BreakdownRow(
                            color: slice.color,
                            category: slice.category.label,
                            amount: fmt(slice.amount),
                            percentage:
                                '${slice.percentage.toStringAsFixed(0)}%',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.section),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: RenewWisePalette.brandSoftStart,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                snapshot.breakdownInsight,
                style: RenewWiseTypography.secondary.copyWith(
                  color: RenewWisePalette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.color,
    required this.category,
    required this.amount,
    required this.percentage,
  });

  final Color color;
  final String category;
  final String amount;
  final String percentage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            category,
            style: RenewWiseTypography.tileEventCount.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(amount, style: RenewWiseTypography.tileAmount),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            percentage,
            textAlign: TextAlign.right,
            style: RenewWiseTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class InsightsDoughnutChart extends StatelessWidget {
  const InsightsDoughnutChart({super.key, required this.slices});

  final List<CategorySpendingSlice> slices;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DoughnutPainter(slices: slices),
      child: const Center(
        child: Icon(
          Icons.pie_chart_outline_rounded,
          color: Color(0x14000000),
          size: 28,
        ),
      ),
    );
  }
}

class _DoughnutPainter extends CustomPainter {
  _DoughnutPainter({required this.slices});

  final List<CategorySpendingSlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    if (slices.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const stroke = 22.0;
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
  bool shouldRepaint(covariant _DoughnutPainter oldDelegate) {
    return oldDelegate.slices != slices;
  }
}

class InsightsCompareYearCard extends StatelessWidget {
  const InsightsCompareYearCard({
    super.key,
    required this.snapshot,
  });

  final SpendingInsightsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    String fmt(double value) => snapshot.currency.formatAmount(value);
    final rows = snapshot.yearComparisons;

    return _InsightsPremiumCard(
      child: rows.isEmpty
          ? Text(
              'No category spending to compare yet.',
              style: RenewWiseTypography.secondary,
            )
          : Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const Divider(height: 24),
                  _CompareRow(row: rows[i], formatAmount: fmt),
                ],
              ],
            ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  const _CompareRow({
    required this.row,
    required this.formatAmount,
  });

  final CategoryYearComparisonRow row;
  final String Function(double) formatAmount;

  @override
  Widget build(BuildContext context) {
    final delta = row.deltaAmount;
    final isUp = delta > 0;
    final isDown = delta < 0;
    final deltaColor = isUp
        ? const Color(0xFFDC2626)
        : isDown
            ? RenewWisePalette.green
            : RenewWisePalette.textSecondary;
    final arrow = isUp ? '▲' : isDown ? '▼' : '•';
    final deltaText = isUp || isDown
        ? '$arrow ${formatAmount(delta.abs())}'
        : 'No change';
    final pctText = row.lastYearAmount <= 0 && row.currentAmount > 0
        ? '(new)'
        : '(${delta >= 0 ? '+' : '-'}${row.deltaPercent.abs().toStringAsFixed(1)}%)';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(row.category.icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(row.category.label, style: RenewWiseTypography.cardTitle),
              const SizedBox(height: 4),
              Text(
                formatAmount(row.currentAmount),
                style: RenewWiseTypography.primaryValue.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 2),
              Text(
                'Last Year ${formatAmount(row.lastYearAmount)}',
                style: RenewWiseTypography.caption,
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              deltaText,
              style: RenewWiseTypography.tileEventCount.copyWith(
                fontWeight: FontWeight.w700,
                color: deltaColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              pctText,
              style: RenewWiseTypography.caption.copyWith(color: deltaColor),
            ),
          ],
        ),
      ],
    );
  }
}

class InsightsBiggestChangesSection extends StatelessWidget {
  const InsightsBiggestChangesSection({
    super.key,
    required this.snapshot,
  });

  final SpendingInsightsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    String fmt(double value) => snapshot.currency.formatAmount(value.abs());

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _InsightsPremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Biggest Increases', style: RenewWiseTypography.cardTitle),
                  const SizedBox(height: 12),
                  if (snapshot.biggestIncreases.isEmpty)
                    Text(
                      'No spending increases this year.',
                      style: RenewWiseTypography.caption,
                    )
                  else
                    ...snapshot.biggestIncreases.asMap().entries.map(
                          (entry) => _RankRow(
                            rank: entry.key + 1,
                            label: entry.value.category.label,
                            value: '▲ ${fmt(entry.value.deltaAmount)}',
                            valueColor: const Color(0xFFDC2626),
                          ),
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _InsightsPremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Biggest Savings', style: RenewWiseTypography.cardTitle),
                  const SizedBox(height: 12),
                  if (snapshot.biggestSavings.isEmpty)
                    Text(
                      'No category reduced spending this year.',
                      style: RenewWiseTypography.caption,
                    )
                  else
                    ...snapshot.biggestSavings.asMap().entries.map(
                          (entry) => _RankRow(
                            rank: entry.key + 1,
                            label: entry.value.category.label,
                            value: '▼ ${fmt(entry.value.deltaAmount)}',
                            valueColor: RenewWisePalette.green,
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

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final int rank;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            '$rank.',
            style: RenewWiseTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: RenewWiseTypography.tileEventCount.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: RenewWiseTypography.tileAmount.copyWith(
              color: valueColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class InsightsNewThisYearCard extends StatelessWidget {
  const InsightsNewThisYearCard({
    super.key,
    required this.snapshot,
  });

  final SpendingInsightsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    String fmt(double value) => snapshot.currency.formatAmount(value);
    final items = snapshot.newExpenses;

    return _InsightsPremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            items.isEmpty
                ? 'No new expenses detected this year.'
                : 'You have ${items.length} new expense${items.length == 1 ? '' : 's'} this year.',
            style: RenewWiseTypography.secondary.copyWith(
              fontWeight: FontWeight.w600,
              color: RenewWisePalette.textPrimary,
            ),
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.section),
            ...items.take(6).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: RenewWiseTypography.cardTitle.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'New this year · ${item.category.label}',
                                style: RenewWiseTypography.caption,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: RenewWisePalette.orangeSoftStart,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: RenewWisePalette.orange.withAlpha(80),
                            ),
                          ),
                          child: Text(
                            'NEW',
                            style: RenewWiseTypography.caption.copyWith(
                              fontWeight: FontWeight.w800,
                              color: RenewWisePalette.orange,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          fmt(item.amount),
                          style: RenewWiseTypography.tileEventCount.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class InsightsDecisionEmptyState extends StatelessWidget {
  const InsightsDecisionEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.divider),
      decoration: BoxDecoration(
        color: RenewWisePalette.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.homeCard),
        boxShadow: RenewWiseShadows.listCard(),
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.insights_rounded,
              size: 42,
              color: AppColors.primary.withAlpha(200),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Not enough data yet.',
            style: RenewWiseTypography.cardTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Keep using RenewWise and meaningful insights will appear here over time.',
            style: RenewWiseTypography.secondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _InsightsPremiumCard extends StatelessWidget {
  const _InsightsPremiumCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: RenewWisePalette.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.homeCard),
        boxShadow: RenewWiseShadows.listCard(),
      ),
      child: child,
    );
  }
}
