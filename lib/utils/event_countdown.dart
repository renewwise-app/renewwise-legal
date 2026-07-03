import 'package:flutter/material.dart';

import 'package:renew_wise/theme/app_theme.dart';

abstract final class EventCountdownUtils {
  static String label(int daysRemaining) {
    if (daysRemaining < 0) {
      final n = daysRemaining.abs();
      return n == 1 ? 'Overdue by 1 Day' : 'Overdue by $n Days';
    }
    if (daysRemaining == 0) return 'Expires Today';
    if (daysRemaining == 1) return 'Expires Tomorrow';
    return 'Expires in $daysRemaining Days';
  }

  /// Green: comfortable · Amber: soon · Red: overdue/urgent
  static Color color(int daysRemaining) {
    if (daysRemaining < 0) return AppColors.critical;
    if (daysRemaining <= 7) return AppColors.gold;
    return AppColors.primary;
  }

  static Color backgroundTint(int daysRemaining) =>
      color(daysRemaining).withAlpha(20);
}
