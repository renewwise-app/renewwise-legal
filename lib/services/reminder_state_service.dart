import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:renew_wise/models/history_entry.dart';
import 'package:renew_wise/models/backup_models.dart';
import 'package:renew_wise/models/reminder_state.dart';
import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/renewal_category.dart';
import 'package:renew_wise/models/renewal_currency.dart';
import 'package:renew_wise/models/renewal_status.dart';
import 'package:renew_wise/repository/history_repository.dart';
import 'package:renew_wise/repository/shared_preferences_history_repository.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/utils/history_filter.dart';
import 'package:renew_wise/utils/history_sort.dart';

/// Persists reminder metadata and history outside SQLite (no schema changes).
class ReminderStateService extends ChangeNotifier {
  ReminderStateService({HistoryRepository? historyRepository})
      : _historyRepository =
            historyRepository ?? SharedPreferencesHistoryRepository();

  static const _kStatesKey = 'reminder_states_v1';

  final HistoryRepository _historyRepository;

  final Map<String, ReminderState> _states = {};
  final List<HistoryEntry> _history = [];
  List<HistoryEntry>? _historyBackup;

  List<HistoryEntry> get history => List.unmodifiable(_history);

  bool get hasUnviewedMissedReminders =>
      _states.values.any((s) => s.missed && !s.missedViewed);

  int get unviewedMissedCount =>
      _states.values.where((s) => s.missed && !s.missedViewed).length;

  HistoryEntry? entryById(String id) {
    try {
      return _history.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final statesRaw = prefs.getString(_kStatesKey);
    if (statesRaw != null) {
      final map = jsonDecode(statesRaw) as Map<String, dynamic>;
      map.forEach((id, value) {
        _states[id] =
            ReminderState.fromJson(value as Map<String, dynamic>);
      });
    }
    final historyRaw = await _historyRepository.loadAll();
    _history
      ..clear()
      ..addAll(historyRaw);
  }

  ReminderState stateFor(String renewalId) =>
      _states[renewalId] ?? const ReminderState();

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final statesJson = _states.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(_kStatesKey, jsonEncode(statesJson));
    await _historyRepository.saveAll(_history);
    notifyListeners();
  }

  Future<void> recordReminderSent(String renewalId, DateTime when) async {
    final prev = stateFor(renewalId);
    _states[renewalId] = prev.copyWith(
      lastReminderSent: when,
      nextReminder: when,
      acknowledged: false,
    );
    await _persist();
  }

  Future<void> markAcknowledged(String renewalId) async {
    final prev = stateFor(renewalId);
    _states[renewalId] = prev.copyWith(acknowledged: true, missed: false);
    await _persist();
  }

  Future<void> markSnoozed(String renewalId, DateTime until) async {
    final prev = stateFor(renewalId);
    _states[renewalId] = prev.copyWith(
      snoozedUntil: until,
      nextReminder: until,
      acknowledged: false,
      missed: false,
    );
    await _persist();
  }

  Future<void> markMissed(String renewalId) async {
    final prev = stateFor(renewalId);
    if (prev.completed) return;
    _states[renewalId] = prev.copyWith(missed: true, missedViewed: false);
    await _persist();
  }

  Future<void> markMissedViewed() async {
    var changed = false;
    for (final id in _states.keys.toList()) {
      final s = _states[id]!;
      if (s.missed && !s.missedViewed) {
        _states[id] = s.copyWith(missedViewed: true);
        changed = true;
      }
    }
    if (changed) await _persist();
  }

  List<Renewal> activeMissedRenewals(List<Renewal> renewals) {
    return renewals.where((r) {
      if (r.status == RenewalStatus.paid ||
          r.status == RenewalStatus.cancelled) {
        return false;
      }
      final s = stateFor(r.id);
      return s.missed && !s.completed;
    }).toList();
  }

  Future<void> evaluateMissedReminders(List<Renewal> renewals) async {
    final now = DateTime.now();
    var changed = false;
    for (final r in renewals) {
      if (r.status == RenewalStatus.paid ||
          r.status == RenewalStatus.cancelled) {
        continue;
      }
      final s = stateFor(r.id);
      if (s.completed || s.acknowledged) continue;

      var shouldMiss = false;

      if (r.isOverdue) {
        shouldMiss = true;
      }

      final snoozedUntil = s.snoozedUntil;
      if (snoozedUntil != null && now.isAfter(snoozedUntil)) {
        shouldMiss = true;
      }

      final sent = s.lastReminderSent;
      if (sent != null && now.difference(sent).inHours >= 1) {
        shouldMiss = true;
      }

      if (shouldMiss && !s.missed) {
        _states[r.id] = s.copyWith(missed: true, missedViewed: false);
        changed = true;
      }
    }
    if (changed) await _persist();
  }

  Future<void> recordCompletion({
    required Renewal renewal,
    required String method,
  }) async {
    final now = DateTime.now();
    _states[renewal.id] = stateFor(renewal.id).copyWith(
      completed: true,
      completionDate: now,
      completionMethod: method,
      acknowledged: true,
      missed: false,
    );
    _history.insert(
      0,
      HistoryEntry(
        id: '${renewal.id}_${now.millisecondsSinceEpoch}',
        renewalId: renewal.id,
        title: renewal.title,
        categoryLabel: renewal.categoryLabel,
        category: renewal.category,
        completionDate: now,
        completionMethod: method,
        originalRenewalDate: renewal.renewalDate,
        amount: renewal.amount,
        currencyCode: renewal.currency.name,
        notes: renewal.notes,
        reminderSchedule: renewal.reminderSchedule,
        paymentRequired: renewal.paymentRequired,
        customEventType: renewal.customEventType,
      ),
    );
    await _persist();
  }

  Future<void> clearCompletionForNextOccurrence(String renewalId) async {
    _states[renewalId] = stateFor(renewalId).copyWith(
      completed: false,
      clearCompletionDate: true,
      clearCompletionMethod: true,
      acknowledged: false,
      missed: false,
      missedViewed: false,
    );
    await _persist();
  }

  Future<void> deleteHistoryEntry(String id) async {
    _history.removeWhere((e) => e.id == id);
    await _persist();
  }

  Future<void> markEntryRestored(String id) async {
    final idx = _history.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    _history[idx] = _history[idx].copyWith(
      restored: true,
      restoredAt: DateTime.now(),
    );
    await _persist();
  }

  /// Restores the linked renewal to active status from a history entry.
  Future<Renewal?> restoreFromHistory({
    required HistoryEntry entry,
    required RenewalService renewalService,
  }) async {
    Renewal? existing;
    try {
      existing = renewalService.renewals.firstWhere(
        (r) => r.id == entry.renewalId,
      );
    } catch (_) {
      existing = null;
    }

    final now = DateTime.now();
    Renewal restored;
    if (existing != null) {
      restored = existing.copyWith(
        status: RenewalStatus.upcoming,
        updatedAt: now,
      );
      renewalService.updateRenewal(restored);
    } else {
      restored = Renewal(
        id: entry.renewalId,
        title: entry.title,
        category: entry.category,
        customEventType: entry.customEventType,
        renewalDate: entry.originalRenewalDate,
        paymentRequired: entry.paymentRequired,
        amount: entry.amount,
        currency: entry.currencyCode != null
            ? RenewalCurrency.values.byName(entry.currencyCode!)
            : RenewalCurrency.inr,
        reminderSchedule: entry.reminderSchedule,
        notes: entry.notes,
        createdAt: now,
        updatedAt: now,
      );
      renewalService.addRenewal(restored);
    }

    _states[entry.renewalId] = stateFor(entry.renewalId).copyWith(
      completed: false,
      clearCompletionDate: true,
      clearCompletionMethod: true,
      acknowledged: false,
      missed: false,
    );
    await markEntryRestored(entry.id);
    return restored;
  }

  Future<void> clearHistory() async {
    _historyBackup = List<HistoryEntry>.from(_history);
    _history.clear();
    await _persist();
  }

  Future<void> restoreAllHistory() async {
    if (_historyBackup == null || _historyBackup!.isEmpty) return;
    _history
      ..clear()
      ..addAll(_historyBackup!);
    await _persist();
  }

  Future<void> generateDemoHistory() async {
    final now = DateTime.now();
    final lastMonthDay = DateTime(now.year, now.month, 1)
        .subtract(const Duration(days: 15));
    final demos = <HistoryEntry>[
      _demoEntry(
        id: 'demo_passport',
        renewalId: 'demo_r_passport',
        title: 'Passport Renewal',
        category: RenewalCategory.passport,
        completed: DateTime(now.year, now.month, now.day, 10, 30),
        original: DateTime(now.year, now.month, now.day),
        method: 'app',
        amount: 1500,
      ),
      _demoEntry(
        id: 'demo_insurance',
        renewalId: 'demo_r_insurance',
        title: 'Insurance Payment',
        category: RenewalCategory.insurance,
        completed: DateTime(now.year, now.month, now.day, 14, 15),
        original: DateTime(now.year, now.month, now.day - 1),
        method: 'notification',
        amount: 8500,
      ),
      _demoEntry(
        id: 'demo_electricity',
        renewalId: 'demo_r_electricity',
        title: 'Electricity Bill',
        category: RenewalCategory.electricity,
        completed: DateTime(now.year, now.month, now.day - 1, 20, 40),
        original: DateTime(now.year, now.month, now.day - 1),
        method: 'app',
        amount: 2200,
      ),
      _demoEntry(
        id: 'demo_gym',
        renewalId: 'demo_r_gym',
        title: 'Gym Membership',
        category: RenewalCategory.gym,
        completed: DateTime(
          lastMonthDay.year,
          lastMonthDay.month,
          lastMonthDay.day,
          9,
          0,
        ),
        original: lastMonthDay,
        method: 'notification',
        amount: 1999,
      ),
    ];

    for (final entry in demos) {
      if (_history.any((e) => e.id == entry.id)) continue;
      _history.add(entry);
    }
    HistorySortUtils.sort(_history, HistorySortOption.newestFirst);
    await _persist();
  }

  HistoryEntry _demoEntry({
    required String id,
    required String renewalId,
    required String title,
    required RenewalCategory category,
    required DateTime completed,
    required DateTime original,
    required String method,
    required double amount,
  }) {
    return HistoryEntry(
      id: id,
      renewalId: renewalId,
      title: title,
      categoryLabel: category.label,
      category: category,
      completionDate: completed,
      completionMethod: method,
      originalRenewalDate: original,
      amount: amount,
      currencyCode: RenewalCurrency.inr.name,
      paymentRequired: true,
      notes: 'Demo history entry',
      reminderSchedule: const [30, 7, 1],
    );
  }

  Future<void> clearState(String renewalId) async {
    _states.remove(renewalId);
    await _persist();
  }

  Map<String, dynamic> exportSnapshot() => {
        'states': _states.map((k, v) => MapEntry(k, v.toJson())),
        'history': _history.map((e) => e.toJson()).toList(),
      };

  Future<void> importSnapshot(
    Map<String, dynamic> data, {
    required RestoreConflictMode mode,
  }) async {
    final statesRaw = data['states'] as Map<String, dynamic>? ?? {};
    final historyRaw = data['history'] as List<dynamic>? ?? [];

    if (mode == RestoreConflictMode.replace) {
      _states.clear();
      _history.clear();
    }

    statesRaw.forEach((id, value) {
      if (mode == RestoreConflictMode.merge && _states.containsKey(id)) return;
      _states[id] =
          ReminderState.fromJson(value as Map<String, dynamic>);
    });

    for (final item in historyRaw) {
      final entry = HistoryEntry.fromJson(item as Map<String, dynamic>);
      if (mode == RestoreConflictMode.merge &&
          _history.any((e) => e.id == entry.id)) {
        continue;
      }
      _history.add(entry);
    }
    HistorySortUtils.sort(_history, HistorySortOption.newestFirst);
    await _persist();
  }

  Future<void> replaceAllFromBackup(Map<String, dynamic> data) async {
    await importSnapshot(data, mode: RestoreConflictMode.replace);
  }
}
