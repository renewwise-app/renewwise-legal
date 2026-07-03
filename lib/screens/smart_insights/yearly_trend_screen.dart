import 'package:flutter/material.dart';

import 'package:renew_wise/models/renewal_currency.dart';
import 'package:renew_wise/models/smart_analytics_models.dart';
import 'package:renew_wise/services/expense_service.dart';
import 'package:renew_wise/services/goal_planner_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/utils/date_utils.dart';
import 'package:renew_wise/utils/feature_purpose_messaging.dart';
import 'package:renew_wise/utils/smart_analytics_engine.dart';
import 'package:renew_wise/widgets/common/feature_purpose_subtitle.dart';
import 'package:renew_wise/widgets/smart_insights/smart_analytics_widgets.dart';

class SmartInsightsYearlyTrendScreen extends StatefulWidget {
  const SmartInsightsYearlyTrendScreen({
    super.key,
    required this.renewalService,
    required this.goalPlannerService,
    required this.settingsService,
  });

  final RenewalService renewalService;
  final GoalPlannerService goalPlannerService;
  final SettingsService? settingsService;

  static Future<void> push(
    BuildContext context, {
    required RenewalService renewalService,
    required GoalPlannerService goalPlannerService,
    SettingsService? settingsService,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SmartInsightsYearlyTrendScreen(
          renewalService: renewalService,
          goalPlannerService: goalPlannerService,
          settingsService: settingsService,
        ),
      ),
    );
  }

  @override
  State<SmartInsightsYearlyTrendScreen> createState() =>
      _SmartInsightsYearlyTrendScreenState();
}

class _SmartInsightsYearlyTrendScreenState
    extends State<SmartInsightsYearlyTrendScreen> {
  SmartAnalyticsFilterState _filter = const SmartAnalyticsFilterState(
    dateFilter: SmartAnalyticsDateFilter.currentYear,
  );

  @override
  void initState() {
    super.initState();
    widget.renewalService.addListener(_refresh);
    widget.goalPlannerService.addListener(_refresh);
    expenseService.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.renewalService.removeListener(_refresh);
    widget.goalPlannerService.removeListener(_refresh);
    expenseService.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  RenewalCurrency get _currency =>
      widget.settingsService?.defaultCurrency ?? RenewalCurrency.inr;

  SmartAnalyticsSnapshot get _snapshot => SmartAnalyticsEngine.compute(
        expenses: expenseService.expenses,
        renewals: widget.renewalService.renewals,
        goalSettings: widget.goalPlannerService.settings,
        filter: _filter,
        currency: _currency,
      );

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final start = await showDatePicker(
      context: context,
      initialDate: _filter.customStart ?? now.subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'Start date',
    );
    if (start == null || !mounted) return;
    final end = await showDatePicker(
      context: context,
      initialDate: _filter.customEnd ?? now,
      firstDate: start,
      lastDate: now,
      helpText: 'End date',
    );
    if (end == null || !mounted) return;
    setState(() {
      _filter = _filter.copyWith(
        dateFilter: SmartAnalyticsDateFilter.customRange,
        customStart: start,
        customEnd: end,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    final fmt = _currency.formatAmount;
    final withTotals = snapshot.yearlyMonths
        .where((month) => month.totalAmount > 0)
        .toList();
    YearlyMonthStat? highest;
    YearlyMonthStat? lowest;
    if (withTotals.isNotEmpty) {
      withTotals.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
      highest = withTotals.first;
      lowest = withTotals.last;
    }

    final hPad =
        MediaQuery.sizeOf(context).width > 600 ? 32.0 : AppSpacing.page;

    return Scaffold(
      backgroundColor: RenewWisePalette.pageBackground,
      appBar: AppBar(
        backgroundColor: RenewWisePalette.pageBackground,
        surfaceTintColor: Colors.transparent,
        title: const Text('Yearly Expense Trend'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 96),
              children: [
                Text(
                  'Yearly Expense Trend',
                  style: RenewWiseTypography.screenTitle.copyWith(fontSize: 26),
                ),
                const SizedBox(height: 8),
                const FeaturePurposeSubtitle(FeaturePurposeMessaging.yearlyTrend),
                const SizedBox(height: AppSpacing.section),
                SmartAnalyticsFilterBar(
                  filter: _filter,
                  onFilterChanged: (filter) => setState(() => _filter = filter),
                  onPickCustomRange: _pickCustomRange,
                ),
                const SizedBox(height: AppSpacing.section),
                SmartAnalyticsYearlyTrendSection(snapshot: snapshot),
                if (highest != null) ...[
                  const SizedBox(height: AppSpacing.section),
                  _TrendMetric(
                    label: 'Highest Expense Month',
                    value:
                        '${RenewalDateUtils.monthName(highest.month)} · ${fmt(highest.totalAmount)}',
                  ),
                  const SizedBox(height: 10),
                  _TrendMetric(
                    label: 'Lowest Expense Month',
                    value:
                        '${RenewalDateUtils.monthName(lowest!.month)} · ${fmt(lowest.totalAmount)}',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrendMetric extends StatelessWidget {
  const _TrendMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: RenewWiseTypography.secondary)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: RenewWiseTypography.tileEventCount.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
