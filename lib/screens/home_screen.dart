import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:renew_wise/models/smart_analytics_models.dart';
import 'package:renew_wise/screens/custom_search_screen.dart';
import 'package:renew_wise/screens/home_events_list_screen.dart';
import 'package:renew_wise/screens/add_renewal_screen.dart';
import 'package:renew_wise/screens/settings_screen.dart';
import 'package:renew_wise/screens/statistics_screen.dart';
import 'package:renew_wise/services/assistant_draft_service.dart';
import 'package:renew_wise/services/backup/backup_service.dart';
import 'package:renew_wise/services/developer_service.dart';
import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/expense_service.dart';
import 'package:renew_wise/services/goal_planner_service.dart';
import 'package:renew_wise/services/notification_service.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/services/sharing_service.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/utils/feature_purpose_messaging.dart';
import 'package:renew_wise/utils/home_events_scope.dart';
import 'package:renew_wise/utils/personalized_greeting.dart';
import 'package:renew_wise/utils/smart_analytics_engine.dart';
import 'package:renew_wise/utils/smart_insights_presentation.dart';
import 'package:renew_wise/widgets/home/home_brand_header.dart';
import 'package:renew_wise/widgets/home/home_micro_interactions.dart';
import 'package:renew_wise/widgets/home/home_summary_card.dart';
import 'package:renew_wise/widgets/reminder/missed_reminders_banner.dart';
import 'package:renew_wise/widgets/smart_insights/smart_insights_dashboard_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.renewalService,
    required this.settingsService,
    required this.notificationService,
    required this.reminderStateService,
    required this.assistantDraftService,
    required this.eventExtrasService,
    this.developerService,
    this.onOpenHistory,
    this.onOpenVault,
    this.backupService,
    this.sharingService,
  });

  final RenewalService renewalService;
  final SettingsService settingsService;
  final NotificationService notificationService;
  final ReminderStateService reminderStateService;
  final AssistantDraftService assistantDraftService;
  final EventExtrasService eventExtrasService;
  final DeveloperService? developerService;
  final BackupService? backupService;
  final SharingService? sharingService;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenVault;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GoalPlannerService _goalPlannerService = GoalPlannerService();
  late final String _welcomePurposeMessage;

  @override
  void initState() {
    super.initState();
    _welcomePurposeMessage = FeaturePurposeMessaging.homeWelcome(
      widget.settingsService.motivationSessionIndex,
    );
    _goalPlannerService.initialize();
    expenseService.addListener(_rebuild);
    _goalPlannerService.addListener(_rebuild);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.reminderStateService.evaluateMissedReminders(
        widget.renewalService.renewals,
      );
      widget.settingsService.advanceInsightRotation();
    });
  }

  @override
  void dispose() {
    expenseService.removeListener(_rebuild);
    _goalPlannerService.removeListener(_rebuild);
    _goalPlannerService.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  String _greeting() {
    return PersonalizedGreeting.greeting(
      userName: widget.settingsService.userName,
    );
  }

  SmartAnalyticsSnapshot _insightsSnapshot(RenewalService service) {
    return SmartAnalyticsEngine.compute(
      expenses: expenseService.expenses,
      renewals: service.renewals,
      goalSettings: _goalPlannerService.settings,
      filter: const SmartAnalyticsFilterState(),
      currency: widget.settingsService.defaultCurrency,
    );
  }

  void _openAddReminder(RenewalService service) {
    AddRenewalScreen.push(
      context,
      renewalService: service,
      defaultCurrency: widget.settingsService.defaultCurrency,
      defaultReminderTimeMinutes:
          widget.settingsService.defaultReminderTimeMinutes,
      defaultAlertStyle: widget.settingsService.defaultAlertStyle,
    );
  }

  void _openEventsList({
    required RenewalService service,
    required String title,
    required HomeEventsScope scope,
  }) {
    HomeEventsListScreen.push(
      context,
      title: title,
      scope: scope,
      renewalService: service,
      settingsService: widget.settingsService,
      reminderStateService: widget.reminderStateService,
      notificationService: widget.notificationService,
      eventExtrasService: widget.eventExtrasService,
      sharingService: widget.sharingService,
      assistantDraftService: widget.assistantDraftService,
    );
  }

  void _openSmartInsights(RenewalService service) {
    StatisticsScreen.push(
      context,
      renewalService: service,
      reminderStateService: widget.reminderStateService,
      eventExtrasService: widget.eventExtrasService,
      sharingService: widget.sharingService,
      settingsService: widget.settingsService,
      notificationService: widget.notificationService,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPad = MediaQuery.sizeOf(context).width > 600 ? 32.0 : AppSpacing.page;

    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.renewalService,
        widget.settingsService,
        widget.reminderStateService,
      ]),
      builder: (context, _) {
        final service = widget.renewalService;
        final currency = service.primaryCurrency;
        final missedRenewals = widget.reminderStateService.activeMissedRenewals(
          service.renewals,
        );
        final todayRenewals = HomeEventsScopeUtils.scopedRenewals(
          service,
          scope: HomeEventsScope.today,
        );
        final monthRenewals = HomeEventsScopeUtils.scopedRenewals(
          service,
          scope: HomeEventsScope.thisMonth,
        );
        final todaySummary = HomeEventsScopeUtils.summarize(todayRenewals);
        final monthSummary = HomeEventsScopeUtils.summarize(monthRenewals);
        final insightsSnapshot = _insightsSnapshot(service);
        final insightsSummary = SmartInsightsPresentation.homeCardInsight(
          snapshot: insightsSnapshot,
        );

        return Scaffold(
          backgroundColor: RenewWisePalette.pageBackground,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: RenewWisePalette.pageBackground,
            surfaceTintColor: Colors.transparent,
            title: const SizedBox.shrink(),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  color: RenewWisePalette.textPrimary,
                ),
                tooltip: 'Settings',
                onPressed: () => SettingsScreen.push(
                  context,
                  settingsService: widget.settingsService,
                  renewalService: service,
                  notificationService: widget.notificationService,
                  eventExtrasService: widget.eventExtrasService,
                  reminderStateService: widget.reminderStateService,
                  backupService: widget.backupService,
                  sharingService: widget.sharingService,
                  developerService:
                      kReleaseMode ? null : widget.developerService,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          floatingActionButton: HomeBreathingFab(
            onPressed: () => _openAddReminder(service),
            child: const Icon(Icons.add_rounded, size: 30),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 0),
                      sliver: SliverToBoxAdapter(
                        child: HomeBrandHeader(
                          greeting: _greeting(),
                          todayEventCount: todaySummary.eventCount,
                          welcomePurposeMessage: _welcomePurposeMessage,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(hPad, AppSpacing.section, hPad, 96),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          children: [
                            MissedRemindersBanner(
                              renewals: missedRenewals,
                              renewalService: service,
                              settingsService: widget.settingsService,
                              reminderStateService: widget.reminderStateService,
                              notificationService: widget.notificationService,
                            ),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: HomeSummaryCard(
                                      title: 'Today',
                                      summary: todaySummary,
                                      currency: currency,
                                      scope: HomeEventsScope.today,
                                      renewals: todayRenewals,
                                      theme: HomeDashboardCardTheme.today,
                                      icon: Icons.today_rounded,
                                      onTap: () => _openEventsList(
                                        service: service,
                                        title: "Today's Events",
                                        scope: HomeEventsScope.today,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: HomeSummaryCard(
                                      title: 'This Month',
                                      summary: monthSummary,
                                      currency: currency,
                                      scope: HomeEventsScope.thisMonth,
                                      renewals: monthRenewals,
                                      theme: HomeDashboardCardTheme.month,
                                      icon: Icons.calendar_month_rounded,
                                      onTap: () => _openEventsList(
                                        service: service,
                                        title: 'This Month Events',
                                        scope: HomeEventsScope.thisMonth,
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
                                    child: HomeCustomSearchCard(
                                      onTap: () => CustomSearchScreen.push(
                                        context,
                                        renewalService: service,
                                        settingsService:
                                            widget.settingsService,
                                        reminderStateService:
                                            widget.reminderStateService,
                                        notificationService:
                                            widget.notificationService,
                                        eventExtrasService:
                                            widget.eventExtrasService,
                                        sharingService: widget.sharingService,
                                        assistantDraftService:
                                            widget.assistantDraftService,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: SmartInsightsDashboardCard(
                                      title: 'Smart Insights',
                                      theme: HomeDashboardCardTheme.week,
                                      icon: Icons.insights_outlined,
                                      summaryLines: [insightsSummary],
                                      onTap: () => _openSmartInsights(service),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
