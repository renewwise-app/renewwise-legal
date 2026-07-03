import 'package:renew_wise/models/expense_record.dart';

/// Persistence boundary for expense records.
abstract class ExpenseRepository {
  Future<List<ExpenseRecord>> loadAll();
  Future<void> saveAll(List<ExpenseRecord> expenses);
}
