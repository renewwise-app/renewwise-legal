import 'package:flutter/material.dart';

import 'package:renew_wise/models/expense_record.dart';
import 'package:renew_wise/models/renewal_currency.dart';
import 'package:renew_wise/models/smart_analytics_models.dart';
import 'package:renew_wise/services/expense_service.dart';
import 'package:renew_wise/services/goal_planner_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/utils/feature_purpose_messaging.dart';
import 'package:renew_wise/utils/empty_state_guidance.dart';
import 'package:renew_wise/utils/smart_analytics_engine.dart';
import 'package:renew_wise/widgets/common/feature_purpose_subtitle.dart';
import 'package:renew_wise/widgets/common/renew_wise_empty_state.dart';
import 'package:renew_wise/widgets/smart_insights/expense_tracking_section.dart';
import 'package:renew_wise/widgets/smart_insights/smart_analytics_widgets.dart';

class SmartInsightsSpendingAnalysisScreen extends StatefulWidget {
  const SmartInsightsSpendingAnalysisScreen({
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
        builder: (_) => SmartInsightsSpendingAnalysisScreen(
          renewalService: renewalService,
          goalPlannerService: goalPlannerService,
          settingsService: settingsService,
        ),
      ),
    );
  }

  @override
  State<SmartInsightsSpendingAnalysisScreen> createState() =>
      _SmartInsightsSpendingAnalysisScreenState();
}

class _SmartInsightsSpendingAnalysisScreenState
    extends State<SmartInsightsSpendingAnalysisScreen> {
  SmartAnalyticsFilterState _filter = const SmartAnalyticsFilterState();

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

  ExpenseFilterState _expenseFilter(SmartAnalyticsFilterState filter) {
    final now = DateTime.now();
    return switch (filter.dateFilter) {
      SmartAnalyticsDateFilter.currentMonth => ExpenseFilterState(
          dateFilter: ExpenseDateFilter.currentMonth,
          category: filter.category,
        ),
      SmartAnalyticsDateFilter.last30Days => ExpenseFilterState(
          dateFilter: ExpenseDateFilter.last30Days,
          category: filter.category,
        ),
      SmartAnalyticsDateFilter.currentYear => ExpenseFilterState(
          dateFilter: ExpenseDateFilter.customRange,
          customStart: DateTime(now.year, 1, 1),
          customEnd: DateTime(now.year, 12, 31),
          category: filter.category,
        ),
      SmartAnalyticsDateFilter.customRange => ExpenseFilterState(
          dateFilter: ExpenseDateFilter.customRange,
          customStart: filter.customStart,
          customEnd: filter.customEnd,
          category: filter.category,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    final filtered = expenseService.filtered(_expenseFilter(_filter));
    final summary = expenseService.summarize(filtered);
    final fmt = _currency.formatAmount;
    final hasExpenses = expenseService.expenses.isNotEmpty;
    final hPad =
        MediaQuery.sizeOf(context).width > 600 ? 32.0 : AppSpacing.page;

    return Scaffold(
      backgroundColor: RenewWisePalette.pageBackground,
      appBar: AppBar(
        backgroundColor: RenewWisePalette.pageBackground,
        surfaceTintColor: Colors.transparent,
        title: const Text('Spending Analysis'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 96),
              children: [
                Text(
                  'Spending Analysis',
                  style: RenewWiseTypography.screenTitle.copyWith(fontSize: 26),
                ),
                const SizedBox(height: 8),
                const FeaturePurposeSubtitle(
                  FeaturePurposeMessaging.spendingAnalysis,
                ),
                const SizedBox(height: AppSpacing.section),
                if (!hasExpenses) ...[
                  RenewWiseEmptyState(
                    icon: Icons.pie_chart_outline_rounded,
                    title: 'No expenses yet',
                    subtitle: EmptyStateGuidance.spendingAnalysis,
                  ),
                  const SizedBox(height: AppSpacing.section),
                  Text(
                    'Expense Records',
                    style: RenewWiseTypography.sectionTitle,
                  ),
                  const SizedBox(height: 12),
                  ExpenseTrackingSection(
                    expenseService: expenseService,
                    currency: _currency,
                    hideChartPlaceholder: true,
                  ),
                ] else ...[
                  SmartAnalyticsFilterBar(
                    filter: _filter,
                    onFilterChanged: (filter) =>
                        setState(() => _filter = filter),
                    onPickCustomRange: _pickCustomRange,
                    showCategoryFilters: false,
                  ),
                  const SizedBox(height: AppSpacing.section),
                  _FinancialSummaryCard(
                    summary: summary,
                    format: fmt,
                  ),
                  const SizedBox(height: AppSpacing.section),
                  SmartAnalyticsSpendingSection(snapshot: snapshot),
                  const SizedBox(height: AppSpacing.section),
                  Text(
                    'Planned vs Actual',
                    style: RenewWiseTypography.sectionTitle,
                  ),
                  const SizedBox(height: 12),
                  SmartAnalyticsPlannedVsActualSection(snapshot: snapshot),
                  const SizedBox(height: AppSpacing.section),
                  Text(
                    'Expense Records',
                    style: RenewWiseTypography.sectionTitle,
                  ),
                  const SizedBox(height: 12),
                  ExpenseTrackingSection(
                    expenseService: expenseService,
                    currency: _currency,
                    hideChartPlaceholder: true,
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

class _FinancialSummaryCard extends StatelessWidget {
  const _FinancialSummaryCard({
    required this.summary,
    required this.format,
  });

  final ExpenseSummary summary;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: RenewWisePalette.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.homeCard),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
                  color: AppColors.primary.withAlpha(24),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Financial Summary',
                style: RenewWiseTypography.sectionTitle,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SummaryMetric(label: 'Total Expenses', value: format(summary.total)),
          const SizedBox(height: 10),
          _SummaryMetric(
            label: 'Number of Expenses',
            value: '${summary.count}',
          ),
          const SizedBox(height: 10),
          _SummaryMetric(
            label: 'Largest Expense',
            value: summary.count == 0 ? '—' : format(summary.largest),
          ),
          const SizedBox(height: 10),
          _SummaryMetric(
            label: 'Average Expense',
            value: summary.count == 0 ? '—' : format(summary.average),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: RenewWiseTypography.secondary)),
        Text(
          value,
          style: RenewWiseTypography.tileEventCount.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
