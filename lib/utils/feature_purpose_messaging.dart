/// Benefit-oriented purpose copy for major RenewWise features (DR-6).
abstract final class FeaturePurposeMessaging {
  static const homeWelcomeMessages = [
    'Stay organised, one reminder at a time.',
    'Your important moments, all in one place.',
    'Peace of mind starts with planning.',
    "Let's make today easier.",
  ];

  static const smartInsights =
      'Understand your finances and commitments at a glance.';

  static const goalPlanner =
      'Build a realistic savings plan around your actual expenses.';

  static const spendingAnalysis =
      'See where your money goes and identify spending patterns.';

  static const yearlyTrend =
      'Prepare ahead by understanding your yearly expenses.';

  static const documents =
      'Keep important files together with the reminders they belong to.';

  static const history =
      'Review completed reminders and track your progress.';

  static const addReminder =
      'Create reminders that match your daily life and future plans.';

  static const settings =
      'Personalise RenewWise and manage your privacy preferences.';

  static const backup =
      'Your data is yours. Backup is always your choice.';

  static String homeWelcome(int rotationIndex) {
    if (homeWelcomeMessages.isEmpty) return '';
    final index = rotationIndex % homeWelcomeMessages.length;
    return homeWelcomeMessages[index];
  }
}
