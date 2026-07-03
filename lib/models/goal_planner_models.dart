import 'package:renew_wise/models/renewal_currency.dart';
import 'package:renew_wise/models/renewal_priority.dart';
import 'package:renew_wise/models/renewwise_entity_metadata.dart';

enum GoalIncomeType {
  sameEveryMonth('Same income every month'),
  enterEachMonth('I will enter income every month');

  const GoalIncomeType(this.label);
  final String label;
}

enum GoalMonthStatus {
  onTrack('✓'),
  heavyExpense('⚠ Heavy Expense Month'),
  insufficient('⚠ Insufficient Income'),
  missingIncome('Enter income for this month');

  const GoalMonthStatus(this.label);
  final String label;
}

class GoalPlannerSettings {
  const GoalPlannerSettings({
    this.goalName,
    this.goalAmount,
    this.targetYear,
    this.targetMonth,
    this.defaultMonthlyIncome,
    this.incomeType = GoalIncomeType.sameEveryMonth,
    this.monthlyIncomes = const {},
    this.planGenerated = false,
    this.version = RenewWiseEntityMetadata.currentSchemaVersion,
  });

  final String? goalName;
  final double? goalAmount;
  final int? targetYear;
  final int? targetMonth;
  final double? defaultMonthlyIncome;
  final GoalIncomeType incomeType;
  final Map<String, double> monthlyIncomes;
  final bool planGenerated;
  final int version;

  DateTime? get targetDate {
    if (targetYear == null || targetMonth == null) return null;
    return DateTime(targetYear!, targetMonth!, 1);
  }

  GoalPlannerSettings copyWith({
    String? goalName,
    double? goalAmount,
    int? targetYear,
    int? targetMonth,
    double? defaultMonthlyIncome,
    GoalIncomeType? incomeType,
    Map<String, double>? monthlyIncomes,
    bool? planGenerated,
    int? version,
    bool clearGoalName = false,
  }) {
    return GoalPlannerSettings(
      goalName: clearGoalName ? null : (goalName ?? this.goalName),
      goalAmount: goalAmount ?? this.goalAmount,
      targetYear: targetYear ?? this.targetYear,
      targetMonth: targetMonth ?? this.targetMonth,
      defaultMonthlyIncome: defaultMonthlyIncome ?? this.defaultMonthlyIncome,
      incomeType: incomeType ?? this.incomeType,
      monthlyIncomes: monthlyIncomes ?? this.monthlyIncomes,
      planGenerated: planGenerated ?? this.planGenerated,
      version: version ?? this.version,
    );
  }

  Map<String, dynamic> toJson() => {
        if (goalName != null && goalName!.isNotEmpty) 'goalName': goalName,
        if (goalAmount != null) 'goalAmount': goalAmount,
        if (targetYear != null) 'targetYear': targetYear,
        if (targetMonth != null) 'targetMonth': targetMonth,
        if (defaultMonthlyIncome != null)
          'defaultMonthlyIncome': defaultMonthlyIncome,
        'incomeType': incomeType.name,
        'monthlyIncomes': monthlyIncomes,
        'planGenerated': planGenerated,
        if (version != RenewWiseEntityMetadata.currentSchemaVersion)
          'version': version,
      };

  factory GoalPlannerSettings.fromJson(Map<String, dynamic> json) {
    final incomesRaw = json['monthlyIncomes'] as Map<String, dynamic>? ?? {};
    return GoalPlannerSettings(
      goalName: json['goalName'] as String?,
      goalAmount: (json['goalAmount'] as num?)?.toDouble(),
      targetYear: json['targetYear'] as int?,
      targetMonth: json['targetMonth'] as int?,
      defaultMonthlyIncome: (json['defaultMonthlyIncome'] as num?)?.toDouble(),
      incomeType: GoalIncomeType.values.firstWhere(
        (t) => t.name == (json['incomeType'] as String?),
        orElse: () => GoalIncomeType.sameEveryMonth,
      ),
      monthlyIncomes: incomesRaw.map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
      planGenerated: json['planGenerated'] as bool? ?? false,
      version: RenewWiseEntityMetadata.parseVersion(json['version']),
    );
  }
}

class GoalPlanMonthRow {
  const GoalPlanMonthRow({
    required this.year,
    required this.month,
    required this.label,
    required this.income,
    required this.plannedExpenses,
    required this.suggestedSavings,
    required this.remainingAmount,
    required this.status,
    this.missingIncome = false,
  });

  final int year;
  final int month;
  final String label;
  final double income;
  final double plannedExpenses;
  final double suggestedSavings;
  final double remainingAmount;
  final GoalMonthStatus status;
  final bool missingIncome;
}

class GoalPlanResult {
  const GoalPlanResult({
    required this.months,
    required this.goalAmount,
    required this.estimatedSavings,
    required this.isAchievable,
    required this.optionalExpenseReminders,
    required this.highPriorityExpenseTotal,
    required this.lowPriorityExpenseTotal,
  });

  final List<GoalPlanMonthRow> months;
  final double goalAmount;
  final double estimatedSavings;
  final bool isAchievable;
  final List<({String title, double amount, RenewalPriority priority})>
      optionalExpenseReminders;
  final double highPriorityExpenseTotal;
  final double lowPriorityExpenseTotal;

  double get remainingToGoal =>
      (goalAmount - estimatedSavings).clamp(0, goalAmount);

  double get completionPercent =>
      goalAmount <= 0 ? 0 : (estimatedSavings / goalAmount * 100).clamp(0, 100);
}

class GoalPlannerValidation {
  const GoalPlannerValidation({this.error});

  final String? error;
  bool get isValid => error == null;
}

abstract final class GoalPlannerValidationUtils {
  static GoalPlannerValidation validateInputs({
    required GoalPlannerSettings settings,
    required DateTime now,
  }) {
    final amount = settings.goalAmount;
    if (amount == null || amount <= 0) {
      return const GoalPlannerValidation(
        error: 'Enter a goal amount greater than zero',
      );
    }

    if (settings.targetYear == null || settings.targetMonth == null) {
      return const GoalPlannerValidation(error: 'Select a target month');
    }

    final target = DateTime(settings.targetYear!, settings.targetMonth!, 1);
    final current = DateTime(now.year, now.month, 1);
    if (target.isBefore(current)) {
      return const GoalPlannerValidation(
        error: 'Target month must be this month or later',
      );
    }

    if (settings.incomeType == GoalIncomeType.sameEveryMonth) {
      final income = settings.defaultMonthlyIncome;
      if (income == null || income <= 0) {
        return const GoalPlannerValidation(
          error: 'Enter a monthly income greater than zero',
        );
      }
    } else {
      final income = settings.defaultMonthlyIncome;
      if (income == null || income <= 0) {
        return const GoalPlannerValidation(
          error: 'Enter a default monthly income greater than zero',
        );
      }
    }

    return const GoalPlannerValidation();
  }

  static String monthKey(int year, int month) =>
      '$year-${month.toString().padLeft(2, '0')}';

  static String formatTargetMonth(int year, int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${names[month - 1]} $year';
  }

  static String shortMonthLabel(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month - 1];
  }

  static String formatMoney(RenewalCurrency currency, double amount) =>
      currency.formatAmount(amount);
}
