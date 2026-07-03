/// Friendly empty-state copy for the no-reminder / no-data experience (NR-2).
abstract final class EmptyStateGuidance {
  static const smartInsights =
      'Understand your expenses, renewal trends and financial habits as you use RenewWise.';

  static const spendingAnalysis =
      'Track your expenses to understand where your money goes.';

  static const yearlyTrend =
      'Your yearly expense trend will appear as you continue using RenewWise.';

  static const documentVault =
      'Store important documents together with your reminders for quick access whenever you need them.';

  static const history =
      'Completed reminders will appear here so you can review your progress anytime.';

  static const goalPlannerIncome =
      'Add your income to receive realistic savings recommendations.';

  static const smartLock =
      "Protect your reminders and personal documents using your phone's built-in security.";

  static const customSearchNoReminders =
      'Add your first reminder before using Custom Search.';

  static String todaySubtitle({required bool hasReminders}) {
    if (!hasReminders) {
      return "You're all caught up.\n\nAdd your first reminder and RenewWise will help you stay ahead of important renewals and events.";
    }
    return "You're all caught up.";
  }

  static String thisMonthSubtitle({required bool hasReminders}) {
    if (!hasReminders) {
      return 'Monthly planning helps you prepare for upcoming renewals and expenses. Add a reminder to get started.';
    }
    return 'Add a reminder whenever you\'re ready.';
  }

  static String customSearchSubtitle({required bool hasReminders}) {
    if (!hasReminders) {
      return customSearchNoReminders;
    }
    return 'Try selecting another period or create a new reminder.';
  }
}
