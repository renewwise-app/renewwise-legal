import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:renew_wise/models/expense_record.dart';
import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/renewal_currency.dart';
import 'package:renew_wise/services/expense_service.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/utils/date_utils.dart';
import 'package:renew_wise/utils/reminder_lifecycle_feedback.dart';
import 'package:renew_wise/widgets/common/app_feedback.dart';

enum _PaymentChoice { yes, no, edit }

abstract final class ExpenseCompletionDialog {
  static Future<ExpenseCompletionOutcome> maybeRecord({
    required BuildContext context,
    required Renewal renewal,
    required RenewalCurrency currency,
  }) async {
    final amount = renewal.amount;
    if (!renewal.paymentRequired || amount == null || amount <= 0) {
      return const ExpenseCompletionOutcome();
    }

    final today = RenewalDateUtils.dateOnly(DateTime.now());
    if (expenseService.hasExpenseForReminder(renewal.id, onDate: today)) {
      return const ExpenseCompletionOutcome();
    }

    final choice = await showDialog<_PaymentChoice>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.dialogBorder),
        title: Text('Did you pay ${currency.formatAmount(amount)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _PaymentChoice.no),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _PaymentChoice.edit),
            child: const Text('Edit Amount'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _PaymentChoice.yes),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (!context.mounted || choice == null || choice == _PaymentChoice.no) {
      return const ExpenseCompletionOutcome();
    }

    var finalAmount = amount;
    if (choice == _PaymentChoice.edit) {
      final edited = await _editAmount(context, currency, amount);
      if (edited == null || !context.mounted) {
        return const ExpenseCompletionOutcome();
      }
      finalAmount = edited;
    }

    final now = DateTime.now();
    await expenseService.addExpense(
      ExpenseRecord(
        id: now.microsecondsSinceEpoch.toString(),
        category: renewal.category,
        amount: finalAmount,
        date: RenewalDateUtils.dateOnly(now),
        source: ExpenseSource.reminder,
        reminderId: renewal.id,
        notes: renewal.title,
        createdAt: now,
      ),
    );

    return ExpenseCompletionOutcome(
      recorded: true,
      amount: finalAmount,
      currency: currency,
    );
  }

  static Future<double?> _editAmount(
    BuildContext context,
    RenewalCurrency currency,
    double initial,
  ) async {
    final ctrl = TextEditingController(
      text: initial.toStringAsFixed(initial == initial.roundToDouble() ? 0 : 2),
    );
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.dialogBorder),
        title: const Text('Edit amount'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            hintText: 'Amount (${currency.symbol})',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(ctrl.text.trim());
              if (parsed == null || parsed <= 0) {
                AppFeedback.info(ctx, 'Enter an amount greater than zero');
                return;
              }
              Navigator.pop(ctx, parsed);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return result;
  }
}
