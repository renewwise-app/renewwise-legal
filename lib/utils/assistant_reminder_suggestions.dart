import 'package:renew_wise/models/assistant_draft.dart';

abstract final class AssistantReminderSuggestions {
  static List<int> forCategory(AssistantCategoryOption? category) {
    if (category == null) return const [30, 7, 1];
    return switch (category.id) {
      'passport' => const [30, 15, 7, 1],
      'insurance' => const [30, 7, 1],
      'driving_licence' => const [30, 15],
      'medical' => const [7, 1],
      'emi' => const [7, 3, 1],
      'subscription' => const [7, 1],
      _ => const [30, 7, 1],
    };
  }

  static String labelFor(AssistantCategoryOption? category) {
    if (category == null) return 'Suggested reminders';
    return switch (category.id) {
      'passport' => 'Passport reminders',
      'insurance' => 'Insurance reminders',
      'driving_licence' => 'Driving Licence reminders',
      'medical' => 'Medical — customize as needed',
      _ => 'Smart suggestions',
    };
  }
}

abstract final class AssistantEncouragements {
  static const messages = [
    "Let's get this set up.",
    "You're doing great.",
    'Almost there.',
    'This will only take a minute.',
    'RenewWise is getting ready.',
    'Just one more thing.',
  ];

  static String forStepIndex(int index) =>
      messages[index % messages.length];
}
