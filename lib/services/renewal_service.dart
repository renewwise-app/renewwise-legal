// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:renew_wise/models/backup_models.dart';
import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/renewal_category.dart';
import 'package:renew_wise/models/renewal_currency.dart';
import 'package:renew_wise/models/renewal_priority.dart';
import 'package:renew_wise/models/renewal_status.dart';
import 'package:renew_wise/repository/renewal_repository.dart';
import 'package:renew_wise/services/notification_service.dart';

class RenewalService extends ChangeNotifier {
  RenewalService({
    required RenewalRepository repository,
    required NotificationService notificationService,
  })  : _repository = repository,
        _notificationService = notificationService;

  final RenewalRepository _repository;
  final NotificationService _notificationService;

  final List<Renewal> _renewals = [];

  List<Renewal> get renewals => List.unmodifiable(_renewals);

  // ─── Startup ───────────────────────────────────────────────────────────────

  /// Load all renewals from the repository. Call once at app startup.
  Future<void> loadRenewals() async {
    _renewals
      ..clear()
      ..addAll(await _repository.loadAll());
    _sortByDate();
    notifyListeners();
  }

  // ─── Home-screen stats ─────────────────────────────────────────────────────

  int get upcomingCount =>
      _renewals.where((r) => r.status != RenewalStatus.cancelled).length;

  int get overdueCount => _renewals
      .where((r) => r.isOverdue && r.status != RenewalStatus.cancelled)
      .length;

  int get criticalCount => criticalRenewals.length;

  /// Overdue or critical-priority active events.
  List<Renewal> get criticalRenewals => _renewals
      .where(
        (r) =>
            r.status != RenewalStatus.cancelled &&
            r.status != RenewalStatus.paid &&
            (r.isOverdue || r.priority == RenewalPriority.critical),
      )
      .toList();

  /// Active events that are not overdue and not critical-priority.
  List<Renewal> get upcomingRenewals => _renewals
      .where(
        (r) =>
            r.status != RenewalStatus.cancelled &&
            r.status != RenewalStatus.paid &&
            !r.isOverdue &&
            r.priority != RenewalPriority.critical,
      )
      .toList();

  /// Completed (paid) events.
  List<Renewal> get completedRenewals =>
      _renewals.where((r) => r.status == RenewalStatus.paid).toList();

  int get completedCount => completedRenewals.length;

  int get upcomingOnlyCount => upcomingRenewals.length;

  /// Active events with a payment amount.
  List<Renewal> get paymentDueRenewals => _renewals
      .where(
        (r) =>
            r.status != RenewalStatus.cancelled &&
            r.status != RenewalStatus.paid &&
            r.paymentRequired &&
            r.amount != null,
      )
      .toList();

  int get criticalTodayCount => criticalRenewals
      .where((r) => r.daysRemaining == 0)
      .length;

  /// Payment renewals due in the current calendar month.
  List<Renewal> get dueThisMonthRenewals {
    final now = DateTime.now();
    return _renewals
        .where(
          (r) =>
              r.status != RenewalStatus.cancelled &&
              r.status != RenewalStatus.paid &&
              r.paymentRequired &&
              r.amount != null &&
              r.renewalDate.year == now.year &&
              r.renewalDate.month == now.month,
        )
        .toList();
  }

  double get dueThisMonthTotal => dueThisMonthRenewals.fold<double>(
        0,
        (sum, r) => sum + (r.amount ?? 0),
      );

  /// Category breakdown for payment renewals due this month.
  List<({RenewalCategory category, int count, double amount})>
      get dueThisMonthCategoryBreakdown =>
          _categoryTotalsFromList(dueThisMonthRenewals);

  bool get hasPaidRenewals => _renewals
      .any((r) => r.paymentRequired && r.status != RenewalStatus.cancelled);

  Map<RenewalCurrency, double> get estimatedCost {
    final totals = <RenewalCurrency, double>{};
    for (final r in _renewals) {
      if (r.paymentRequired &&
          r.amount != null &&
          r.status != RenewalStatus.cancelled) {
        totals.update(
          r.currency,
          (v) => v + r.amount!,
          ifAbsent: () => r.amount!,
        );
      }
    }
    return totals;
  }

  String get formattedEstimatedCost {
    final costs = estimatedCost;
    if (costs.isEmpty) return '';
    return costs.entries.map((e) => e.key.formatAmount(e.value)).join(' + ');
  }

  Renewal? get nearestRenewal {
    if (_renewals.isEmpty) return null;
    return _renewals.reduce(
      (a, b) => a.renewalDate.isBefore(b.renewalDate) ? a : b,
    );
  }

  // ─── Statistics – global ──────────────────────────────────────────────────

  int get totalRenewalCount => upcomingCount;

  int get paymentRenewalCount => _renewals
      .where((r) => r.paymentRequired && r.status != RenewalStatus.cancelled)
      .length;

  int get nonPaymentRenewalCount => _renewals
      .where((r) => !r.paymentRequired && r.status != RenewalStatus.cancelled)
      .length;

  RenewalCurrency get primaryCurrency {
    final freqs = <RenewalCurrency, int>{};
    for (final r in _renewals) {
      if (r.paymentRequired && r.status != RenewalStatus.cancelled) {
        freqs[r.currency] = (freqs[r.currency] ?? 0) + 1;
      }
    }
    if (freqs.isEmpty) return RenewalCurrency.inr;
    return freqs.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  Renewal? get largestRenewal {
    final candidates = _renewals
        .where(
          (r) =>
              r.paymentRequired &&
              r.amount != null &&
              r.status != RenewalStatus.cancelled,
        )
        .toList();
    if (candidates.isEmpty) return null;
    return candidates.reduce((a, b) => a.amount! > b.amount! ? a : b);
  }

  List<({RenewalCategory category, int count, double amount})>
      get categoryTotals => _categoryTotalsFromList(
            _renewals.where((r) => r.status != RenewalStatus.cancelled),
          );

  ({int count, double amount}) get next30DayCost => _upcomingCost(30);
  ({int count, double amount}) get next90DayCost => _upcomingCost(90);
  ({int count, double amount}) get next365DayCost => _upcomingCost(365);

  // ─── Statistics – navigable month/year ────────────────────────────────────

  /// Detailed summary for a specific calendar month.
  ({
    int count,
    double amount,
    Renewal? largest,
    List<RenewalCategory> categories,
  }) monthlySummaryFor(int year, int month) {
    final inMonth = _renewals
        .where(
          (r) =>
              r.status != RenewalStatus.cancelled &&
              r.renewalDate.year == year &&
              r.renewalDate.month == month,
        )
        .toList();

    final paymentList = inMonth
        .where((r) => r.paymentRequired && r.amount != null)
        .toList();
    final amount =
        paymentList.fold<double>(0, (s, r) => s + r.amount!);
    final largest = paymentList.isEmpty
        ? null
        : paymentList.reduce((a, b) => a.amount! > b.amount! ? a : b);
    final categories = inMonth.map((r) => r.category).toSet().toList();

    return (
      count: inMonth.length,
      amount: amount,
      largest: largest,
      categories: categories,
    );
  }

  /// Summary for a specific calendar year.
  ({int count, double amount, double avgMonthly}) yearlySummaryFor(int year) {
    final inYear = _renewals.where(
      (r) => r.status != RenewalStatus.cancelled && r.renewalDate.year == year,
    );
    final count = inYear.length;
    final amount = inYear
        .where((r) => r.paymentRequired && r.amount != null)
        .fold<double>(0, (s, r) => s + r.amount!);
    return (count: count, amount: amount, avgMonthly: amount / 12);
  }

  /// Category breakdown for a specific calendar year.
  List<({RenewalCategory category, int count, double amount})>
      categoryTotalsFor(int year) => _categoryTotalsFromList(
            _renewals.where(
              (r) =>
                  r.status != RenewalStatus.cancelled &&
                  r.renewalDate.year == year,
            ),
          );

  // ─── Legacy monthly/yearly (uses current date, kept for Stats overview) ───

  ({int count, double amount}) get monthlySummary {
    final now = DateTime.now();
    final s = monthlySummaryFor(now.year, now.month);
    return (count: s.count, amount: s.amount);
  }

  ({int count, double amount, double avgMonthly}) get yearlySummary =>
      yearlySummaryFor(DateTime.now().year);

  // ─── Mutations ─────────────────────────────────────────────────────────────

  void addRenewal(Renewal renewal) {
    _renewals.add(renewal);
    _sortByDate();
    notifyListeners();
    unawaited(_repository.insert(renewal));
    unawaited(_notificationService.scheduleReminders(renewal));
  }

  void updateRenewal(Renewal updated) {
    final idx = _renewals.indexWhere((r) => r.id == updated.id);
    if (idx < 0) return;
    _renewals[idx] = updated;
    _sortByDate();
    notifyListeners();
    unawaited(_repository.update(updated));
    unawaited(_notificationService.cancelReminders(updated.id));
    unawaited(_notificationService.scheduleReminders(updated));
  }

  void deleteRenewal(String id) {
    _renewals.removeWhere((r) => r.id == id);
    notifyListeners();
    unawaited(_repository.delete(id));
    unawaited(_notificationService.cancelReminders(id));
  }

  /// Remove every renewal and cancel all scheduled notifications.
  Future<void> clearAll() async {
    await _notificationService.cancelAll();
    _renewals.clear();
    notifyListeners();
    await _repository.clearAll();
  }

  Future<List<Map<String, dynamic>>> exportRenewalRows() =>
      _repository.exportAllRows();

  Future<void> importRenewalRows(
    List<Map<String, dynamic>> rows, {
    required RestoreConflictMode mode,
  }) async {
    if (mode == RestoreConflictMode.replace) {
      await _notificationService.cancelAll();
      await _repository.replaceAllRows(rows);
      await loadRenewals();
      await resyncAllReminders();
      return;
    }

    final byId = {
      for (final r in await _repository.exportAllRows()) r['id'] as String: r,
    };
    for (final row in rows) {
      final id = row['id'] as String;
      final localRow = byId[id];
      if (localRow == null) {
        byId[id] = row;
        continue;
      }
      final backupUpdated =
          DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int);
      final localUpdated = DateTime.fromMillisecondsSinceEpoch(
        localRow['updated_at'] as int,
      );
      if (backupUpdated.isAfter(localUpdated)) {
        byId[id] = row;
      }
    }
    await _repository.replaceAllRows(byId.values.toList());
    await loadRenewals();
    await resyncAllReminders();
  }

  Future<void> resyncAllReminders() async {
    await _notificationService.cancelAll();
    for (final r in _renewals) {
      if (r.status != RenewalStatus.cancelled &&
          r.status != RenewalStatus.paid) {
        await _notificationService.scheduleReminders(r);
      }
    }
  }

  Map<String, dynamic> exportStatisticsSnapshot() => {
        'upcomingCount': upcomingCount,
        'overdueCount': overdueCount,
        'criticalCount': criticalCount,
        'completedCount': completedCount,
        'exportedAt': DateTime.now().toIso8601String(),
      };

  // ─── Internals ─────────────────────────────────────────────────────────────

  void _sortByDate() {
    _renewals.sort((a, b) => a.renewalDate.compareTo(b.renewalDate));
  }

  ({int count, double amount}) _upcomingCost(int days) {
    final inWindow = _renewals.where((r) {
      final d = r.daysRemaining;
      return r.status != RenewalStatus.cancelled && d >= 0 && d <= days;
    });
    return (
      count: inWindow.length,
      amount: inWindow
          .where((r) => r.paymentRequired && r.amount != null)
          .fold<double>(0, (s, r) => s + r.amount!),
    );
  }

  List<({RenewalCategory category, int count, double amount})>
      _categoryTotalsFromList(Iterable<Renewal> source) {
    final map = <RenewalCategory, ({int count, double amount})>{};
    for (final r in source) {
      final prev = map[r.category];
      final add = (r.paymentRequired && r.amount != null) ? r.amount! : 0.0;
      map[r.category] = prev == null
          ? (count: 1, amount: add)
          : (count: prev.count + 1, amount: prev.amount + add);
    }
    return (map.entries
          .map(
            (e) => (
              category: e.key,
              count: e.value.count,
              amount: e.value.amount,
            ),
          )
          .toList()
        ..sort((a, b) => b.amount.compareTo(a.amount)));
  }
}
