import 'package:flutter/material.dart';

import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/renewal_currency.dart';
import 'package:renew_wise/widgets/common/app_feedback.dart';

/// Outcome of the payment prompt during reminder completion.
class ExpenseCompletionOutcome {
  const ExpenseCompletionOutcome({
    this.recorded = false,
    this.amount,
    this.currency,
  });

  final bool recorded;
  final double? amount;
  final RenewalCurrency? currency;
}

/// Short, positive confirmation after completing a reminder (DR-4).
abstract final class ReminderLifecycleFeedback {
  static void show(
    BuildContext context, {
    required Renewal renewal,
    required bool movedToHistory,
    ExpenseCompletionOutcome expense = const ExpenseCompletionOutcome(),
  }) {
    final lines = <String>[];

    if (movedToHistory) {
      lines.add('${renewal.title} marked as completed.');
    } else {
      lines.add('${renewal.title} completed.');
    }

    if (expense.recorded &&
        expense.amount != null &&
        expense.currency != null) {
      lines.add(
        '${expense.currency!.formatAmount(expense.amount!)} added to your expenses.',
      );
      lines.add('Smart Insights updated.');
      lines.add('Goal Planner updated.');
    } else if (renewal.paymentRequired && renewal.amount != null) {
      lines.add('Completion recorded.');
    } else {
      lines.add("You're on track today.");
    }

    AppFeedback.show(
      context,
      message: lines.join('\n'),
      success: true,
      haptic: true,
      duration: const Duration(seconds: 4),
    );
  }
}
