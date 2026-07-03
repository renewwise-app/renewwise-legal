import 'package:flutter/material.dart';

import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/utils/home_events_scope.dart';

/// Visual status chip shown on home summary cards.
class HomeSummaryBadge {
  const HomeSummaryBadge({
    required this.label,
    required this.dotColor,
    required this.backgroundColor,
  });

  final String label;
  final Color dotColor;
  final Color backgroundColor;
}

/// Presentation-only badge selection for home dashboard cards.
abstract final class HomeSummaryBadgeUtils {
  static HomeSummaryBadge? forScope({
    required HomeEventsScope scope,
    required List<Renewal> renewals,
    required int highPriorityCount,
  }) {
    switch (scope) {
      case HomeEventsScope.today:
        final overdue = renewals.where((r) => r.isOverdue).length;
        if (overdue > 0) {
          return HomeSummaryBadge(
            label: overdue == 1 ? 'Overdue' : '$overdue Overdue',
            dotColor: AppColors.critical,
            backgroundColor: AppColors.critical.withAlpha(28),
          );
        }
        if (renewals.isNotEmpty) {
          return HomeSummaryBadge(
            label: 'Due Today',
            dotColor: AppColors.primary,
            backgroundColor: AppColors.primary.withAlpha(28),
          );
        }
        return null;
      case HomeEventsScope.thisWeek:
        if (highPriorityCount > 0) {
          return HomeSummaryBadge(
            label: highPriorityCount == 1
                ? '1 High Priority'
                : '$highPriorityCount High Priority',
            dotColor: const Color(0xFFEA580C),
            backgroundColor: const Color(0xFFEA580C).withAlpha(28),
          );
        }
        return null;
      case HomeEventsScope.thisMonth:
        final upcoming =
            renewals.where((r) => !r.isOverdue && r.daysRemaining > 0).length;
        if (upcoming > 0) {
          return HomeSummaryBadge(
            label: upcoming == 1 ? '1 Upcoming' : '$upcoming Upcoming',
            dotColor: const Color(0xFF2563EB),
            backgroundColor: const Color(0xFF2563EB).withAlpha(28),
          );
        }
        return null;
      case HomeEventsScope.customRange:
        return null;
    }
  }
}
