import 'package:flutter/material.dart';

/// Local-only sharing visibility (v1 — no cloud sync yet).
enum ShareVisibility {
  private('Private', Icons.lock_outline_rounded),
  shared('Shared', Icons.groups_outlined);

  const ShareVisibility(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum SharePermission {
  owner('Owner', 'Full control'),
  editor('Editor', 'Can update reminder details'),
  viewer('Viewer', 'Read only');

  const SharePermission(this.label, this.description);
  final String label;
  final String description;
}

enum SharingListFilter {
  all('All'),
  private('Private'),
  shared('Shared'),
  ownedByMe('Owned By Me'),
  sharedWithMe('Shared With Me');

  const SharingListFilter(this.label);
  final String label;
}

enum SharedActivityAction {
  created('Created'),
  edited('Edited'),
  reminderChanged('Reminder Changed'),
  completed('Completed'),
  documentAdded('Document Added'),
  memberAdded('Member Added'),
  memberRemoved('Member Removed'),
  shared('Shared'),
  madePrivate('Made Private');

  const SharedActivityAction(this.label);
  final String label;
}

class LocalUserProfile {
  const LocalUserProfile({required this.id, required this.displayName});

  final String id;
  final String displayName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
      };

  factory LocalUserProfile.fromJson(Map<String, dynamic> json) =>
      LocalUserProfile(
        id: json['id'] as String,
        displayName: json['displayName'] as String? ?? 'You',
      );
}

class SharedMember {
  const SharedMember({
    required this.id,
    required this.displayName,
    required this.permission,
    this.email,
    this.avatarHue = 200,
  });

  final String id;
  final String displayName;
  final String? email;
  final SharePermission permission;
  final int avatarHue;

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        if (email != null) 'email': email,
        'permission': permission.name,
        'avatarHue': avatarHue,
      };

  factory SharedMember.fromJson(Map<String, dynamic> json) => SharedMember(
        id: json['id'] as String,
        displayName: json['displayName'] as String? ?? 'Member',
        email: json['email'] as String?,
        permission: SharePermission.values.firstWhere(
          (p) => p.name == json['permission'],
          orElse: () => SharePermission.viewer,
        ),
        avatarHue: json['avatarHue'] as int? ?? 200,
      );

  SharedMember copyWith({
    SharePermission? permission,
    String? displayName,
  }) =>
      SharedMember(
        id: id,
        displayName: displayName ?? this.displayName,
        email: email,
        permission: permission ?? this.permission,
        avatarHue: avatarHue,
      );
}

class EventSharingMeta {
  const EventSharingMeta({
    required this.renewalId,
    required this.visibility,
    required this.ownerId,
    required this.ownerName,
    this.members = const [],
    required this.updatedAt,
  });

  final String renewalId;
  final ShareVisibility visibility;
  final String ownerId;
  final String ownerName;
  final List<SharedMember> members;
  final DateTime updatedAt;

  bool get isShared => visibility == ShareVisibility.shared;

  SharedMember get ownerMember => SharedMember(
        id: ownerId,
        displayName: ownerName,
        permission: SharePermission.owner,
        avatarHue: ownerName.hashCode % 360,
      );

  Map<String, dynamic> toJson() => {
        'renewalId': renewalId,
        'visibility': visibility.name,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'members': members.map((m) => m.toJson()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory EventSharingMeta.fromJson(Map<String, dynamic> json) =>
      EventSharingMeta(
        renewalId: json['renewalId'] as String,
        visibility: ShareVisibility.values.firstWhere(
          (v) => v.name == json['visibility'],
          orElse: () => ShareVisibility.private,
        ),
        ownerId: json['ownerId'] as String,
        ownerName: json['ownerName'] as String? ?? 'Owner',
        members: (json['members'] as List<dynamic>? ?? [])
            .map((m) => SharedMember.fromJson(m as Map<String, dynamic>))
            .toList(),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  factory EventSharingMeta.privateFor({
    required String renewalId,
    required String ownerId,
    required String ownerName,
  }) =>
      EventSharingMeta(
        renewalId: renewalId,
        visibility: ShareVisibility.private,
        ownerId: ownerId,
        ownerName: ownerName,
        updatedAt: DateTime.now(),
      );

  EventSharingMeta copyWith({
    ShareVisibility? visibility,
    List<SharedMember>? members,
    DateTime? updatedAt,
  }) =>
      EventSharingMeta(
        renewalId: renewalId,
        visibility: visibility ?? this.visibility,
        ownerId: ownerId,
        ownerName: ownerName,
        members: members ?? this.members,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class SharedActivityEntry {
  const SharedActivityEntry({
    required this.action,
    required this.actorName,
    required this.timestamp,
    this.detail,
  });

  final SharedActivityAction action;
  final String actorName;
  final DateTime timestamp;
  final String? detail;

  Map<String, dynamic> toJson() => {
        'action': action.name,
        'actorName': actorName,
        'timestamp': timestamp.toIso8601String(),
        if (detail != null) 'detail': detail,
      };

  factory SharedActivityEntry.fromJson(Map<String, dynamic> json) =>
      SharedActivityEntry(
        action: SharedActivityAction.values.firstWhere(
          (a) => a.name == json['action'],
          orElse: () => SharedActivityAction.edited,
        ),
        actorName: json['actorName'] as String? ?? 'Someone',
        timestamp: DateTime.parse(json['timestamp'] as String),
        detail: json['detail'] as String?,
      );
}
