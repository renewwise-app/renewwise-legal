import 'package:renew_wise/models/alert_style.dart';
import 'package:renew_wise/models/recurrence_end_type.dart';
import 'package:renew_wise/models/renewal_category.dart';
import 'package:renew_wise/models/renewal_currency.dart';
import 'package:renew_wise/models/renewal_importance.dart';
import 'package:renew_wise/models/renewal_priority.dart';
import 'package:renew_wise/models/renewal_status.dart';
import 'package:renew_wise/models/repeat_cycle.dart';
import 'package:renew_wise/utils/date_utils.dart';

class Renewal {
  const Renewal({
    required this.id,
    required this.title,
    required this.category,
    required this.renewalDate,
    this.paymentRequired = false,
    this.amount,
    this.currency = RenewalCurrency.inr,
    this.importance = RenewalImportance.important,
    this.priority = RenewalPriority.medium,
    this.alertStyle = AlertStyle.standard,
    this.status = RenewalStatus.upcoming,
    this.repeatCycle = RepeatCycle.yearly,
    this.recurrenceEndType = RecurrenceEndType.never,
    this.recurrenceEndDate,
    this.recurrenceOccurrenceLimit,
    this.recurrenceCompletedCount = 0,
    this.reminderSchedule = const [30, 7, 1],
    this.notes,
    this.fundId,
    required this.createdAt,
    required this.updatedAt,
    // ── v2 fields ─────────────────────────────────────────────────────────
    this.customEventType,
    this.customReminderDates = const [],
    this.reminderTimeMinutes,
  });

  final String id;
  final String title;
  final RenewalCategory category;
  final DateTime renewalDate;
  final bool paymentRequired;
  final double? amount;
  final RenewalCurrency currency;
  final RenewalImportance importance;
  final RenewalPriority priority;
  final AlertStyle alertStyle;
  final RenewalStatus status;
  final RepeatCycle repeatCycle;
  final RecurrenceEndType recurrenceEndType;
  final DateTime? recurrenceEndDate;
  final int? recurrenceOccurrenceLimit;
  final int recurrenceCompletedCount;
  final List<int> reminderSchedule;
  final String? notes;
  final String? fundId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Free-form event type name shown when category is [RenewalCategory.other].
  final String? customEventType;

  /// Specific calendar dates on which reminders should fire (in addition to
  /// the day-offset-based [reminderSchedule]).
  final List<DateTime> customReminderDates;

  /// Minutes since midnight (0..1439) at which all reminders fire.
  /// Null means use the app-wide default (9:00 AM = 540).
  final int? reminderTimeMinutes;

  // ── Computed properties ──────────────────────────────────────────────────

  int get daysRemaining => RenewalDateUtils.daysRemaining(renewalDate);
  bool get isOverdue => daysRemaining < 0;

  String get daysRemainingLabel =>
      RenewalDateUtils.daysRemainingLabel(renewalDate);

  String get formattedRenewalDate =>
      RenewalDateUtils.formatDisplayDate(renewalDate);

  /// Display label for the category, honouring [customEventType] when set.
  String get categoryLabel => customEventType ?? category.label;

  /// Null when there is no payment or no amount entered.
  String? get formattedAmount =>
      (paymentRequired && amount != null) ? currency.formatAmount(amount!) : null;

  /// Always returns a display string – shows "No payment" when not applicable.
  String get displayAmount {
    if (!paymentRequired || amount == null) return 'No payment';
    return currency.formatAmount(amount!);
  }

  Renewal copyWith({
    String? id,
    String? title,
    RenewalCategory? category,
    DateTime? renewalDate,
    bool? paymentRequired,
    double? amount,
    bool clearAmount = false,
    RenewalCurrency? currency,
    RenewalImportance? importance,
    RenewalPriority? priority,
    AlertStyle? alertStyle,
    RenewalStatus? status,
    RepeatCycle? repeatCycle,
    RecurrenceEndType? recurrenceEndType,
    DateTime? recurrenceEndDate,
    bool clearRecurrenceEndDate = false,
    int? recurrenceOccurrenceLimit,
    bool clearRecurrenceOccurrenceLimit = false,
    int? recurrenceCompletedCount,
    List<int>? reminderSchedule,
    String? notes,
    bool clearNotes = false,
    String? fundId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customEventType,
    bool clearCustomEventType = false,
    List<DateTime>? customReminderDates,
    int? reminderTimeMinutes,
    bool clearReminderTime = false,
  }) {
    return Renewal(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      renewalDate: renewalDate ?? this.renewalDate,
      paymentRequired: paymentRequired ?? this.paymentRequired,
      amount: clearAmount ? null : (amount ?? this.amount),
      currency: currency ?? this.currency,
      importance: importance ?? this.importance,
      priority: priority ?? this.priority,
      alertStyle: alertStyle ?? this.alertStyle,
      status: status ?? this.status,
      repeatCycle: repeatCycle ?? this.repeatCycle,
      recurrenceEndType: recurrenceEndType ?? this.recurrenceEndType,
      recurrenceEndDate: clearRecurrenceEndDate
          ? null
          : (recurrenceEndDate ?? this.recurrenceEndDate),
      recurrenceOccurrenceLimit: clearRecurrenceOccurrenceLimit
          ? null
          : (recurrenceOccurrenceLimit ?? this.recurrenceOccurrenceLimit),
      recurrenceCompletedCount:
          recurrenceCompletedCount ?? this.recurrenceCompletedCount,
      reminderSchedule: reminderSchedule ?? this.reminderSchedule,
      notes: clearNotes ? null : (notes ?? this.notes),
      fundId: fundId ?? this.fundId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customEventType:
          clearCustomEventType ? null : (customEventType ?? this.customEventType),
      customReminderDates: customReminderDates ?? this.customReminderDates,
      reminderTimeMinutes:
          clearReminderTime ? null : (reminderTimeMinutes ?? this.reminderTimeMinutes),
    );
  }
}
