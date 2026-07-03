/// Document in the vault (stored outside SQLite).
library;

import 'package:renew_wise/models/vault_document_category.dart';
import 'package:renew_wise/models/renewwise_entity_metadata.dart';

class EventDocument {
  const EventDocument({
    required this.id,
    required this.path,
    required this.name,
    this.isImage = true,
    this.addedAt,
    this.category = VaultDocumentCategory.other,
    this.customCategory,
    this.tags = const [],
    this.notes,
    this.isFavorite = false,
    this.sizeBytes = 0,
    this.fileType,
    this.linkedRenewalIds = const [],
    this.lastViewedAt,
    this.ocrText,
    this.storageBackend = VaultStorageBackend.local,
    this.isProtected = false,
    this.updatedAt,
    this.version = RenewWiseEntityMetadata.currentSchemaVersion,
  });

  final String id;
  final String path;
  final String name;
  final bool isImage;
  final DateTime? addedAt;
  final VaultDocumentCategory category;
  final String? customCategory;
  final List<String> tags;
  final String? notes;
  final bool isFavorite;
  final int sizeBytes;
  final VaultFileType? fileType;
  final List<String> linkedRenewalIds;
  final DateTime? lastViewedAt;
  final String? ocrText;
  final VaultStorageBackend storageBackend;

  /// When true, opening or changing protection requires device authentication.
  final bool isProtected;
  final DateTime? updatedAt;
  final int version;

  DateTime? get createdAt => addedAt;

  String? get subCategory => customCategory;

  VaultFileType get resolvedFileType =>
      fileType ?? VaultFileType.fromPath(path, isImage: isImage);

  bool get isLinked => linkedRenewalIds.isNotEmpty;

  String get categoryLabel => category.displayLabel(customCategory);

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'name': name,
        'isImage': isImage,
        if (addedAt != null) 'addedAt': addedAt!.toIso8601String(),
        'category': category.name,
        if (customCategory != null) 'customCategory': customCategory,
        'tags': tags,
        if (notes != null) 'notes': notes,
        'isFavorite': isFavorite,
        'sizeBytes': sizeBytes,
        if (fileType != null) 'fileType': fileType!.name,
        'linkedRenewalIds': linkedRenewalIds,
        if (lastViewedAt != null)
          'lastViewedAt': lastViewedAt!.toIso8601String(),
        if (ocrText != null) 'ocrText': ocrText,
        'storageBackend': storageBackend.name,
        'isProtected': isProtected,
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
        if (version != RenewWiseEntityMetadata.currentSchemaVersion)
          'version': version,
      };

  factory EventDocument.fromJson(Map<String, dynamic> json) {
    final linked = json['linkedRenewalIds'];
    final meta = RenewWiseRecordMeta.fromJson(
      json,
      fallbackCreatedAt: json['addedAt'] != null
          ? DateTime.tryParse(json['addedAt'] as String)
          : null,
      fallbackSubCategory: json['customCategory'] as String?,
    );
    return EventDocument(
      id: json['id'] as String,
      path: json['path'] as String,
      name: json['name'] as String,
      isImage: json['isImage'] as bool? ?? true,
      addedAt: json['addedAt'] != null
          ? DateTime.parse(json['addedAt'] as String)
          : null,
      category: VaultDocumentCategory.values.firstWhere(
        (c) => c.name == (json['category'] as String?),
        orElse: () => VaultDocumentCategory.other,
      ),
      customCategory: json['customCategory'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      notes: json['notes'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      fileType: json['fileType'] != null
          ? VaultFileType.values.byName(json['fileType'] as String)
          : null,
      linkedRenewalIds: linked is List
          ? linked.map((e) => e.toString()).toList()
          : const [],
      lastViewedAt: json['lastViewedAt'] != null
          ? DateTime.parse(json['lastViewedAt'] as String)
          : null,
      ocrText: json['ocrText'] as String?,
      storageBackend: VaultStorageBackend.values.firstWhere(
        (b) => b.name == (json['storageBackend'] as String?),
        orElse: () => VaultStorageBackend.local,
      ),
      isProtected: json['isProtected'] as bool? ?? false,
      updatedAt: meta.updatedAt,
      version: meta.version,
    );
  }

  EventDocument copyWith({
    String? id,
    String? path,
    String? name,
    bool? isImage,
    DateTime? addedAt,
    VaultDocumentCategory? category,
    String? customCategory,
    List<String>? tags,
    String? notes,
    bool? isFavorite,
    int? sizeBytes,
    VaultFileType? fileType,
    List<String>? linkedRenewalIds,
    DateTime? lastViewedAt,
    String? ocrText,
    VaultStorageBackend? storageBackend,
    bool? isProtected,
    DateTime? updatedAt,
    int? version,
  }) {
    return EventDocument(
      id: id ?? this.id,
      path: path ?? this.path,
      name: name ?? this.name,
      isImage: isImage ?? this.isImage,
      addedAt: addedAt ?? this.addedAt,
      category: category ?? this.category,
      customCategory: customCategory ?? this.customCategory,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      fileType: fileType ?? this.fileType,
      linkedRenewalIds: linkedRenewalIds ?? this.linkedRenewalIds,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      ocrText: ocrText ?? this.ocrText,
      storageBackend: storageBackend ?? this.storageBackend,
      isProtected: isProtected ?? this.isProtected,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }
}

enum EventActivityType {
  created('Created'),
  reminderSent('Reminder Sent'),
  viewed('Viewed'),
  acknowledged('Acknowledged'),
  completed('Completed'),
  restored('Restored'),
  rescheduled('Rescheduled'),
  documentAdded('Document Added');

  const EventActivityType(this.label);
  final String label;
}

class EventActivity {
  const EventActivity({
    required this.type,
    required this.timestamp,
    this.detail,
  });

  final EventActivityType type;
  final DateTime timestamp;
  final String? detail;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        if (detail != null) 'detail': detail,
      };

  factory EventActivity.fromJson(Map<String, dynamic> json) => EventActivity(
        type: EventActivityType.values.byName(json['type'] as String),
        timestamp: DateTime.parse(json['timestamp'] as String),
        detail: json['detail'] as String?,
      );
}
