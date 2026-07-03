import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:renew_wise/models/goal_planner_models.dart';
import 'package:renew_wise/repository/goal_planner_repository.dart';

class SharedPreferencesGoalPlannerRepository implements GoalPlannerRepository {
  static const _kSettingsKey = 'goal_planner_settings_v1';

  @override
  Future<GoalPlannerSettings?> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSettingsKey);
    if (raw == null) return null;
    return GoalPlannerSettings.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> saveSettings(GoalPlannerSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSettingsKey, jsonEncode(settings.toJson()));
  }
}
