enum RenewalStatus {
  upcoming('Upcoming'),
  paid('Paid'),
  overdue('Overdue'),
  cancelled('Cancelled');

  const RenewalStatus(this.label);

  final String label;
}
