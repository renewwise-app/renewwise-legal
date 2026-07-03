import 'package:renew_wise/models/renewal_category.dart';

/// Completed event stored in completion history (SharedPreferences).
class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.renewalId,
    required this.title,
    required this.categoryLabel,
    required this.category,
    required this.completionDate,
    required this.completionMethod,
    required this.originalRenewalDate,
    this.amount,
    this.currencyCode,
    this.notes,
    this.reminderSchedule = const [30, 7, 1],
    this.paymentRequired = false,
    this.restored = false,
    this.restoredAt,
    this.customEventType,
  });

  final String id;
  final String renewalId;
  final String title;
  final String categoryLabel;
  final RenewalCategory category;
  final DateTime completionDate;
  final String completionMethod;
  final DateTime originalRenewalDate;
  final double? amount;
  final String? currencyCode;
  final String? notes;
  final List<int> reminderSchedule;
  final bool paymentRequired;
  final bool restored;
  final DateTime? restoredAt;
  final String? customEventType;

  String get completionMethodLabel =>
      completionMethod == 'notification' ? 'Notification' : 'App';

  Map<String, dynamic> toJson() => {
        'id': id,
        'renewalId': renewalId,
        'title': title,
        'categoryLabel': categoryLabel,
        'category': category.name,
        'completionDate': completionDate.toIso8601String(),
        'completionMethod': completionMethod,
        'originalRenewalDate': originalRenewalDate.toIso8601String(),
        if (amount != null) 'amount': amount,
        if (currencyCode != null) 'currencyCode': currencyCode,
        if (notes != null) 'notes': notes,
        'reminderSchedule': reminderSchedule,
        'paymentRequired': paymentRequired,
        'restored': restored,
        if (restoredAt != null) 'restoredAt': restoredAt!.toIso8601String(),
        if (customEventType != null) 'customEventType': customEventType,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    final completionDate = DateTime.parse(json['completionDate'] as String);
    final renewalId = json['renewalId'] as String;
    return HistoryEntry(
      id: json['id'] as String? ??
          '${renewalId}_${completionDate.millisecondsSinceEpoch}',
      renewalId: renewalId,
      title: json['title'] as String,
      categoryLabel: json['categoryLabel'] as String,
      category: RenewalCategory.values.byName(
        json['category'] as String? ?? RenewalCategory.other.name,
      ),
      completionDate: completionDate,
      completionMethod: json['completionMethod'] as String,
      originalRenewalDate: json['originalRenewalDate'] != null
          ? DateTime.parse(json['originalRenewalDate'] as String)
          : completionDate,
      amount: (json['amount'] as num?)?.toDouble(),
      currencyCode: json['currencyCode'] as String?,
      notes: json['notes'] as String?,
      reminderSchedule: (json['reminderSchedule'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [30, 7, 1],
      paymentRequired: json['paymentRequired'] as bool? ?? false,
      restored: json['restored'] as bool? ?? false,
      restoredAt: json['restoredAt'] != null
          ? DateTime.parse(json['restoredAt'] as String)
          : null,
      customEventType: json['customEventType'] as String?,
    );
  }

  HistoryEntry copyWith({
    String? id,
    String? renewalId,
    String? title,
    String? categoryLabel,
    RenewalCategory? category,
    DateTime? completionDate,
    String? completionMethod,
    DateTime? originalRenewalDate,
    double? amount,
    String? currencyCode,
    String? notes,
    List<int>? reminderSchedule,
    bool? paymentRequired,
    bool? restored,
    DateTime? restoredAt,
    String? customEventType,
  }) {
    return HistoryEntry(
      id: id ?? this.id,
      renewalId: renewalId ?? this.renewalId,
      title: title ?? this.title,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      category: category ?? this.category,
      completionDate: completionDate ?? this.completionDate,
      completionMethod: completionMethod ?? this.completionMethod,
      originalRenewalDate: originalRenewalDate ?? this.originalRenewalDate,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      notes: notes ?? this.notes,
      reminderSchedule: reminderSchedule ?? this.reminderSchedule,
      paymentRequired: paymentRequired ?? this.paymentRequired,
      restored: restored ?? this.restored,
      restoredAt: restoredAt ?? this.restoredAt,
      customEventType: customEventType ?? this.customEventType,
    );
  }
}
