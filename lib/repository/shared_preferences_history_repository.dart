import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:renew_wise/models/history_entry.dart';
import 'package:renew_wise/repository/history_repository.dart';

class SharedPreferencesHistoryRepository implements HistoryRepository {
  static const _kHistoryKey = 'reminder_history_v1';

  @override
  Future<List<HistoryEntry>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final historyRaw = prefs.getString(_kHistoryKey);
    if (historyRaw == null) return const [];
    final list = jsonDecode(historyRaw) as List<dynamic>;
    return list
        .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveAll(List<HistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kHistoryKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }
}
