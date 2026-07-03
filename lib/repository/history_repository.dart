import 'package:renew_wise/models/history_entry.dart';

/// Persistence boundary for completion history.
abstract class HistoryRepository {
  Future<List<HistoryEntry>> loadAll();
  Future<void> saveAll(List<HistoryEntry> entries);
}
