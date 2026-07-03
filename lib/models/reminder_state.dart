/// Per-event reminder metadata stored outside the SQLite schema.
class ReminderState {
  const ReminderState({
    this.lastReminderSent,
    this.acknowledged = false,
    this.completed = false,
    this.snoozedUntil,
    this.nextReminder,
    this.missed = false,
    this.missedViewed = false,
    this.completionDate,
    this.completionMethod,
  });

  final DateTime? lastReminderSent;
  final bool acknowledged;
  final bool completed;
  final DateTime? snoozedUntil;
  final DateTime? nextReminder;
  final bool missed;
  final bool missedViewed;
  final DateTime? completionDate;
  final String? completionMethod;

  ReminderState copyWith({
    DateTime? lastReminderSent,
    bool? acknowledged,
    bool? completed,
    DateTime? snoozedUntil,
    bool clearSnoozedUntil = false,
    DateTime? nextReminder,
    bool? missed,
    bool? missedViewed,
    DateTime? completionDate,
    bool clearCompletionDate = false,
    String? completionMethod,
    bool clearCompletionMethod = false,
  }) {
    return ReminderState(
      lastReminderSent: lastReminderSent ?? this.lastReminderSent,
      acknowledged: acknowledged ?? this.acknowledged,
      completed: completed ?? this.completed,
      snoozedUntil:
          clearSnoozedUntil ? null : (snoozedUntil ?? this.snoozedUntil),
      nextReminder: nextReminder ?? this.nextReminder,
      missed: missed ?? this.missed,
      missedViewed: missedViewed ?? this.missedViewed,
      completionDate:
          clearCompletionDate ? null : (completionDate ?? this.completionDate),
      completionMethod: clearCompletionMethod
          ? null
          : (completionMethod ?? this.completionMethod),
    );
  }

  Map<String, dynamic> toJson() => {
        if (lastReminderSent != null)
          'lastReminderSent': lastReminderSent!.toIso8601String(),
        'acknowledged': acknowledged,
        'completed': completed,
        if (snoozedUntil != null)
          'snoozedUntil': snoozedUntil!.toIso8601String(),
        if (nextReminder != null)
          'nextReminder': nextReminder!.toIso8601String(),
        'missed': missed,
        'missedViewed': missedViewed,
        if (completionDate != null)
          'completionDate': completionDate!.toIso8601String(),
        if (completionMethod != null) 'completionMethod': completionMethod,
      };

  factory ReminderState.fromJson(Map<String, dynamic> json) {
    DateTime? parse(String? key) {
      final v = json[key];
      if (v is! String) return null;
      return DateTime.tryParse(v);
    }

    return ReminderState(
      lastReminderSent: parse('lastReminderSent'),
      acknowledged: json['acknowledged'] as bool? ?? false,
      completed: json['completed'] as bool? ?? false,
      snoozedUntil: parse('snoozedUntil'),
      nextReminder: parse('nextReminder'),
      missed: json['missed'] as bool? ?? false,
      missedViewed: json['missedViewed'] as bool? ?? false,
      completionDate: parse('completionDate'),
      completionMethod: json['completionMethod'] as String?,
    );
  }
}
