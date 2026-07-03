import 'package:flutter/material.dart';

import 'package:renew_wise/models/life_insights_models.dart';
import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/notification_service.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/services/sharing_service.dart';
import 'package:renew_wise/screens/event_details_screen.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/utils/date_utils.dart';
import 'package:renew_wise/widgets/common/app_empty_state.dart';
import 'package:renew_wise/widgets/renewal_list_item.dart';

class StatisticsDayDetailScreen extends StatelessWidget {
  const StatisticsDayDetailScreen({
    super.key,
    required this.day,
    required this.renewalService,
    this.settingsService,
    this.reminderStateService,
    this.notificationService,
    this.eventExtrasService,
    this.sharingService,
  });

  final DayInsights day;
  final RenewalService renewalService;
  final SettingsService? settingsService;
  final ReminderStateService? reminderStateService;
  final NotificationService? notificationService;
  final EventExtrasService? eventExtrasService;
  final SharingService? sharingService;

  static Future<void> push(
    BuildContext context, {
    required DayInsights day,
    required RenewalService renewalService,
    SettingsService? settingsService,
    ReminderStateService? reminderStateService,
    NotificationService? notificationService,
    EventExtrasService? eventExtrasService,
    SharingService? sharingService,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StatisticsDayDetailScreen(
          day: day,
          renewalService: renewalService,
          settingsService: settingsService,
          reminderStateService: reminderStateService,
          notificationService: notificationService,
          eventExtrasService: eventExtrasService,
          sharingService: sharingService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = RenewalDateUtils.formatDisplayDate(day.date);
    final canOpenEvent = settingsService != null &&
        reminderStateService != null &&
        notificationService != null &&
        eventExtrasService != null;

    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.page, 8, AppSpacing.page, 32),
          children: [
            if (day.renewals.isEmpty && day.historyEntries.isEmpty)
              const AppEmptyState(
                icon: Icons.event_available_outlined,
                title: "Nothing on this day",
                subtitle: "You're all caught up — enjoy the calm.",
              )
            else ...[
              if (day.renewals.isNotEmpty) ...[
                Text(
                  'Reminders',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                ...day.renewals.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: RenewalListItem(
                      renewal: r,
                      documentCount:
                          eventExtrasService?.documentsFor(r.id).length ?? 0,
                      onTap: canOpenEvent
                          ? () => EventDetailsScreen.push(
                                context,
                                renewal: r,
                                renewalService: renewalService,
                                settingsService: settingsService!,
                                reminderStateService: reminderStateService!,
                                notificationService: notificationService!,
                                eventExtrasService: eventExtrasService!,
                                sharingService: sharingService,
                              )
                          : null,
                    ),
                  ),
                ),
              ],
              if (day.historyEntries.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Completed',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                ...day.historyEntries.map(
                  (e) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Icon(
                        Icons.check_circle_outline,
                        color: AppColors.success,
                      ),
                      title: Text(e.title),
                      subtitle: Text(e.categoryLabel),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
