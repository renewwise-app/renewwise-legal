import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/repository/reminder_repository.dart';

/// Abstract interface for renewal persistence.
/// The SQLite implementation is used in production;
/// an in-memory implementation is used in tests.
abstract class RenewalRepository implements ReminderRepository {
  @override
  Future<List<Renewal>> loadAll();
  @override
  Future<void> insert(Renewal renewal);
  @override
  Future<void> update(Renewal renewal);
  @override
  Future<void> delete(String id);
  @override
  Future<void> clearAll();
  @override
  Future<List<Map<String, dynamic>>> exportAllRows();
  @override
  Future<void> replaceAllRows(List<Map<String, dynamic>> rows);
}
