/// Shared metadata conventions for RenewWise domain models (Packet A).
///
/// Fields are optional in persisted JSON; [fromJson] factories supply defaults
/// so existing user data remains compatible without migration.
abstract final class RenewWiseEntityMetadata {
  static const int currentSchemaVersion = 1;

  static DateTime? parseOptionalDate(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }

  static int parseVersion(Object? raw) {
    if (raw is int && raw > 0) return raw;
    return currentSchemaVersion;
  }
}

/// Common optional metadata carried by persisted entities.
class RenewWiseRecordMeta {
  const RenewWiseRecordMeta({
    this.createdAt,
    this.updatedAt,
    this.subCategory,
    this.version = RenewWiseEntityMetadata.currentSchemaVersion,
  });

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? subCategory;
  final int version;

  Map<String, dynamic> toJson({bool includeDefaults = false}) => {
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
        if (subCategory != null && subCategory!.isNotEmpty)
          'subCategory': subCategory,
        if (includeDefaults || version != RenewWiseEntityMetadata.currentSchemaVersion)
          'version': version,
      };

  factory RenewWiseRecordMeta.fromJson(
    Map<String, dynamic> json, {
    DateTime? fallbackCreatedAt,
    DateTime? fallbackUpdatedAt,
    String? fallbackSubCategory,
  }) {
    final created = RenewWiseEntityMetadata.parseOptionalDate(json['createdAt']) ??
        fallbackCreatedAt;
    final updated = RenewWiseEntityMetadata.parseOptionalDate(json['updatedAt']) ??
        fallbackUpdatedAt ??
        created;
    return RenewWiseRecordMeta(
      createdAt: created,
      updatedAt: updated,
      subCategory: json['subCategory'] as String? ?? fallbackSubCategory,
      version: RenewWiseEntityMetadata.parseVersion(json['version']),
    );
  }
}
