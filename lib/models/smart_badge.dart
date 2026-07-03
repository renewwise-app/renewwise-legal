import 'package:flutter/material.dart';

import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/renewal_priority.dart';
import 'package:renew_wise/models/renewal_status.dart';
import 'package:renew_wise/models/repeat_cycle.dart';
import 'package:renew_wise/models/reminder_state.dart';
import 'package:renew_wise/theme/app_theme.dart';

/// Offline smart badges derived from renewal + context.
enum SmartBadgeKind {
  noDocument('No Document', Icons.description_outlined),
  recurring('Recurring', Icons.repeat_rounded),
  highValue('High Value', Icons.payments_outlined),
  critical('Critical', Icons.priority_high_rounded),
  overdue('Overdue', Icons.warning_amber_rounded),
  today('Today', Icons.today_outlined),
  upcoming('Upcoming', Icons.schedule_outlined),
  completed('Completed', Icons.check_circle_outline);

  const SmartBadgeKind(this.label, this.icon);

  final String label;
  final IconData icon;

  Color get color => switch (this) {
        SmartBadgeKind.noDocument => AppColors.gold,
        SmartBadgeKind.recurring => AppColors.teal,
        SmartBadgeKind.highValue => AppColors.primary,
        SmartBadgeKind.critical => AppColors.critical,
        SmartBadgeKind.overdue => AppColors.critical,
        SmartBadgeKind.today => AppColors.gold,
        SmartBadgeKind.upcoming => AppColors.primary,
        SmartBadgeKind.completed => AppColors.success,
      };
}

abstract final class SmartBadgeResolver {
  static const _highValueThreshold = 10000.0;

  static List<SmartBadgeKind> forRenewal(
    Renewal renewal, {
    int documentCount = 0,
    ReminderState? reminderState,
    bool includeTiming = true,
  }) {
    if (reminderState?.completed == true ||
        renewal.status == RenewalStatus.paid) {
      return const [SmartBadgeKind.completed];
    }

    final badges = <SmartBadgeKind>[];

    if (renewal.isOverdue) {
      badges.add(SmartBadgeKind.overdue);
    } else if (includeTiming) {
      final days = renewal.daysRemaining;
      if (days == 0) {
        badges.add(SmartBadgeKind.today);
      } else if (days > 0 && days <= 30) {
        badges.add(SmartBadgeKind.upcoming);
      }
    }

    if (renewal.priority == RenewalPriority.critical) {
      badges.add(SmartBadgeKind.critical);
    }

    if (renewal.repeatCycle != RepeatCycle.oneTime) {
      badges.add(SmartBadgeKind.recurring);
    }

    if (renewal.paymentRequired &&
        renewal.amount != null &&
        renewal.amount! >= _highValueThreshold) {
      badges.add(SmartBadgeKind.highValue);
    }

    if (documentCount == 0) {
      badges.add(SmartBadgeKind.noDocument);
    }

    return badges;
  }
}
