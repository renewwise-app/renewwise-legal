import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:renew_wise/models/event_document.dart';
import 'package:renew_wise/repository/vault_repository.dart';

class SharedPreferencesVaultRepository implements VaultRepository {
  static const _kLegacyDocumentsKey = 'event_documents_v1';
  static const _kVaultKey = 'vault_documents_v2';

  @override
  Future<Map<String, EventDocument>> loadAllDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final vaultRaw = prefs.getString(_kVaultKey);
    if (vaultRaw == null) return {};
    final map = jsonDecode(vaultRaw) as Map<String, dynamic>;
    final result = <String, EventDocument>{};
    map.forEach((id, value) {
      result[id] = EventDocument.fromJson(value as Map<String, dynamic>);
    });
    return result;
  }

  @override
  Future<void> saveAllDocuments(Map<String, EventDocument> documents) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kVaultKey,
      jsonEncode(documents.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  @override
  Future<Map<String, List<EventDocument>>?> loadLegacyDocumentsByRenewal() async {
    final prefs = await SharedPreferences.getInstance();
    final legacyRaw = prefs.getString(_kLegacyDocumentsKey);
    if (legacyRaw == null) return null;
    final map = jsonDecode(legacyRaw) as Map<String, dynamic>;
    final result = <String, List<EventDocument>>{};
    map.forEach((renewalId, value) {
      result[renewalId] = (value as List<dynamic>)
          .map((e) => EventDocument.fromJson(e as Map<String, dynamic>))
          .toList();
    });
    return result;
  }
}
