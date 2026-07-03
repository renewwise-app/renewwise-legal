import 'package:sqflite/sqflite.dart';

import 'package:renew_wise/database/database_helper.dart';
import 'package:renew_wise/models/alert_style.dart';
import 'package:renew_wise/models/recurrence_end_type.dart';
import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/renewal_category.dart';
import 'package:renew_wise/models/renewal_currency.dart';
import 'package:renew_wise/models/renewal_importance.dart';
import 'package:renew_wise/models/renewal_priority.dart';
import 'package:renew_wise/models/renewal_status.dart';
import 'package:renew_wise/models/repeat_cycle.dart';
import 'package:renew_wise/repository/renewal_repository.dart';

class SqliteRenewalRepository implements RenewalRepository {
  const SqliteRenewalRepository({required this.databaseHelper});

  final DatabaseHelper databaseHelper;

  @override
  Future<List<Renewal>> loadAll() async {
    final db = await databaseHelper.database;
    final rows = await db.query('renewals', orderBy: 'renewal_date ASC');
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> insert(Renewal renewal) async {
    final db = await databaseHelper.database;
    await db.insert(
      'renewals',
      _toRow(renewal),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> update(Renewal renewal) async {
    final db = await databaseHelper.database;
    await db.update(
      'renewals',
      _toRow(renewal),
      where: 'id = ?',
      whereArgs: [renewal.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    final db = await databaseHelper.database;
    await db.delete('renewals', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> clearAll() async {
    final db = await databaseHelper.database;
    await db.delete('renewals');
  }

  /// Export raw rows for encrypted backup bundles.
  @override
  Future<List<Map<String, dynamic>>> exportAllRows() async {
    final db = await databaseHelper.database;
    return db.query('renewals');
  }

  /// Replace all rows atomically during restore.
  @override
  Future<void> replaceAllRows(List<Map<String, dynamic>> rows) async {
    final db = await databaseHelper.database;
    await db.transaction((txn) async {
      await txn.delete('renewals');
      for (final row in rows) {
        await txn.insert(
          'renewals',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // ─── Serialization ──────────────────────────────────────────────────────────

  Map<String, dynamic> _toRow(Renewal r) => {
        'id': r.id,
        'title': r.title,
        'category': r.category.name,
        'renewal_date': r.renewalDate.millisecondsSinceEpoch,
        'payment_required': r.paymentRequired ? 1 : 0,
        'amount': r.amount,
        'currency': r.currency.name,
        'importance': r.importance.name,
        'priority': r.priority.name,
        'alert_style': r.alertStyle.name,
        'status': r.status.name,
        'repeat_cycle': r.repeatCycle.name,
        'recurrence_end_type': r.recurrenceEndType.name,
        'recurrence_end_date': r.recurrenceEndDate?.millisecondsSinceEpoch,
        'recurrence_occurrence_limit': r.recurrenceOccurrenceLimit,
        'recurrence_completed_count': r.recurrenceCompletedCount,
        'reminder_schedule': r.reminderSchedule.join(','),
        'notes': r.notes,
        'fund_id': r.fundId,
        'created_at': r.createdAt.millisecondsSinceEpoch,
        'updated_at': r.updatedAt.millisecondsSinceEpoch,
        'custom_event_type': r.customEventType,
        'custom_reminder_dates': r.customReminderDates.isEmpty
            ? null
            : r.customReminderDates
                .map((d) => d.millisecondsSinceEpoch)
                .join(','),
        'reminder_time_minutes': r.reminderTimeMinutes,
      };

  Renewal _fromRow(Map<String, dynamic> row) {
    final scheduleStr = (row['reminder_schedule'] as String?) ?? '';
    final schedule = scheduleStr.isEmpty
        ? <int>[]
        : scheduleStr.split(',').map(int.parse).toList();

    final customDatesStr = (row['custom_reminder_dates'] as String?) ?? '';
    final customDates = customDatesStr.isEmpty
        ? <DateTime>[]
        : customDatesStr
            .split(',')
            .map((s) => DateTime.fromMillisecondsSinceEpoch(int.parse(s)))
            .toList();

    return Renewal(
      id: row['id'] as String,
      title: row['title'] as String,
      category: _enumByName(
          RenewalCategory.values, row['category'] as String, RenewalCategory.other),
      renewalDate:
          DateTime.fromMillisecondsSinceEpoch(row['renewal_date'] as int),
      paymentRequired: (row['payment_required'] as int) == 1,
      amount: row['amount'] as double?,
      currency: _enumByName(
          RenewalCurrency.values, row['currency'] as String, RenewalCurrency.inr),
      importance: _enumByName(RenewalImportance.values,
          row['importance'] as String, RenewalImportance.important),
      priority: _enumByName(RenewalPriority.values, row['priority'] as String,
          RenewalPriority.medium),
      alertStyle: _enumByName(AlertStyle.values, row['alert_style'] as String? ?? 'standard',
          AlertStyle.standard),
      status: _enumByName(
          RenewalStatus.values, row['status'] as String, RenewalStatus.upcoming),
      repeatCycle: _enumByName(RepeatCycle.values, row['repeat_cycle'] as String,
          RepeatCycle.yearly),
      recurrenceEndType: _enumByName(
        RecurrenceEndType.values,
        row['recurrence_end_type'] as String? ?? 'never',
        RecurrenceEndType.never,
      ),
      recurrenceEndDate: row['recurrence_end_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              row['recurrence_end_date'] as int,
            )
          : null,
      recurrenceOccurrenceLimit: row['recurrence_occurrence_limit'] as int?,
      recurrenceCompletedCount:
          (row['recurrence_completed_count'] as int?) ?? 0,
      reminderSchedule: schedule,
      notes: row['notes'] as String?,
      fundId: row['fund_id'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
      customEventType: row['custom_event_type'] as String?,
      customReminderDates: customDates,
      reminderTimeMinutes: row['reminder_time_minutes'] as int?,
    );
  }

  T _enumByName<T extends Enum>(List<T> values, String name, T fallback) =>
      values.firstWhere((e) => e.name == name, orElse: () => fallback);
}
