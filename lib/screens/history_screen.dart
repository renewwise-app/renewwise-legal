import 'package:flutter/material.dart';

import 'package:renew_wise/models/history_entry.dart';
import 'package:renew_wise/screens/history_completed_list_screen.dart';
import 'package:renew_wise/screens/history_period_screen.dart';
import 'package:renew_wise/services/notification_service.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/utils/empty_state_guidance.dart';
import 'package:renew_wise/utils/history_events_scope.dart';
import 'package:renew_wise/utils/history_stats.dart';
import 'package:renew_wise/widgets/event_list/event_list_empty_state.dart';
import 'package:renew_wise/widgets/history/history_summary_card.dart';
import 'package:renew_wise/widgets/home/home_summary_card.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({
    super.key,
    required this.renewalService,
    required this.settingsService,
    required this.notificationService,
    required this.reminderStateService,
    required this.onOpenEntry,
  });

  final RenewalService renewalService;
  final SettingsService settingsService;
  final NotificationService notificationService;
  final ReminderStateService reminderStateService;
  final void Function(HistoryEntry entry) onOpenEntry;

  void _openCompletedList(
    BuildContext context, {
    required HistoryEventsScope scope,
    required String title,
  }) {
    HistoryCompletedListScreen.push(
      context,
      title: title,
      scope: scope,
      reminderStateService: reminderStateService,
      onOpenEntry: onOpenEntry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPad =
        MediaQuery.sizeOf(context).width > 600 ? 32.0 : AppSpacing.page;

    return ListenableBuilder(
      listenable: Listenable.merge([
        reminderStateService,
        renewalService,
      ]),
      builder: (context, _) {
        final allHistory = reminderStateService.history;

        final todayEntries = HistoryEventsScopeUtils.scopedEntries(
          allHistory,
          scope: HistoryEventsScope.completedToday,
        );
        final weekEntries = HistoryEventsScopeUtils.scopedEntries(
          allHistory,
          scope: HistoryEventsScope.completedThisWeek,
        );
        final monthEntries = HistoryEventsScopeUtils.scopedEntries(
          allHistory,
          scope: HistoryEventsScope.completedThisMonth,
        );

        final todaySummary =
            HistoryEventsScopeUtils.summarize(todayEntries);
        final weekSummary = HistoryEventsScopeUtils.summarize(weekEntries);
        final monthSummary =
            HistoryEventsScopeUtils.summarize(monthEntries);

        final stats = HistoryStatsCalculator.compute(
          history: allHistory,
          activeEventCount: renewalService.upcomingCount,
        );

        return Scaffold(
          backgroundColor: RenewWisePalette.pageBackground,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 0),
                      sliver: SliverToBoxAdapter(
                        child: HistoryPageHeader(
                          weeklyCompletedCount: weekSummary.completedCount,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        hPad,
                        AppSpacing.section,
                        hPad,
                        12,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          children: [
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: HistorySummaryCard(
                                      title: 'Completed Today',
                                      summary: todaySummary,
                                      theme: HomeDashboardCardTheme.completed,
                                      icon: Icons.today_rounded,
                                      onTap: () => _openCompletedList(
                                        context,
                                        scope: HistoryEventsScope
                                            .completedToday,
                                        title: 'Completed Today',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: HistorySummaryCard(
                                      title: 'Completed This Week',
                                      summary: weekSummary,
                                      theme: HomeDashboardCardTheme.week,
                                      icon: Icons.bar_chart_rounded,
                                      onTap: () => _openCompletedList(
                                        context,
                                        scope: HistoryEventsScope
                                            .completedThisWeek,
                                        title: 'Completed This Week',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: HistorySummaryCard(
                                      title: 'Completed This Month',
                                      summary: monthSummary,
                                      theme: HomeDashboardCardTheme.month,
                                      icon: Icons.calendar_month_rounded,
                                      onTap: () => _openCompletedList(
                                        context,
                                        scope: HistoryEventsScope
                                            .completedThisMonth,
                                        title: 'Completed This Month',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: HistoryChoosePeriodCard(
                                      onTap: () => HistoryPeriodScreen.push(
                                        context,
                                        reminderStateService:
                                            reminderStateService,
                                        onOpenEntry: onOpenEntry,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (allHistory.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EventListEmptyState(
                          title: 'Nothing completed yet.',
                          subtitle: EmptyStateGuidance.history,
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 96),
                        sliver: SliverToBoxAdapter(
                          child: _CollapsedAnalyticsPanel(stats: stats),
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

class _CollapsedAnalyticsPanel extends StatelessWidget {
  const _CollapsedAnalyticsPanel({required this.stats});

  final HistoryStats stats;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RenewWisePalette.cardSurface,
      borderRadius: BorderRadius.circular(AppRadius.homeCard),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            'Optional insights',
            style: RenewWiseTypography.cardTitle.copyWith(fontSize: 15),
          ),
          subtitle: Text(
            'Tap to view completion insights',
            style: RenewWiseTypography.secondary.copyWith(
              fontSize: 15,
              height: 1.35,
            ),
          ),
          children: [
            _InsightRow(
              label: 'Completed this month',
              value: '${stats.completedThisMonth}',
            ),
            const SizedBox(height: 8),
            _InsightRow(
              label: 'Completed this year',
              value: '${stats.completedThisYear}',
            ),
            const SizedBox(height: 8),
            _InsightRow(
              label: 'Total paid (all time)',
              value: stats.formattedTotalPaid,
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: RenewWiseTypography.caption.copyWith(
              color: RenewWisePalette.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: RenewWiseTypography.tileEventCount.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
