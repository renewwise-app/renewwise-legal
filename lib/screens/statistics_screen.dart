import 'package:flutter/material.dart';

import 'package:renew_wise/models/renewal_currency.dart';
import 'package:renew_wise/models/smart_analytics_models.dart';
import 'package:renew_wise/services/expense_service.dart';
import 'package:renew_wise/services/goal_planner_service.dart';
import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/notification_service.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/services/sharing_service.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/utils/empty_state_guidance.dart';
import 'package:renew_wise/utils/smart_analytics_engine.dart';
import 'package:renew_wise/utils/smart_insights_presentation.dart';
import 'package:renew_wise/widgets/common/renew_wise_back_button.dart';
import 'package:renew_wise/widgets/home/home_summary_card.dart';
import 'package:renew_wise/widgets/common/app_shimmer.dart';
import 'package:renew_wise/widgets/smart_insights/smart_insights_dashboard_card.dart';
import 'package:renew_wise/widgets/smart_insights/smart_insights_dashboard_widgets.dart';
import 'package:renew_wise/screens/smart_insights/goal_planner_screen.dart';
import 'package:renew_wise/screens/smart_insights/spending_analysis_screen.dart';
import 'package:renew_wise/screens/smart_insights/this_month_screen.dart';
import 'package:renew_wise/screens/smart_insights/yearly_trend_screen.dart';

/// Smart Insights — dashboard-first financial intelligence hub.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({
    super.key,
    required this.renewalService,
    this.settingsService,
  });

  final RenewalService renewalService;
  final SettingsService? settingsService;

  static Future<void> push(
    BuildContext context, {
    required RenewalService renewalService,
    ReminderStateService? reminderStateService,
    EventExtrasService? eventExtrasService,
    SharingService? sharingService,
    SettingsService? settingsService,
    NotificationService? notificationService,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => StatisticsScreen(
          renewalService: renewalService,
          settingsService: settingsService,
        ),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: RenewWiseHomeMotion.shellFade,
      ),
    );
  }

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final GoalPlannerService _goalPlannerService = GoalPlannerService();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    widget.renewalService.addListener(_onDataChanged);
    _goalPlannerService.initialize().then((_) {
      if (mounted) {
        _goalPlannerService.addListener(_onDataChanged);
        expenseService.initialize().then((_) {
          if (mounted) {
            expenseService.addListener(_onDataChanged);
            setState(() => _ready = true);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    widget.renewalService.removeListener(_onDataChanged);
    expenseService.removeListener(_onDataChanged);
    _goalPlannerService.removeListener(_onDataChanged);
    _goalPlannerService.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  RenewalCurrency get _currency =>
      widget.settingsService?.defaultCurrency ?? RenewalCurrency.inr;

  SmartAnalyticsSnapshot get _snapshot => SmartAnalyticsEngine.compute(
        expenses: expenseService.expenses,
        renewals: widget.renewalService.renewals,
        goalSettings: _goalPlannerService.settings,
        filter: const SmartAnalyticsFilterState(),
        currency: _currency,
      );

  @override
  Widget build(BuildContext context) {
    final hPad =
        MediaQuery.sizeOf(context).width > 600 ? 32.0 : AppSpacing.page;

    return Scaffold(
      backgroundColor: RenewWisePalette.pageBackground,
      appBar: AppBar(
        backgroundColor: RenewWisePalette.pageBackground,
        surfaceTintColor: Colors.transparent,
        leading: const RenewWiseAppBarBackButton(),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 96),
              children: [
                SmartInsightsPageHeader(
                  purposeMessage: _ready &&
                          !_snapshot.hasReminderData &&
                          !_snapshot.hasExpenseData
                      ? EmptyStateGuidance.smartInsights
                      : null,
                ),
                const SizedBox(height: AppSpacing.section),
                if (!_ready)
                  Column(
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: const [
                            Expanded(child: AppDashboardCardSkeleton()),
                            SizedBox(width: 12),
                            Expanded(child: AppDashboardCardSkeleton()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: const [
                            Expanded(child: AppDashboardCardSkeleton()),
                            SizedBox(width: 12),
                            Expanded(child: AppDashboardCardSkeleton()),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: SmartInsightsDashboardCard(
                            title: 'This Month',
                            theme: HomeDashboardCardTheme.today,
                            icon: Icons.calendar_month_rounded,
                            summaryLines: SmartInsightsPresentation
                                .thisMonthSummary(
                              snapshot: _snapshot,
                              renewalService: widget.renewalService,
                            ),
                            onTap: () => SmartInsightsThisMonthScreen.push(
                              context,
                              renewalService: widget.renewalService,
                              goalPlannerService: _goalPlannerService,
                              settingsService: widget.settingsService,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SmartInsightsDashboardCard(
                            title: 'Goal Planner',
                            theme: HomeDashboardCardTheme.week,
                            icon: Icons.savings_outlined,
                            summaryLines:
                                SmartInsightsPresentation.goalPlannerSummary(
                              snapshot: _snapshot,
                              settings: _goalPlannerService.settings,
                            ),
                            onTap: () => SmartInsightsGoalPlannerScreen.push(
                              context,
                              renewalService: widget.renewalService,
                              goalPlannerService: _goalPlannerService,
                              settingsService: widget.settingsService,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: SmartInsightsDashboardCard(
                            title: 'Spending Analysis',
                            theme: HomeDashboardCardTheme.month,
                            icon: Icons.pie_chart_outline_rounded,
                            summaryLines:
                                SmartInsightsPresentation.spendingSummary(
                              snapshot: _snapshot,
                            ),
                            onTap: () =>
                                SmartInsightsSpendingAnalysisScreen.push(
                              context,
                              renewalService: widget.renewalService,
                              goalPlannerService: _goalPlannerService,
                              settingsService: widget.settingsService,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SmartInsightsDashboardCard(
                            title: 'Yearly Trend',
                            theme: HomeDashboardCardTheme.customSearch,
                            icon: Icons.bar_chart_rounded,
                            summaryLines:
                                SmartInsightsPresentation.yearlyTrendSummary(
                              snapshot: _snapshot,
                            ),
                            onTap: () => SmartInsightsYearlyTrendScreen.push(
                              context,
                              renewalService: widget.renewalService,
                              goalPlannerService: _goalPlannerService,
                              settingsService: widget.settingsService,
                            ),
                          ),
                        ),
                      ],
                    ),
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
