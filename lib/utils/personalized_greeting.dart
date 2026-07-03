/// Time-of-day greeting helpers (Package 6A).
abstract final class PersonalizedGreeting {
  static String timeOfDayPeriod(DateTime time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  static String greeting({
    required String userName,
    DateTime? now,
  }) {
    final period = timeOfDayPeriod(now ?? DateTime.now());
    final name = userName.trim();
    if (name.isEmpty) return period;
    return '$period, $name';
  }
}
