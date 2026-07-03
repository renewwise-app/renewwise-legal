/// Smart notification priority tiers for RenewWise reminders.
enum NotificationLevel {
  low('Low'),
  medium('Medium'),
  high('High'),
  critical('Critical');

  const NotificationLevel(this.label);
  final String label;
}
