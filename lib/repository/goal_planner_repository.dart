import 'package:renew_wise/models/goal_planner_models.dart';

/// Persistence boundary for goal planner settings.
abstract class GoalPlannerRepository {
  Future<GoalPlannerSettings?> loadSettings();
  Future<void> saveSettings(GoalPlannerSettings settings);
}
