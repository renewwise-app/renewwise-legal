import 'package:renew_wise/models/assistant_query.dart';
import 'package:renew_wise/models/event_document.dart';
import 'package:renew_wise/models/expense_record.dart';
import 'package:renew_wise/models/goal_planner_models.dart';
import 'package:renew_wise/models/history_entry.dart';
import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/expense_service.dart';
import 'package:renew_wise/services/goal_planner_service.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';

/// Internal foundation for RenewWise Assistant (V2).
///
/// No UI, settings, or voice integration in Packet A — read-only placeholders
/// that delegate to existing services.
class RenewWiseAssistantService {
  RenewWiseAssistantService({
    required this.renewalService,
    required this.expenseService,
    required this.goalPlannerService,
    required this.eventExtrasService,
    required this.reminderStateService,
    required this.settingsService,
  });

  static RenewWiseAssistantService? _instance;

  static void attach(RenewWiseAssistantService service) {
    _instance = service;
  }

  static RenewWiseAssistantService get instance {
    assert(
      _instance != null,
      'RenewWiseAssistantService.attach() must be called at startup',
    );
    return _instance!;
  }

  final RenewalService renewalService;
  final ExpenseService expenseService;
  final GoalPlannerService goalPlannerService;
  final EventExtrasService eventExtrasService;
  final ReminderStateService reminderStateService;
  final SettingsService settingsService;

  List<Renewal> getReminders() => renewalService.renewals;

  List<ExpenseRecord> getExpenses() => expenseService.expenses;

  GoalPlannerSettings getGoals() => goalPlannerService.settings;

  List<EventDocument> getDocuments() => eventExtrasService.allDocuments;

  List<HistoryEntry> getHistory() => reminderStateService.history;

  /// Placeholder for future offline insight aggregation.
  Map<String, Object?> getInsights() => {
        'reminderCount': renewalService.renewals.length,
        'expenseCount': expenseService.expenses.length,
        'historyCount': reminderStateService.history.length,
        'documentCount': eventExtrasService.totalDocumentCount,
        'defaultCurrency': settingsService.defaultCurrency.name,
      };

  /// Placeholder for future natural-language answers.
  Future<AssistantAnswer> answerQuestion(String question) async {
    return AssistantAnswer(
      question: question.trim(),
      answer:
          'RenewWise Assistant is not available yet. Your question has been received.',
      source: AssistantAnswerSource.placeholder,
    );
  }
}
