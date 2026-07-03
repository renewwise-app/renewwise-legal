enum RepeatCycle {
  oneTime('Once'),
  hourly('Hourly'),
  daily('Daily'),
  weekdays('Weekdays'),
  weekly('Weekly'),
  monthly('Monthly'),
  quarterly('Quarterly'),
  halfYearly('Half Yearly'),
  yearly('Yearly'),
  custom('Custom');

  const RepeatCycle(this.label);

  final String label;
}
