import 'package:flutter/material.dart';

import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/theme/app_theme.dart';

class TodayInsight {
  const TodayInsight({
    required this.emoji,
    required this.message,
    required this.tint,
    required this.priority,
  });

  final String emoji;
  final String message;
  final Color tint;
  final int priority;
}

abstract final class RenewWiseInsights {
  static List<TodayInsight> buildCandidates(
    RenewalService service,
    EventExtrasService extras,
  ) {
    final renewals = service.renewals;
    final items = <TodayInsight>[];

    final critical = service.criticalRenewals.length;
    if (critical == 0) {
      items.add(
        TodayInsight(
          emoji: '🟢',
          message: 'You have no urgent reminders today.',
          tint: AppColors.primaryGreen,
          priority: 10,
        ),
      );
    }

    final weekDue = renewals
        .where((r) {
          final d = r.daysRemaining;
          return d >= 0 && d <= 7;
        })
        .length;
    if (weekDue > 0) {
      items.add(
        TodayInsight(
          emoji: '🟡',
          message: weekDue == 1
              ? 'One reminder is due this week.'
              : '$weekDue reminders are due this week.',
          tint: AppColors.gold,
          priority: 40,
        ),
      );
    }

    final overdue = renewals.where((r) => r.isOverdue).length;
    if (overdue > 0) {
      items.add(
        TodayInsight(
          emoji: '🔴',
          message: overdue == 1
              ? 'One reminder is overdue.'
              : '$overdue reminders are overdue.',
          tint: AppColors.critical,
          priority: 90,
        ),
      );
    }

    Renewal? nearestImportant;
    for (final r in renewals) {
      if (r.isOverdue) continue;
      if (nearestImportant == null ||
          r.renewalDate.isBefore(nearestImportant.renewalDate)) {
        nearestImportant = r;
      }
    }
    if (nearestImportant != null) {
      final days = nearestImportant.daysRemaining;
      if (days >= 0 && days <= 45) {
        items.add(
          TodayInsight(
            emoji: '🔴',
            message: 'Your ${nearestImportant.title} expires in $days ${days == 1 ? 'day' : 'days'}.',
            tint: days <= 7 ? AppColors.critical : AppColors.gold,
            priority: days <= 7 ? 85 : 55,
          ),
        );
      }
    }

    final monthTotal = service.dueThisMonthTotal;
    if (monthTotal > 0) {
      items.add(
        TodayInsight(
          emoji: '💰',
          message:
              '${service.primaryCurrency.formatAmount(monthTotal)} is due this month.',
          tint: AppColors.teal,
          priority: 50,
        ),
      );
    }

    final noDocs = renewals
        .where((r) => extras.documentsFor(r.id).isEmpty)
        .length;
    if (noDocs > 0) {
      items.add(
        TodayInsight(
          emoji: '📄',
          message: noDocs == 1
              ? 'One reminder has no documents attached.'
              : '$noDocs reminders have no documents attached.',
          tint: AppColors.gold,
          priority: 35,
        ),
      );
    }

    if (items.isEmpty) {
      items.add(
        TodayInsight(
          emoji: '🟢',
          message: 'You have no urgent reminders today.',
          tint: AppColors.primaryGreen,
          priority: 0,
        ),
      );
    }

    items.sort((a, b) => b.priority.compareTo(a.priority));
    return items;
  }

  static TodayInsight pickForSession(
    List<TodayInsight> candidates,
    int rotationIndex,
  ) {
    if (candidates.isEmpty) {
      return TodayInsight(
        emoji: '🟢',
        message: 'You have no urgent reminders today.',
        tint: AppColors.primaryGreen,
        priority: 0,
      );
    }
    final top = candidates.take(5).toList();
    return top[rotationIndex % top.length];
  }
}

abstract final class DashboardMotivation {
  static const _messages = [
    'Everything is under control.',
    "You're fully prepared this week.",
    'Nice work.',
    'No critical reminders today.',
    'RenewWise is quietly keeping watch.',
    'Your reminders are in good shape.',
  ];

  static String? messageFor({
    required RenewalService service,
    required int dayOfYear,
    required int sessionIndex,
  }) {
    if (service.renewals.isEmpty) return null;
    if (service.criticalRenewals.isNotEmpty && sessionIndex.isOdd) {
      return null;
    }
    if (dayOfYear % 3 != sessionIndex % 3) return null;
    return _messages[(dayOfYear + sessionIndex) % _messages.length];
  }
}
