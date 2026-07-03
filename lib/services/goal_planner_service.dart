import 'package:flutter/foundation.dart';

import 'package:renew_wise/models/goal_planner_models.dart';
import 'package:renew_wise/repository/goal_planner_repository.dart';
import 'package:renew_wise/repository/shared_preferences_goal_planner_repository.dart';

class GoalPlannerService extends ChangeNotifier {
  GoalPlannerService({GoalPlannerRepository? repository})
      : _repository = repository ?? SharedPreferencesGoalPlannerRepository();

  final GoalPlannerRepository _repository;

  GoalPlannerSettings _settings = const GoalPlannerSettings();

  GoalPlannerSettings get settings => _settings;

  Future<void> initialize() async {
    _settings = await _repository.loadSettings() ?? const GoalPlannerSettings();
    notifyListeners();
  }

  Future<void> saveSettings(GoalPlannerSettings settings) async {
    _settings = settings;
    await _repository.saveSettings(settings);
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
