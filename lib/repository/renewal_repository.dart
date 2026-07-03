import 'package:renew_wise/models/renewal.dart';

/// Abstract interface for renewal persistence.
/// The SQLite implementation is used in production;
/// an in-memory implementation is used in tests.
abstract class RenewalRepository {
  Future<List<Renewal>> loadAll();
  Future<void> insert(Renewal renewal);
  Future<void> update(Renewal renewal);
  Future<void> delete(String id);
  Future<void> clearAll();

  /// Raw SQLite rows for backup (production repo only).
  Future<List<Map<String, dynamic>>> exportAllRows();

  /// Replace all renewal rows from a backup snapshot.
  Future<void> replaceAllRows(List<Map<String, dynamic>> rows);
}
