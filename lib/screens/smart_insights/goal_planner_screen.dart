import 'package:flutter/material.dart';

import 'package:renew_wise/models/renewal_currency.dart';
import 'package:renew_wise/models/smart_analytics_models.dart';
import 'package:renew_wise/services/expense_service.dart';
import 'package:renew_wise/services/goal_planner_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/utils/feature_purpose_messaging.dart';
import 'package:renew_wise/utils/smart_analytics_engine.dart';
import 'package:renew_wise/widgets/common/feature_purpose_subtitle.dart';
import 'package:renew_wise/widgets/smart_insights/goal_planner_card.dart';
import 'package:renew_wise/widgets/smart_insights/smart_analytics_widgets.dart';

class SmartInsightsGoalPlannerScreen extends StatefulWidget {
  const SmartInsightsGoalPlannerScreen({
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
        builder: (_) => SmartInsightsGoalPlannerScreen(
          renewalService: renewalService,
          goalPlannerService: goalPlannerService,
          settingsService: settingsService,
        ),
      ),
    );
  }

  @override
  State<SmartInsightsGoalPlannerScreen> createState() =>
      _SmartInsightsGoalPlannerScreenState();
}

class _SmartInsightsGoalPlannerScreenState
    extends State<SmartInsightsGoalPlannerScreen> {
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
        filter: const SmartAnalyticsFilterState(),
        currency: _currency,
      );

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    final hPad =
        MediaQuery.sizeOf(context).width > 600 ? 32.0 : AppSpacing.page;

    return Scaffold(
      backgroundColor: RenewWisePalette.pageBackground,
      appBar: AppBar(
        backgroundColor: RenewWisePalette.pageBackground,
        surfaceTintColor: Colors.transparent,
        title: const Text('Goal Planner'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 96),
              children: [
                Text(
                  'Savings Planner',
                  style: RenewWiseTypography.screenTitle.copyWith(fontSize: 26),
                ),
                const SizedBox(height: 8),
                const FeaturePurposeSubtitle(FeaturePurposeMessaging.goalPlanner),
                const SizedBox(height: AppSpacing.section),
                SmartAnalyticsGoalProgressSection(snapshot: snapshot),
                const SizedBox(height: AppSpacing.section),
                GoalPlannerSection(
                  renewalService: widget.renewalService,
                  goalPlannerService: widget.goalPlannerService,
                  currency: _currency,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
