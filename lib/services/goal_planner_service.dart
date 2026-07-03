import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:renew_wise/models/goal_planner_models.dart';

class GoalPlannerService extends ChangeNotifier {
  static const _kSettingsKey = 'goal_planner_settings_v1';

  GoalPlannerSettings _settings = const GoalPlannerSettings();

  GoalPlannerSettings get settings => _settings;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSettingsKey);
    if (raw != null) {
      _settings = GoalPlannerSettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    }
    notifyListeners();
  }

  Future<void> saveSettings(GoalPlannerSettings settings) async {
    _settings = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSettingsKey, jsonEncode(settings.toJson()));
    notifyListeners();
  }

  Future<void> setMonthlyIncome(int year, int month, double amount) async {
    final key = GoalPlannerValidationUtils.monthKey(year, month);
    final updated = Map<String, double>.from(_settings.monthlyIncomes)
      ..[key] = amount;
    await saveSettings(_settings.copyWith(monthlyIncomes: updated));
  }

  bool needsIncomeForMonth(int year, int month) {
    if (_settings.incomeType != GoalIncomeType.enterEachMonth) return false;
    final key = GoalPlannerValidationUtils.monthKey(year, month);
    final value = _settings.monthlyIncomes[key];
    return value == null || value <= 0;
  }
}
