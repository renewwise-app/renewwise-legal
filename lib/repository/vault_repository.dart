import 'package:renew_wise/models/event_document.dart';

/// Persistence boundary for vault documents.
abstract class VaultRepository {
  Future<Map<String, EventDocument>> loadAllDocuments();
  Future<void> saveAllDocuments(Map<String, EventDocument> documents);

  /// Legacy per-event document map for one-time migration.
  Future<Map<String, List<EventDocument>>?> loadLegacyDocumentsByRenewal();
}
