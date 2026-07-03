import 'package:flutter/material.dart';

import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/services/assistant_draft_service.dart';
import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/notification_service.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/services/sharing_service.dart';
import 'package:renew_wise/screens/event_details_screen.dart';
import 'package:renew_wise/screens/add_renewal_screen.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/utils/dashboard_list_utils.dart';
import 'package:renew_wise/utils/event_list_sort.dart';
import 'package:renew_wise/utils/home_events_scope.dart';
import 'package:renew_wise/utils/empty_state_guidance.dart';
import 'package:renew_wise/widgets/event_list/event_list_empty_state.dart';
import 'package:renew_wise/widgets/event_list/event_list_header.dart';
import 'package:renew_wise/widgets/event_list/event_list_reminder_card.dart';

/// Unified reminder list for Today, This Week, This Month, and Custom Search.
class HomeEventsListScreen extends StatefulWidget {
  const HomeEventsListScreen({
    super.key,
    required this.title,
    required this.scope,
    required this.renewalService,
    required this.settingsService,
    required this.reminderStateService,
    required this.notificationService,
    required this.eventExtrasService,
    this.sharingService,
    this.assistantDraftService,
    this.fromDate,
    this.toDate,
  });

  final String title;
  final HomeEventsScope scope;
  final RenewalService renewalService;
  final SettingsService settingsService;
  final ReminderStateService reminderStateService;
  final NotificationService notificationService;
  final EventExtrasService eventExtrasService;
  final SharingService? sharingService;
  final AssistantDraftService? assistantDraftService;
  final DateTime? fromDate;
  final DateTime? toDate;

  static Future<void> push(
    BuildContext context, {
    required String title,
    required HomeEventsScope scope,
    required RenewalService renewalService,
    required SettingsService settingsService,
    required ReminderStateService reminderStateService,
    required NotificationService notificationService,
    required EventExtrasService eventExtrasService,
    SharingService? sharingService,
    AssistantDraftService? assistantDraftService,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => HomeEventsListScreen(
          title: title,
          scope: scope,
          renewalService: renewalService,
          settingsService: settingsService,
          reminderStateService: reminderStateService,
          notificationService: notificationService,
          eventExtrasService: eventExtrasService,
          sharingService: sharingService,
          assistantDraftService: assistantDraftService,
          fromDate: fromDate,
          toDate: toDate,
        ),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  @override
  State<HomeEventsListScreen> createState() => _HomeEventsListScreenState();
}

class _HomeEventsListScreenState extends State<HomeEventsListScreen> {
  EventListSortOption _sort = EventListSortOption.dueSoonest;

  String get _pageTitle => switch (widget.scope) {
        HomeEventsScope.today => 'Today',
        HomeEventsScope.thisWeek => 'This Week',
        HomeEventsScope.thisMonth => 'This Month',
        HomeEventsScope.customRange => 'Custom Search',
      };

  ({String title, String subtitle}) _emptyState(bool hasReminders) =>
      switch (widget.scope) {
        HomeEventsScope.today => (
            title: 'Nothing due today.',
            subtitle: EmptyStateGuidance.todaySubtitle(
              hasReminders: hasReminders,
            ),
          ),
        HomeEventsScope.thisWeek => (
            title: 'No reminders this week.',
            subtitle: hasReminders
                ? "It's going to be a peaceful week."
                : 'Add your first reminder and RenewWise will help you stay ahead of important renewals and events.',
          ),
        HomeEventsScope.thisMonth => (
            title: 'Nothing scheduled this month.',
            subtitle: EmptyStateGuidance.thisMonthSubtitle(
              hasReminders: hasReminders,
            ),
          ),
        HomeEventsScope.customRange => (
            title: 'No reminders found.',
            subtitle: EmptyStateGuidance.customSearchSubtitle(
              hasReminders: hasReminders,
            ),
          ),
      };

  List<Renewal> _scopedRenewals() {
    return HomeEventsScopeUtils.scopedRenewals(
      widget.renewalService,
      scope: widget.scope,
      fromDate: widget.fromDate,
      toDate: widget.toDate,
    );
  }

  List<Renewal> _displayList() {
    final list = _scopedRenewals();
    EventListSortUtils.sort(list, _sort);
    return list;
  }

  void _openAddReminder() {
    AddRenewalScreen.push(
      context,
      renewalService: widget.renewalService,
      defaultCurrency: widget.settingsService.defaultCurrency,
      defaultReminderTimeMinutes:
          widget.settingsService.defaultReminderTimeMinutes,
    );
  }

  Future<void> _showSortSheet() async {
    final picked = await showModalBottomSheet<EventListSortOption>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  'Sort by',
                  style: RenewWiseTypography.cardTitle,
                ),
              ),
              ...EventListSortOption.values.map(
                (option) => ListTile(
                  title: Text(
                    option.label,
                    style: RenewWiseTypography.tileEventCount.copyWith(
                      fontWeight:
                          _sort == option ? FontWeight.w600 : FontWeight.w500,
                      color: _sort == option
                          ? AppColors.primary
                          : const Color(0xFF334155),
                    ),
                  ),
                  trailing: _sort == option
                      ? Icon(Icons.check_rounded, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(ctx, option),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _sort = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.renewalService,
      builder: (context, _) {
        final renewals = _displayList();
        final scoped = _scopedRenewals();
        final currency = widget.renewalService.primaryCurrency;
        final dueTotal = DashboardListUtils.totalAmount(scoped);
        final dueLabel =
            dueTotal > 0 ? currency.formatAmount(dueTotal) : null;
        final hasReminders = widget.renewalService.renewals.isNotEmpty;
        final empty = _emptyState(hasReminders);

        return Scaffold(
          backgroundColor: RenewWisePalette.listBackground,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EventListHeader(
                      title: _pageTitle,
                      eventCount: scoped.length,
                      dueLabel: dueLabel,
                      onBack: () => Navigator.of(context).pop(),
                      onSort: _showSortSheet,
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: renewals.isEmpty
                          ? EventListEmptyState(
                              title: empty.title,
                              subtitle: empty.subtitle,
                              onAddReminder: _openAddReminder,
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.page,
                                0,
                                AppSpacing.page,
                                AppSpacing.xxl,
                              ),
                              itemCount: renewals.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final renewal = renewals[index];
                                return EventListReminderCard(
                                  renewal: renewal,
                                  onTap: () => EventDetailsScreen.push(
                                    context,
                                    renewal: renewal,
                                    renewalService: widget.renewalService,
                                    settingsService: widget.settingsService,
                                    reminderStateService:
                                        widget.reminderStateService,
                                    notificationService:
                                        widget.notificationService,
                                    eventExtrasService:
                                        widget.eventExtrasService,
                                    sharingService: widget.sharingService,
                                  ),
                                );
                              },
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
