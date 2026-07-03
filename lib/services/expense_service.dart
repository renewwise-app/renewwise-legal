import 'package:flutter/foundation.dart';

import 'package:renew_wise/models/expense_record.dart';
import 'package:renew_wise/repository/expense_repository.dart';
import 'package:renew_wise/repository/shared_preferences_expense_repository.dart';
import 'package:renew_wise/utils/date_utils.dart';

class ExpenseService extends ChangeNotifier {
  ExpenseService({ExpenseRepository? repository})
      : _repository = repository ?? SharedPreferencesExpenseRepository();

  final ExpenseRepository _repository;

  final List<ExpenseRecord> _expenses = [];

  List<ExpenseRecord> get expenses {
    final copy = List<ExpenseRecord>.from(_expenses)
      ..sort((a, b) => b.date.compareTo(a.date));
    return copy;
  }

  Future<void> initialize() async {
    _expenses
      ..clear()
      ..addAll(await _repository.loadAll());
    notifyListeners();
  }

  Future<void> _persist() async {
    await _repository.saveAll(_expenses);
    notifyListeners();
  }

  Future<void> addExpense(ExpenseRecord expense) async {
    _expenses.add(expense);
    await _persist();
  }

  Future<void> updateExpense(ExpenseRecord expense) async {
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index == -1) return;
    _expenses[index] = expense;
    await _persist();
  }

  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    await _persist();
  }

  List<ExpenseRecord> filtered(ExpenseFilterState filter, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final today = RenewalDateUtils.dateOnly(current);

    return expenses.where((expense) {
      final date = RenewalDateUtils.dateOnly(expense.date);

      final inRange = switch (filter.dateFilter) {
        ExpenseDateFilter.currentMonth =>
          date.year == current.year && date.month == current.month,
        ExpenseDateFilter.last30Days =>
          !date.isBefore(today.subtract(const Duration(days: 29))) &&
              !date.isAfter(today),
        ExpenseDateFilter.customRange => _inCustomRange(
            date,
            filter.customStart,
            filter.customEnd,
          ),
      };

      if (!inRange) return false;
      if (filter.category != null && expense.category != filter.category) {
        return false;
      }
      if (filter.source != null && expense.source != filter.source) {
        return false;
      }
      return true;
    }).toList();
  }

  static bool _inCustomRange(
    DateTime date,
    DateTime? start,
    DateTime? end,
  ) {
    if (start == null || end == null) return true;
    final s = RenewalDateUtils.dateOnly(start);
    final e = RenewalDateUtils.dateOnly(end);
    return !date.isBefore(s) && !date.isAfter(e);
  }

  ExpenseSummary summarize(List<ExpenseRecord> records) {
    if (records.isEmpty) return ExpenseSummary.empty;
    final total = records.fold<double>(0, (sum, e) => sum + e.amount);
    final largest = records
        .map((e) => e.amount)
        .reduce((a, b) => a > b ? a : b);
    return ExpenseSummary(
      total: total,
      count: records.length,
      largest: largest,
      average: total / records.length,
    );
  }

  bool hasExpenseForReminder(String reminderId, {DateTime? onDate}) {
    return _expenses.any((expense) {
      if (expense.reminderId != reminderId) return false;
      if (onDate == null) return true;
      return RenewalDateUtils.dateOnly(expense.date) ==
          RenewalDateUtils.dateOnly(onDate);
    });
  }
}

ExpenseService? _expenseServiceInstance;

ExpenseService get expenseService {
  final service = _expenseServiceInstance;
  assert(service != null, 'ExpenseService has not been initialized');
  return service!;
}

Future<ExpenseService> initializeExpenseService() async {
  _expenseServiceInstance ??= ExpenseService();
  await _expenseServiceInstance!.initialize();
  return _expenseServiceInstance!;
}
