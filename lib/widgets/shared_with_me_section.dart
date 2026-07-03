import 'package:flutter/material.dart';

import 'package:renew_wise/screens/shared_events_screen.dart';
import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/notification_service.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/services/sharing_service.dart';
import 'package:renew_wise/theme/app_theme.dart';

/// Home section — Shared With Me (does not modify the 4 dashboard cards).
class SharedWithMeSection extends StatelessWidget {
  const SharedWithMeSection({
    super.key,
    required this.sharingService,
    required this.renewalService,
    required this.settingsService,
    required this.reminderStateService,
    required this.notificationService,
    required this.eventExtrasService,
  });

  final SharingService sharingService;
  final RenewalService renewalService;
  final SettingsService settingsService;
  final ReminderStateService reminderStateService;
  final NotificationService notificationService;
  final EventExtrasService eventExtrasService;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([sharingService, renewalService]),
      builder: (context, _) {
        final all = renewalService.renewals;
        final sharedWithMe = sharingService.sharedWithMeEvents(all);
        final ownedShared = sharingService.ownedSharedEvents(all);
        final totalShared = all.where((r) => sharingService.isShared(r.id)).length;
        final pending = sharingService.pendingActionsCount(all);
        final recent = sharingService.recentlyUpdatedShared(all, limit: 3);

        if (totalShared == 0) {
          return _EmptySharedCard(
            onLearnMore: () => SharedEventsScreen.push(
              context,
              sharingService: sharingService,
              renewalService: renewalService,
              settingsService: settingsService,
              reminderStateService: reminderStateService,
              notificationService: notificationService,
              eventExtrasService: eventExtrasService,
            ),
          );
        }

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => SharedEventsScreen.push(
              context,
              sharingService: sharingService,
              renewalService: renewalService,
              settingsService: settingsService,
              reminderStateService: reminderStateService,
              notificationService: notificationService,
              eventExtrasService: eventExtrasService,
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.groups_outlined,
                          color: AppColors.teal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Shared With Me',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '$totalShared shared · ${sharedWithMe.length} with you',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatChip(
                        icon: Icons.event_outlined,
                        label: '${sharedWithMe.length + ownedShared.length} events',
                      ),
                      if (pending > 0)
                        _StatChip(
                          icon: Icons.notifications_active_outlined,
                          label: '$pending pending',
                          accent: AppColors.gold,
                        ),
                      if (recent.isNotEmpty)
                        _StatChip(
                          icon: Icons.update_rounded,
                          label: '${recent.length} recent',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptySharedCard extends StatelessWidget {
  const _EmptySharedCard({required this.onLearnMore});

  final VoidCallback onLearnMore;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.groups_outlined,
                    color: AppColors.teal,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sharing stays private for now',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'When you share reminders with people you trust, they will appear here.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onLearnMore,
              child: const Text('Explore Sharing'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    this.accent,
  });

  final IconData icon;
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.teal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
