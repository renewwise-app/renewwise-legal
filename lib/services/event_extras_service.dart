import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:renew_wise/models/event_document.dart';
import 'package:renew_wise/models/backup_models.dart';
import 'package:renew_wise/models/vault_document_category.dart';

/// Vault + event documents and activity log (SharedPreferences — no SQLite).
class EventExtrasService extends ChangeNotifier {
  static const _kLegacyDocumentsKey = 'event_documents_v1';
  static const _kVaultKey = 'vault_documents_v2';
  static const _kActivityKey = 'event_activity_v1';

  final Map<String, EventDocument> _vault = {};
  final Map<String, List<EventActivity>> _activities = {};

  List<EventDocument> documentsFor(String renewalId) {
    return _vault.values
        .where((d) => d.linkedRenewalIds.contains(renewalId))
        .toList()
      ..sort((a, b) => (b.addedAt ?? DateTime(0)).compareTo(a.addedAt ?? DateTime(0)));
  }

  List<EventDocument> get allDocuments {
    final list = _vault.values.toList()
      ..sort((a, b) => (b.addedAt ?? DateTime(0)).compareTo(a.addedAt ?? DateTime(0)));
    return list;
  }

  EventDocument? documentById(String id) => _vault[id];

  int get totalDocumentCount => _vault.length;

  int get totalStorageBytes =>
      _vault.values.fold(0, (sum, d) => sum + d.sizeBytes);

  List<EventDocument> get favorites =>
      allDocuments.where((d) => d.isFavorite).toList();

  List<EventDocument> get recentlyAdded => allDocuments.take(8).toList();

  List<EventDocument> get recentlyViewed {
    final list = allDocuments
        .where((d) => d.lastViewedAt != null)
        .toList()
      ..sort((a, b) => b.lastViewedAt!.compareTo(a.lastViewedAt!));
    return list.take(8).toList();
  }

  Map<VaultDocumentCategory, int> categoryCounts() {
    final counts = <VaultDocumentCategory, int>{};
    for (final d in _vault.values) {
      counts[d.category] = (counts[d.category] ?? 0) + 1;
    }
    return counts;
  }

  int linkCount(String docId) => _vault[docId]?.linkedRenewalIds.length ?? 0;

  List<EventActivity> activitiesFor(String renewalId) {
    final stored = _activities[renewalId] ?? const [];
    final copy = List<EventActivity>.from(stored)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return copy;
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final vaultRaw = prefs.getString(_kVaultKey);
    if (vaultRaw != null) {
      final map = jsonDecode(vaultRaw) as Map<String, dynamic>;
      map.forEach((id, value) {
        _vault[id] =
            EventDocument.fromJson(value as Map<String, dynamic>);
      });
    } else {
      await _migrateLegacy(prefs);
    }

    final actRaw = prefs.getString(_kActivityKey);
    if (actRaw != null) {
      final map = jsonDecode(actRaw) as Map<String, dynamic>;
      map.forEach((id, value) {
        _activities[id] = (value as List<dynamic>)
            .map((e) => EventActivity.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    }
  }

  Future<void> _migrateLegacy(SharedPreferences prefs) async {
    final legacyRaw = prefs.getString(_kLegacyDocumentsKey);
    if (legacyRaw == null) return;
    final map = jsonDecode(legacyRaw) as Map<String, dynamic>;
    map.forEach((renewalId, value) {
      for (final e in value as List<dynamic>) {
        final doc = EventDocument.fromJson(e as Map<String, dynamic>);
        final existing = _vault[doc.id];
        if (existing != null) {
          final links = {...existing.linkedRenewalIds, renewalId}.toList();
          _vault[doc.id] = existing.copyWith(linkedRenewalIds: links);
        } else {
          _vault[doc.id] = doc.copyWith(
            linkedRenewalIds: doc.linkedRenewalIds.isEmpty
                ? [renewalId]
                : doc.linkedRenewalIds,
          );
        }
      }
    });
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kVaultKey,
      jsonEncode(_vault.map((k, v) => MapEntry(k, v.toJson()))),
    );
    await prefs.setString(
      _kActivityKey,
      jsonEncode(
        _activities.map(
          (k, v) => MapEntry(k, v.map((a) => a.toJson()).toList()),
        ),
      ),
    );
    notifyListeners();
  }

  Future<void> upsertDocument(EventDocument doc) async {
    _vault[doc.id] = doc;
    await _persist();
  }

  Future<void> setDocuments(
    String renewalId,
    List<EventDocument> docs,
  ) async {
    for (final existing in _vault.values.toList()) {
      if (existing.linkedRenewalIds.contains(renewalId) &&
          !docs.any((d) => d.id == existing.id)) {
        await unlinkDocument(existing.id, renewalId);
      }
    }
    for (final doc in docs) {
      final links = {...doc.linkedRenewalIds, renewalId}.toList();
      _vault[doc.id] = doc.copyWith(linkedRenewalIds: links);
    }
    await _persist();
  }

  Future<void> addDocument(String renewalId, EventDocument doc) async {
    final existing = _vault[doc.id];
    if (existing != null) {
      final links = {...existing.linkedRenewalIds, renewalId}.toList();
      _vault[doc.id] = existing.copyWith(linkedRenewalIds: links);
    } else {
      _vault[doc.id] = doc.copyWith(
        linkedRenewalIds: doc.linkedRenewalIds.isEmpty
            ? [renewalId]
            : doc.linkedRenewalIds,
      );
    }
    await recordActivity(
      renewalId,
      EventActivityType.documentAdded,
      detail: doc.name,
    );
    await _persist();
  }

  Future<void> linkDocument(String docId, String renewalId) async {
    final doc = _vault[docId];
    if (doc == null) return;
    if (doc.linkedRenewalIds.contains(renewalId)) return;
    _vault[docId] = doc.copyWith(
      linkedRenewalIds: [...doc.linkedRenewalIds, renewalId],
    );
    await recordActivity(
      renewalId,
      EventActivityType.documentAdded,
      detail: doc.name,
    );
    await _persist();
  }

  Future<void> unlinkDocument(String docId, String renewalId) async {
    final doc = _vault[docId];
    if (doc == null) return;
    final links =
        doc.linkedRenewalIds.where((id) => id != renewalId).toList();
    if (links.isEmpty) {
      await deleteDocument(docId);
    } else {
      _vault[docId] = doc.copyWith(linkedRenewalIds: links);
      await _persist();
    }
  }

  Future<void> removeDocument(String renewalId, String docId) async {
    await unlinkDocument(docId, renewalId);
  }

  Future<void> deleteDocument(String docId, {bool deleteFile = true}) async {
    final doc = _vault.remove(docId);
    if (doc != null && deleteFile && !doc.path.startsWith('demo://')) {
      try {
        final file = File(doc.path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    await _persist();
  }

  Future<void> replaceDocument(
    String renewalId,
    String docId,
    EventDocument replacement,
  ) async {
    final old = _vault[docId];
    final links = old?.linkedRenewalIds ?? [renewalId];
    _vault.remove(docId);
    _vault[replacement.id] = replacement.copyWith(linkedRenewalIds: links);
    await _persist();
  }

  Future<void> updateDocument(EventDocument doc) async {
    _vault[doc.id] = doc;
    await _persist();
  }

  Future<void> markViewed(String docId) async {
    final doc = _vault[docId];
    if (doc == null) return;
    _vault[docId] = doc.copyWith(lastViewedAt: DateTime.now());
    await _persist();
  }

  Future<void> toggleFavorite(String docId) async {
    final doc = _vault[docId];
    if (doc == null) return;
    _vault[docId] = doc.copyWith(isFavorite: !doc.isFavorite);
    await _persist();
  }

  Future<void> recordActivity(
    String renewalId,
    EventActivityType type, {
    String? detail,
    DateTime? timestamp,
  }) async {
    _activities.putIfAbsent(renewalId, () => []).add(
          EventActivity(
            type: type,
            timestamp: timestamp ?? DateTime.now(),
            detail: detail,
          ),
        );
    await _persist();
  }

  Future<void> generateSampleDocuments(String renewalId) async {
    final now = DateTime.now();
    await upsertDocument(
      EventDocument(
        id: 'sample_doc_1',
        path: 'demo://policy.pdf',
        name: 'policy.pdf',
        isImage: false,
        addedAt: now,
        category: VaultDocumentCategory.insurance,
        sizeBytes: 245000,
        linkedRenewalIds: [renewalId],
      ),
    );
    await upsertDocument(
      EventDocument(
        id: 'sample_doc_2',
        path: 'demo://receipt.jpg',
        name: 'receipt.jpg',
        isImage: true,
        addedAt: now.subtract(const Duration(hours: 2)),
        category: VaultDocumentCategory.financial,
        sizeBytes: 89000,
        linkedRenewalIds: [renewalId],
      ),
    );
  }

  Future<void> generateSampleTimeline(String renewalId) async {
    final now = DateTime.now();
    _activities[renewalId] = [
      EventActivity(
        type: EventActivityType.created,
        timestamp: now.subtract(const Duration(days: 30)),
      ),
      EventActivity(
        type: EventActivityType.reminderSent,
        timestamp: now.subtract(const Duration(days: 7)),
      ),
      EventActivity(
        type: EventActivityType.viewed,
        timestamp: now.subtract(const Duration(days: 2)),
      ),
      EventActivity(
        type: EventActivityType.acknowledged,
        timestamp: now.subtract(const Duration(days: 1)),
      ),
    ];
    await _persist();
  }

  Future<void> generateSampleEventDetails(String renewalId) async {
    await generateSampleDocuments(renewalId);
    await generateSampleTimeline(renewalId);
  }

  Future<void> generateVaultSamples({List<String>? renewalIds}) async {
    final now = DateTime.now();
    final samples = [
      (
        id: 'vault_passport',
        name: 'passport_scan.jpg',
        cat: VaultDocumentCategory.passport,
        image: true,
      ),
      (
        id: 'vault_insurance',
        name: 'car_insurance.pdf',
        cat: VaultDocumentCategory.insurance,
        image: false,
      ),
      (
        id: 'vault_licence',
        name: 'driving_licence.jpg',
        cat: VaultDocumentCategory.drivingLicence,
        image: true,
      ),
      (
        id: 'vault_medical',
        name: 'health_report.pdf',
        cat: VaultDocumentCategory.medical,
        image: false,
      ),
    ];
    for (var i = 0; i < samples.length; i++) {
      final s = samples[i];
      final links = renewalIds != null && renewalIds.length > i
          ? [renewalIds[i % renewalIds.length]]
          : <String>[];
      await upsertDocument(
        EventDocument(
          id: s.id,
          path: 'demo://${s.name}',
          name: s.name,
          isImage: s.image,
          addedAt: now.subtract(Duration(days: i * 3)),
          category: s.cat,
          sizeBytes: 120000 + i * 45000,
          tags: i.isEven ? ['important'] : const [],
          notes: i == 0 ? 'Keep original safe' : null,
          isFavorite: i == 0,
          linkedRenewalIds: links,
          lastViewedAt: i < 2 ? now.subtract(Duration(hours: i + 1)) : null,
        ),
      );
    }
  }

  Future<void> generateLinkedVaultDocuments(List<String> renewalIds) async {
    if (renewalIds.isEmpty) return;
    final now = DateTime.now();
    await upsertDocument(
      EventDocument(
        id: 'vault_linked_passport',
        path: 'demo://passport_full.pdf',
        name: 'passport_full.pdf',
        isImage: false,
        addedAt: now,
        category: VaultDocumentCategory.passport,
        sizeBytes: 512000,
        linkedRenewalIds: renewalIds.take(3).toList(),
        notes: 'Linked to multiple renewals',
      ),
    );
  }

  Future<void> clearForEvent(String renewalId) async {
    for (final doc in _vault.values.toList()) {
      if (doc.linkedRenewalIds.contains(renewalId)) {
        await unlinkDocument(doc.id, renewalId);
      }
    }
    _activities.remove(renewalId);
    await _persist();
  }

  Future<void> clearAll() async {
    for (final doc in _vault.values.toList()) {
      if (!doc.path.startsWith('demo://')) {
        try {
          final file = File(doc.path);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
    }
    _vault.clear();
    _activities.clear();
    await _persist();
  }

  Map<String, dynamic> exportSnapshot() => {
        'vault': _vault.map((k, v) => MapEntry(k, v.toJson())),
        'activities': _activities.map(
          (k, v) => MapEntry(k, v.map((a) => a.toJson()).toList()),
        ),
      };

  Future<void> importSnapshot(
    Map<String, dynamic> data, {
    required RestoreConflictMode mode,
  }) async {
    final vaultRaw = data['vault'] as Map<String, dynamic>? ?? {};
    final activitiesRaw = data['activities'] as Map<String, dynamic>? ?? {};

    if (mode == RestoreConflictMode.replace) {
      await clearAll();
    }

    for (final entry in vaultRaw.entries) {
      if (mode == RestoreConflictMode.merge && _vault.containsKey(entry.key)) {
        continue;
      }
      _vault[entry.key] =
          EventDocument.fromJson(entry.value as Map<String, dynamic>);
    }

    activitiesRaw.forEach((renewalId, list) {
      final parsed = (list as List<dynamic>)
          .map((a) => EventActivity.fromJson(a as Map<String, dynamic>))
          .toList();
      if (mode == RestoreConflictMode.merge) {
        final existing = _activities[renewalId] ?? [];
        String activityKey(EventActivity a) =>
            '${a.type.name}|${a.timestamp.toIso8601String()}|${a.detail ?? ''}';
        final keys = existing.map(activityKey).toSet();
        final merged = [
          ...existing,
          ...parsed.where((a) => !keys.contains(activityKey(a))),
        ];
        _activities[renewalId] = merged;
      } else {
        _activities[renewalId] = parsed;
      }
    });

    await _persist();
  }

  /// Updates document paths after binary files are restored to local storage.
  Future<void> remapDocumentPath(String docId, String newPath) async {
    final doc = _vault[docId];
    if (doc == null) return;
    _vault[docId] = EventDocument(
      id: doc.id,
      path: newPath,
      name: doc.name,
      isImage: doc.isImage,
      addedAt: doc.addedAt,
      category: doc.category,
      customCategory: doc.customCategory,
      tags: doc.tags,
      notes: doc.notes,
      isFavorite: doc.isFavorite,
      sizeBytes: doc.sizeBytes,
      fileType: doc.fileType,
      linkedRenewalIds: doc.linkedRenewalIds,
      lastViewedAt: doc.lastViewedAt,
      ocrText: doc.ocrText,
      storageBackend: doc.storageBackend,
      isProtected: doc.isProtected,
    );
    await _persist();
  }
}
