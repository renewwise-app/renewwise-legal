import 'package:renew_wise/models/history_entry.dart';
import 'package:renew_wise/models/renewal_currency.dart';

class HistoryStats {
  const HistoryStats({
    required this.completedThisMonth,
    required this.completedThisYear,
    required this.completionRate,
    required this.totalMoneyPaid,
    required this.averageCompletionDays,
    required this.primaryCurrency,
  });

  final int completedThisMonth;
  final int completedThisYear;
  final double completionRate;
  final double totalMoneyPaid;
  final double averageCompletionDays;
  final RenewalCurrency primaryCurrency;

  String get formattedTotalPaid => primaryCurrency.formatAmount(totalMoneyPaid);

  String get formattedAverageCompletion {
    if (averageCompletionDays == 0) return '—';
    final abs = averageCompletionDays.abs();
    final early = averageCompletionDays < 0;
    final label = abs == 1 ? '1 day' : '${abs.toStringAsFixed(0)} days';
    return early ? '$label early' : '$label after due';
  }
}

abstract final class HistoryStatsCalculator {
  static HistoryStats compute({
    required List<HistoryEntry> history,
    required int activeEventCount,
  }) {
    final now = DateTime.now();
    final thisMonth = history
        .where(
          (e) =>
              e.completionDate.year == now.year &&
              e.completionDate.month == now.month,
        )
        .length;
    final thisYear =
        history.where((e) => e.completionDate.year == now.year).length;

    final totalEvents = history.length + activeEventCount;
    final rate =
        totalEvents == 0 ? 0.0 : (history.length / totalEvents) * 100;

    final currencyFreq = <RenewalCurrency, int>{};
    var totalPaid = 0.0;
    for (final e in history) {
      if (e.amount != null && e.currencyCode != null) {
        final c = RenewalCurrency.values.byName(e.currencyCode!);
        currencyFreq[c] = (currencyFreq[c] ?? 0) + 1;
        totalPaid += e.amount!;
      }
    }
    final primary = currencyFreq.isEmpty
        ? RenewalCurrency.inr
        : currencyFreq.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    var avgDays = 0.0;
    if (history.isNotEmpty) {
      final sum = history.fold<double>(
        0,
        (s, e) =>
            s +
            e.completionDate
                .difference(
                  DateTime(
                    e.originalRenewalDate.year,
                    e.originalRenewalDate.month,
                    e.originalRenewalDate.day,
                  ),
                )
                .inDays
                .toDouble(),
      );
      avgDays = sum / history.length;
    }

    return HistoryStats(
      completedThisMonth: thisMonth,
      completedThisYear: thisYear,
      completionRate: rate,
      totalMoneyPaid: totalPaid,
      averageCompletionDays: avgDays,
      primaryCurrency: primary,
    );
  }
}
