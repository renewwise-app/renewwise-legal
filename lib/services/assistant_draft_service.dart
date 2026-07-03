import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:renew_wise/models/assistant_draft.dart';
import 'package:renew_wise/models/backup_models.dart';
import 'package:renew_wise/models/renewal_priority.dart';

/// Persists in-progress assistant conversations (no SQLite changes).
class AssistantDraftService extends ChangeNotifier {
  static const _kDraftKey = 'assistant_draft_v1';

  AssistantDraft? _draft;

  bool get hasDraft => _draft != null && _draft!.hasContent;

  AssistantDraft? get draft => _draft;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kDraftKey);
    if (raw == null) return;
    _draft = AssistantDraft.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> saveDraft(AssistantDraft draft) async {
    _draft = draft.copyWith(updatedAt: DateTime.now());
    await _persist();
  }

  Future<void> clearDraft() async {
    _draft = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDraftKey);
    notifyListeners();
  }

  Future<void> _persist() async {
    if (_draft == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDraftKey, jsonEncode(_draft!.toJson()));
    notifyListeners();
  }

  Future<void> generateSampleDraft() async {
    _draft = AssistantDraft(
      step: AssistantStep.question2,
      title: 'Car Insurance Renewal',
      categoryId: 'insurance',
      renewalDate: DateTime.now().add(const Duration(days: 45)),
      amount: 12500,
      priority: RenewalPriority.medium,
      reminderSchedule: const [30, 7, 1],
      notes: 'Policy #RW-2026-001',
      tags: const ['important'],
      updatedAt: DateTime.now(),
    );
    await _persist();
  }

  Future<void> generateDraftOnly() async {
    _draft = AssistantDraft(
      step: AssistantStep.question1,
      title: 'Passport Renewal',
      categoryId: 'passport',
      updatedAt: DateTime.now(),
    );
    await _persist();
  }

  Future<void> generateDraftWithNotes() async {
    _draft = AssistantDraft(
      step: AssistantStep.question5,
      title: 'Health Insurance',
      categoryId: 'medical',
      renewalDate: DateTime.now().add(const Duration(days: 30)),
      amount: 8500,
      reminderSchedule: const [30, 7, 1],
      notes: 'Renew through employer portal. Policy number: HI-99201.',
      tags: const ['medical', 'annual'],
      updatedAt: DateTime.now(),
    );
    await _persist();
  }

  Future<void> generateDraftWithAttachments() async {
    _draft = AssistantDraft(
      step: AssistantStep.question4,
      title: 'Vehicle Registration',
      categoryId: 'vehicle',
      renewalDate: DateTime.now().add(const Duration(days: 60)),
      reminderSchedule: const [30, 7, 1],
      attachments: const [
        AssistantAttachment(
          id: 'demo_doc_1',
          path: 'demo://policy.pdf',
          name: 'policy.pdf',
          isImage: false,
        ),
      ],
      updatedAt: DateTime.now(),
    );
    await _persist();
  }

  Map<String, dynamic>? exportSnapshot() =>
      _draft?.toJson();

  Future<void> importSnapshot(
    Map<String, dynamic>? json, {
    required RestoreConflictMode mode,
  }) async {
    if (json == null) return;
    if (mode == RestoreConflictMode.merge && hasDraft) return;
    _draft = AssistantDraft.fromJson(json);
    await _persist();
  }

  Future<void> clearForBackupReplace() async => clearDraft();
}
