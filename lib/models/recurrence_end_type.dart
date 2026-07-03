enum RecurrenceEndType {
  never('Never Ends'),
  endDate('End On Date'),
  occurrenceCount('After Number of Occurrences');

  const RecurrenceEndType(this.label);

  final String label;
}
