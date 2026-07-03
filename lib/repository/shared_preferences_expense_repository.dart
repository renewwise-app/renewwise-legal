import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:renew_wise/models/expense_record.dart';
import 'package:renew_wise/repository/expense_repository.dart';

class SharedPreferencesExpenseRepository implements ExpenseRepository {
  static const _kExpensesKey = 'expense_records_v1';

  @override
  Future<List<ExpenseRecord>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kExpensesKey);
    if (raw == null) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => ExpenseRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveAll(List<ExpenseRecord> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kExpensesKey,
      jsonEncode(expenses.map((e) => e.toJson()).toList()),
    );
  }
}
