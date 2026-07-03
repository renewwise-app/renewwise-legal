import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:renew_wise/models/event_document.dart';
import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/renewal_status.dart';
import 'package:renew_wise/models/sharing_models.dart';
import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';

/// Local sharing metadata — ready for future cloud sync layer.
class SharingService extends ChangeNotifier {
  static const _kMetaKey = 'event_sharing_meta_v1';
  static const _kActivityKey = 'shared_activity_v1';
  static const _kLocalUserKey = 'sharing_local_user_v1';

  final Map<String, EventSharingMeta> _meta = {};
  final Map<String, List<SharedActivityEntry>> _activities = {};
  LocalUserProfile? _localUser;

  LocalUserProfile get localUser =>
      _localUser ?? const LocalUserProfile(id: 'local', displayName: 'You');

  Future<void> initialize(SettingsService settings) async {
    final prefs = await SharedPreferences.getInstance();
    final userRaw = prefs.getString(_kLocalUserKey);
    if (userRaw != null) {
      _localUser = LocalUserProfile.fromJson(
        jsonDecode(userRaw) as Map<String, dynamic>,
      );
    } else {
      _localUser = LocalUserProfile(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        displayName: settings.userName.isNotEmpty ? settings.userName : 'You',
      );
      await _persistLocalUser();
    }

    final metaRaw = prefs.getString(_kMetaKey);
    if (metaRaw != null) {
      final map = jsonDecode(metaRaw) as Map<String, dynamic>;
      map.forEach((id, value) {
        _meta[id] =
            EventSharingMeta.fromJson(value as Map<String, dynamic>);
      });
    }

    final actRaw = prefs.getString(_kActivityKey);
    if (actRaw != null) {
      final map = jsonDecode(actRaw) as Map<String, dynamic>;
      map.forEach((id, list) {
        _activities[id] = (list as List<dynamic>)
            .map((e) => SharedActivityEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    }
    notifyListeners();
  }

  Future<void> syncLocalUserName(String name) async {
    if (name.isEmpty || _localUser == null) return;
    if (_localUser!.displayName == name) return;
    _localUser = LocalUserProfile(id: _localUser!.id, displayName: name);
    await _persistLocalUser();
    notifyListeners();
  }

  EventSharingMeta metaFor(String renewalId) {
    return _meta[renewalId] ??
        EventSharingMeta.privateFor(
          renewalId: renewalId,
          ownerId: localUser.id,
          ownerName: localUser.displayName,
        );
  }

  ShareVisibility visibilityFor(String renewalId) => metaFor(renewalId).visibility;

  bool isShared(String renewalId) =>
      visibilityFor(renewalId) == ShareVisibility.shared;

  bool isDocumentShared(EventDocument doc) =>
      doc.linkedRenewalIds.any(isShared);

  bool isOwner(String renewalId) =>
      metaFor(renewalId).ownerId == localUser.id;

  bool isSharedWithMe(String renewalId) {
    final meta = metaFor(renewalId);
    if (!meta.isShared) return false;
    if (meta.ownerId == localUser.id) return false;
    return meta.members.any((m) => m.id == localUser.id);
  }

  SharePermission? myPermission(String renewalId) {
    final meta = metaFor(renewalId);
    if (meta.ownerId == localUser.id) return SharePermission.owner;
    for (final m in meta.members) {
      if (m.id == localUser.id) return m.permission;
    }
    return null;
  }

  bool canEdit(String renewalId) {
    final perm = myPermission(renewalId);
    if (perm == null) return isOwner(renewalId);
    return perm == SharePermission.owner || perm == SharePermission.editor;
  }

  List<SharedActivityEntry> activitiesFor(String renewalId) {
    final list = List<SharedActivityEntry>.from(_activities[renewalId] ?? [])
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  List<Renewal> filterRenewals(
    List<Renewal> source,
    SharingListFilter filter,
  ) {
    return switch (filter) {
      SharingListFilter.all => source,
      SharingListFilter.private =>
        source.where((r) => !isShared(r.id)).toList(),
      SharingListFilter.shared =>
        source.where((r) => isShared(r.id)).toList(),
      SharingListFilter.ownedByMe => source
          .where((r) => isShared(r.id) && isOwner(r.id))
          .toList(),
      SharingListFilter.sharedWithMe => source
          .where((r) => isSharedWithMe(r.id))
          .toList(),
    };
  }

  List<Renewal> sharedWithMeEvents(List<Renewal> all) =>
      filterRenewals(all, SharingListFilter.sharedWithMe);

  List<Renewal> ownedSharedEvents(List<Renewal> all) =>
      filterRenewals(all, SharingListFilter.ownedByMe);

  int pendingActionsCount(List<Renewal> all) {
    return sharedWithMeEvents(all)
        .where(
          (r) =>
              r.status != RenewalStatus.paid &&
              r.status != RenewalStatus.cancelled &&
              (r.isOverdue || r.daysRemaining <= 7),
        )
        .length;
  }

  List<Renewal> recentlyUpdatedShared(List<Renewal> all, {int limit = 5}) {
    final shared = all.where((r) => isShared(r.id)).toList()
      ..sort((a, b) {
        final ua = metaFor(a.id).updatedAt;
        final ub = metaFor(b.id).updatedAt;
        return ub.compareTo(ua);
      });
    return shared.take(limit).toList();
  }

  Future<void> makeShared(String renewalId) async {
    final meta = metaFor(renewalId).copyWith(
      visibility: ShareVisibility.shared,
      updatedAt: DateTime.now(),
    );
    _meta[renewalId] = meta;
    await _record(renewalId, SharedActivityAction.shared);
    await _persist();
  }

  Future<void> makePrivate(String renewalId) async {
    final meta = metaFor(renewalId).copyWith(
      visibility: ShareVisibility.private,
      members: const [],
      updatedAt: DateTime.now(),
    );
    _meta[renewalId] = meta;
    await _record(renewalId, SharedActivityAction.madePrivate);
    await _persist();
  }

  Future<void> addMember(
    String renewalId, {
    required String displayName,
    String? email,
    SharePermission permission = SharePermission.viewer,
  }) async {
    final meta = metaFor(renewalId);
    if (!meta.isShared) await makeShared(renewalId);
    final current = metaFor(renewalId);
    final member = SharedMember(
      id: 'member_${DateTime.now().microsecondsSinceEpoch}',
      displayName: displayName.trim(),
      email: email?.trim(),
      permission: permission,
      avatarHue: Random().nextInt(360),
    );
    _meta[renewalId] = current.copyWith(
      members: [...current.members, member],
      updatedAt: DateTime.now(),
    );
    await _record(
      renewalId,
      SharedActivityAction.memberAdded,
      detail: '${member.displayName} (${member.permission.label})',
    );
    await _persist();
  }

  Future<void> removeMember(String renewalId, String memberId) async {
    final current = metaFor(renewalId);
    final removed = current.members.where((m) => m.id == memberId).toList();
    _meta[renewalId] = current.copyWith(
      members: current.members.where((m) => m.id != memberId).toList(),
      updatedAt: DateTime.now(),
    );
    if (removed.isNotEmpty) {
      await _record(
        renewalId,
        SharedActivityAction.memberRemoved,
        detail: removed.first.displayName,
      );
    }
    await _persist();
  }

  Future<void> updateMemberPermission(
    String renewalId,
    String memberId,
    SharePermission permission,
  ) async {
    final current = metaFor(renewalId);
    _meta[renewalId] = current.copyWith(
      members: current.members
          .map((m) => m.id == memberId ? m.copyWith(permission: permission) : m)
          .toList(),
      updatedAt: DateTime.now(),
    );
    await _record(renewalId, SharedActivityAction.edited, detail: 'Permissions updated');
    await _persist();
  }

  Future<void> recordExternalActivity(
    String renewalId,
    SharedActivityAction action, {
    String? detail,
  }) async {
    await _record(renewalId, action, detail: detail);
    final current = metaFor(renewalId);
    _meta[renewalId] = current.copyWith(updatedAt: DateTime.now());
    await _persist();
  }

  Future<void> clearForEvent(String renewalId) async {
    _meta.remove(renewalId);
    _activities.remove(renewalId);
    await _persist();
  }

  Future<void> _record(
    String renewalId,
    SharedActivityAction action, {
    String? detail,
  }) async {
    final entry = SharedActivityEntry(
      action: action,
      actorName: localUser.displayName,
      timestamp: DateTime.now(),
      detail: detail,
    );
    final list = _activities.putIfAbsent(renewalId, () => []);
    list.insert(0, entry);
  }

  Future<void> _persistLocalUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocalUserKey, jsonEncode(_localUser!.toJson()));
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kMetaKey,
      jsonEncode(_meta.map((k, v) => MapEntry(k, v.toJson()))),
    );
    await prefs.setString(
      _kActivityKey,
      jsonEncode(
        _activities.map(
          (k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()),
        ),
      ),
    );
    notifyListeners();
  }

  // ─── Developer / demo ──────────────────────────────────────────────────────

  Future<void> generateDemoSharedEvents(RenewalService renewalService) async {
    final events = renewalService.renewals
        .where((r) => r.status != RenewalStatus.cancelled)
        .take(3)
        .toList();
    for (final r in events) {
      await makeShared(r.id);
      await addMember(
        r.id,
        displayName: 'Alex',
        email: 'alex@family.local',
        permission: SharePermission.editor,
      );
      await addMember(
        r.id,
        displayName: 'Sam',
        email: 'sam@family.local',
        permission: SharePermission.viewer,
      );
    }
  }

  Future<void> generateDemoSharedWithMe(RenewalService renewalService) async {
    final events = renewalService.renewals
        .where((r) => r.status != RenewalStatus.cancelled)
        .skip(3)
        .take(2)
        .toList();
    for (final r in events) {
      _meta[r.id] = EventSharingMeta(
        renewalId: r.id,
        visibility: ShareVisibility.shared,
        ownerId: 'demo_owner',
        ownerName: 'Jordan',
        members: [
          SharedMember(
            id: localUser.id,
            displayName: localUser.displayName,
            permission: SharePermission.editor,
            avatarHue: 160,
          ),
        ],
        updatedAt: DateTime.now(),
      );
      await _record(
        r.id,
        SharedActivityAction.shared,
        detail: 'Shared with ${localUser.displayName}',
      );
    }
    await _persist();
  }

  Future<void> generateDemoActivityTimeline(String renewalId) async {
    final actions = SharedActivityAction.values;
    for (var i = 0; i < actions.length; i++) {
      _activities.putIfAbsent(renewalId, () => []).add(
            SharedActivityEntry(
              action: actions[i],
              actorName: i.isEven ? localUser.displayName : 'Alex',
              timestamp: DateTime.now().subtract(Duration(hours: i * 6)),
              detail: 'Demo activity',
            ),
          );
    }
    await _persist();
  }

  Future<void> markLinkedDocumentsShared(EventExtrasService extras) async {
    for (final doc in extras.allDocuments) {
      if (doc.linkedRenewalIds.any(isShared)) {
        for (final rid in doc.linkedRenewalIds.where(isShared)) {
          await recordExternalActivity(
            rid,
            SharedActivityAction.documentAdded,
            detail: doc.name,
          );
        }
      }
    }
  }

  Future<void> clearAllSharing() async {
    _meta.clear();
    _activities.clear();
    await _persist();
  }
}
