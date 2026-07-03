import 'package:renew_wise/models/renewal_category.dart';

enum ExpenseSource {
  reminder('Reminder'),
  manual('Manual');

  const ExpenseSource(this.label);
  final String label;
}

enum ExpenseDateFilter {
  currentMonth('Current Month'),
  last30Days('Last 30 Days'),
  customRange('Custom Date Range');

  const ExpenseDateFilter(this.label);
  final String label;
}

class ExpenseRecord {
  const ExpenseRecord({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    required this.source,
    this.reminderId,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final RenewalCategory category;
  final double amount;
  final DateTime date;
  final ExpenseSource source;
  final String? reminderId;
  final String? notes;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'amount': amount,
        'date': date.toIso8601String(),
        'source': source.name,
        if (reminderId != null) 'reminderId': reminderId,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ExpenseRecord.fromJson(Map<String, dynamic> json) => ExpenseRecord(
        id: json['id'] as String,
        category: RenewalCategory.values.firstWhere(
          (c) => c.name == (json['category'] as String?),
          orElse: () => RenewalCategory.other,
        ),
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        source: ExpenseSource.values.firstWhere(
          (s) => s.name == (json['source'] as String?),
          orElse: () => ExpenseSource.manual,
        ),
        reminderId: json['reminderId'] as String?,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  ExpenseRecord copyWith({
    String? id,
    RenewalCategory? category,
    double? amount,
    DateTime? date,
    ExpenseSource? source,
    String? reminderId,
    String? notes,
    DateTime? createdAt,
    bool clearNotes = false,
    bool clearReminderId = false,
  }) {
    return ExpenseRecord(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      source: source ?? this.source,
      reminderId: clearReminderId ? null : (reminderId ?? this.reminderId),
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ExpenseFilterState {
  const ExpenseFilterState({
    this.dateFilter = ExpenseDateFilter.currentMonth,
    this.customStart,
    this.customEnd,
    this.category,
    this.source,
  });

  final ExpenseDateFilter dateFilter;
  final DateTime? customStart;
  final DateTime? customEnd;
  final RenewalCategory? category;
  final ExpenseSource? source;

  ExpenseFilterState copyWith({
    ExpenseDateFilter? dateFilter,
    DateTime? customStart,
    DateTime? customEnd,
    RenewalCategory? category,
    ExpenseSource? source,
    bool clearCategory = false,
    bool clearSource = false,
  }) {
    return ExpenseFilterState(
      dateFilter: dateFilter ?? this.dateFilter,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
      category: clearCategory ? null : (category ?? this.category),
      source: clearSource ? null : (source ?? this.source),
    );
  }
}

class ExpenseSummary {
  const ExpenseSummary({
    required this.total,
    required this.count,
    required this.largest,
    required this.average,
  });

  final double total;
  final int count;
  final double largest;
  final double average;

  static const empty = ExpenseSummary(
    total: 0,
    count: 0,
    largest: 0,
    average: 0,
  );
}

class ExpenseValidation {
  const ExpenseValidation({this.error});
  final String? error;
  bool get isValid => error == null;
}

abstract final class ExpenseValidationUtils {
  static ExpenseValidation validate({
    required RenewalCategory? category,
    required String amountText,
    required DateTime? date,
    DateTime? now,
  }) {
    if (category == null) {
      return const ExpenseValidation(error: 'Select an expense category');
    }
    final amount = double.tryParse(amountText.trim());
    if (amount == null || amount <= 0) {
      return const ExpenseValidation(
        error: 'Enter an amount greater than zero',
      );
    }
    if (date == null) {
      return const ExpenseValidation(error: 'Select an expense date');
    }
    final today = DateTime(
      (now ?? DateTime.now()).year,
      (now ?? DateTime.now()).month,
      (now ?? DateTime.now()).day,
    );
    final picked = DateTime(date.year, date.month, date.day);
    if (picked.isAfter(today)) {
      return const ExpenseValidation(error: 'Expense date cannot be in the future');
    }
    return const ExpenseValidation();
  }
}
