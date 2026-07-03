import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/renewal_category.dart';
import 'package:renew_wise/models/renewal_currency.dart';
import 'package:renew_wise/models/renewal_importance.dart';
import 'package:renew_wise/models/renewal_priority.dart';
import 'package:renew_wise/models/renewal_status.dart';
import 'package:renew_wise/models/repeat_cycle.dart';
import 'package:renew_wise/repository/in_memory_renewal_repository.dart';
import 'package:renew_wise/screens/main_shell_screen.dart';
import 'package:renew_wise/services/assistant_draft_service.dart';
import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/no_op_notification_service.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/widgets/renewal_list_item.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

RenewalService makeService() => RenewalService(
      repository: InMemoryRenewalRepository(),
      notificationService: const NoOpNotificationService(),
    );

late ReminderStateService _reminderState;
late AssistantDraftService _assistantDraft;
late EventExtrasService _eventExtras;

Widget buildApp(RenewalService service) {
  return MaterialApp(
    theme: AppTheme.light,
    home: MainShellScreen(
      renewalService: service,
      settingsService: SettingsService(),
      notificationService: const NoOpNotificationService(),
      reminderStateService: _reminderState,
      assistantDraftService: _assistantDraft,
      eventExtrasService: _eventExtras,
    ),
  );
}

void _usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// A renewal date still inside the current month (for This Month filter tests).
DateTime upcomingInCurrentMonth(DateTime now) {
  final lastDay = DateTime(now.year, now.month + 1, 0).day;
  if (now.day < lastDay) {
    return DateTime(now.year, now.month, now.day + 1);
  }
  return DateTime(now.year, now.month, now.day);
}

Renewal makeRenewal({
  required String id,
  required String title,
  required DateTime renewalDate,
  bool paymentRequired = false,
  double? amount,
  RenewalCurrency currency = RenewalCurrency.inr,
  RenewalPriority priority = RenewalPriority.medium,
  RenewalCategory category = RenewalCategory.insurance,
  RenewalStatus status = RenewalStatus.upcoming,
  String? notes,
  String? customEventType,
}) {
  final now = DateTime.now();
  return Renewal(
    id: id,
    title: title,
    category: category,
    renewalDate: renewalDate,
    paymentRequired: paymentRequired,
    amount: amount,
    currency: currency,
    priority: priority,
    importance: RenewalImportance.important,
    status: status,
    repeatCycle: RepeatCycle.yearly,
    notes: notes,
    customEventType: customEventType,
    createdAt: now,
    updatedAt: now,
  );
}

// ─── Widget tests ─────────────────────────────────────────────────────────────

void main() {
  final now = DateTime.now();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    _reminderState = ReminderStateService();
    await _reminderState.initialize();
    _assistantDraft = AssistantDraftService();
    await _assistantDraft.initialize();
    _eventExtras = EventExtrasService();
    await _eventExtras.initialize();
  });

  testWidgets('Home screen renders four dashboard summary cards', (tester) async {
    _usePhoneScreen(tester);
    final service = makeService();
    await tester.pumpWidget(buildApp(service));

    expect(find.text('RenewWise'), findsOneWidget);
    expect(find.text('Because Peace of Mind Matters.'), findsOneWidget);
    expect(find.textContaining('Good '), findsOneWidget);
    expect(find.text("You're all caught up."), findsOneWidget);
    expect(find.text('Critical Events'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Due This Month'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Add Event'), findsOneWidget);
    expect(find.text('View Details'), findsNWidgets(4));
  });

  testWidgets('Tapping Add Event navigates to assistant welcome', (tester) async {
    _usePhoneScreen(tester);
    final service = makeService();
    await tester.pumpWidget(buildApp(service));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Add Event'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Event'));
    await tester.pumpAndSettle();

    expect(find.text("Let's Begin"), findsOneWidget);
    expect(
      find.textContaining('never have to worry'),
      findsOneWidget,
    );
  });

  testWidgets('Assistant Continue disabled until title and category set',
      (tester) async {
    _usePhoneScreen(tester);
    final service = makeService();
    await tester.pumpWidget(buildApp(service));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Add Event'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Event'));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Let's Begin"));
    await tester.pumpAndSettle();

    final continueButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Continue'),
    );
    expect(continueButton.onPressed, isNull);
  });

  testWidgets('Tapping Upcoming card opens event list', (tester) async {
    _usePhoneScreen(tester);
    final service = makeService();
    service.addRenewal(
      makeRenewal(
        id: '1',
        title: 'Car Insurance',
        renewalDate: upcomingInCurrentMonth(now),
      ),
    );

    await tester.pumpWidget(buildApp(service));
    await tester.pump();

    await tester.tap(find.text('Upcoming').first);
    await tester.pumpAndSettle();

    expect(find.text('Upcoming'), findsWidgets);
    expect(find.byType(RenewalListItem, skipOffstage: false), findsOneWidget);
  });

  testWidgets('Tapping event opens details screen, not edit directly',
      (tester) async {
    _usePhoneScreen(tester);
    final service = makeService();
    service.addRenewal(
      makeRenewal(
        id: '1',
        title: 'My Car Insurance',
        renewalDate: upcomingInCurrentMonth(now),
      ),
    );

    await tester.pumpWidget(buildApp(service));
    await tester.pump();

    await tester.tap(find.text('Upcoming').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(RenewalListItem, skipOffstage: false));
    await tester.pumpAndSettle();

    expect(find.text('Event Details'), findsOneWidget);
    expect(find.text('Edit'), findsWidgets);
    expect(find.text('Edit Event'), findsNothing);
  });

  testWidgets('Edit from event details opens edit screen', (tester) async {
    _usePhoneScreen(tester);
    final service = makeService();
    service.addRenewal(
      makeRenewal(
        id: '1',
        title: 'My Car Insurance',
        renewalDate: upcomingInCurrentMonth(now),
      ),
    );

    await tester.pumpWidget(buildApp(service));
    await tester.pump();

    await tester.tap(find.text('Upcoming').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(RenewalListItem, skipOffstage: false));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Edit').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit').last);
    await tester.pumpAndSettle();

    expect(find.text('Edit Event'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('Delete from event details removes event', (tester) async {
    _usePhoneScreen(tester);
    final service = makeService();
    service.addRenewal(
      makeRenewal(
        id: '1',
        title: 'Delete Me',
        renewalDate: upcomingInCurrentMonth(now),
      ),
    );

    await tester.pumpWidget(buildApp(service));
    await tester.pump();

    await tester.tap(find.text('Upcoming').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(RenewalListItem, skipOffstage: false));
    await tester.pumpAndSettle();

    final deleteButton = find.text('Delete');
    await tester.ensureVisible(deleteButton.last);
    await tester.pumpAndSettle();
    await tester.tap(deleteButton.last);
    await tester.pumpAndSettle();
    expect(find.text('Delete permanently?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(service.renewals.isEmpty, isTrue);
  });

  testWidgets('Due This Month card opens unified detail list', (tester) async {
    _usePhoneScreen(tester);
    final service = makeService();
    service.addRenewal(
      makeRenewal(
        id: '1',
        title: 'Gym',
        renewalDate: DateTime(now.year, now.month, 15),
        paymentRequired: true,
        amount: 2000,
        category: RenewalCategory.gym,
      ),
    );

    await tester.pumpWidget(buildApp(service));
    await tester.pump();

    await tester.tap(find.text('Due This Month'));
    await tester.pumpAndSettle();

    expect(find.text('Sort'), findsOneWidget);
    expect(find.text('Search events…'), findsOneWidget);
    expect(find.byType(RenewalListItem, skipOffstage: false), findsOneWidget);
  });

  testWidgets('Overdue renewal appears under Critical Events', (tester) async {
    _usePhoneScreen(tester);
    final service = makeService();
    service.addRenewal(
      makeRenewal(
        id: '1',
        title: 'Past Due',
        renewalDate: now.subtract(const Duration(days: 5)),
      ),
    );

    await tester.pumpWidget(buildApp(service));
    await tester.pump();

    expect(find.text('1 event needs attention'), findsOneWidget);

    await tester.tap(find.text('Critical Events'));
    await tester.pumpAndSettle();

    expect(find.text('Overdue', skipOffstage: false), findsOneWidget);
  });

  // ─── RenewalService unit tests ─────────────────────────────────────────────

  group('RenewalService', () {
    test('sorts by nearest date, overdue renewals first', () {
      final service = makeService();
      service.addRenewal(
        makeRenewal(id: '1', title: 'Far', renewalDate: now.add(const Duration(days: 30))),
      );
      service.addRenewal(
        makeRenewal(id: '2', title: 'Near', renewalDate: now.add(const Duration(days: 5))),
      );
      service.addRenewal(
        makeRenewal(id: '3', title: 'Overdue', renewalDate: now.subtract(const Duration(days: 2))),
      );

      expect(service.renewals[0].title, 'Overdue');
      expect(service.renewals[1].title, 'Near');
      expect(service.renewals[2].title, 'Far');
    });

    test('deleteRenewal removes the renewal', () {
      final service = makeService();
      service.addRenewal(
        makeRenewal(id: '1', title: 'Test', renewalDate: now.add(const Duration(days: 10))),
      );
      expect(service.renewals.length, 1);
      service.deleteRenewal('1');
      expect(service.renewals.isEmpty, isTrue);
    });

    test('updateRenewal replaces renewal by id without duplicating', () {
      final service = makeService();
      service.addRenewal(
        makeRenewal(id: '1', title: 'Old Title', renewalDate: now.add(const Duration(days: 10))),
      );
      service.updateRenewal(
        makeRenewal(id: '1', title: 'New Title', renewalDate: now.add(const Duration(days: 10))),
      );
      expect(service.renewals.length, 1);
      expect(service.renewals.first.title, 'New Title');
    });

    test('overdueCount counts renewals with past dates', () {
      final service = makeService();
      service.addRenewal(
        makeRenewal(id: '1', title: 'Overdue', renewalDate: now.subtract(const Duration(days: 3))),
      );
      service.addRenewal(
        makeRenewal(id: '2', title: 'Active', renewalDate: now.add(const Duration(days: 30))),
      );
      expect(service.overdueCount, 1);
    });

    test('upcomingCount excludes cancelled', () {
      final service = makeService();
      service.addRenewal(
        makeRenewal(id: '1', title: 'Active', renewalDate: now.add(const Duration(days: 30))),
      );
      service.addRenewal(
        Renewal(
          id: '2',
          title: 'Cancelled',
          category: RenewalCategory.other,
          renewalDate: now.add(const Duration(days: 60)),
          status: RenewalStatus.cancelled,
          createdAt: now,
          updatedAt: now,
        ),
      );
      expect(service.upcomingCount, 1);
    });

    test('criticalCount includes overdue and critical priority', () {
      final service = makeService();
      service.addRenewal(
        makeRenewal(
          id: '1',
          title: 'Critical',
          renewalDate: now.add(const Duration(days: 5)),
          priority: RenewalPriority.critical,
        ),
      );
      service.addRenewal(
        makeRenewal(
          id: '2',
          title: 'Overdue',
          renewalDate: now.subtract(const Duration(days: 2)),
          priority: RenewalPriority.low,
        ),
      );
      service.addRenewal(
        makeRenewal(
          id: '3',
          title: 'Normal',
          renewalDate: now.add(const Duration(days: 10)),
          priority: RenewalPriority.high,
        ),
      );
      expect(service.criticalCount, 2);
    });

    test('completedRenewals returns paid events only', () {
      final service = makeService();
      service.addRenewal(
        makeRenewal(
          id: '1',
          title: 'Done',
          renewalDate: now.subtract(const Duration(days: 1)),
          status: RenewalStatus.paid,
        ),
      );
      service.addRenewal(
        makeRenewal(
          id: '2',
          title: 'Active',
          renewalDate: now.add(const Duration(days: 10)),
        ),
      );
      expect(service.completedCount, 1);
      expect(service.completedRenewals.first.title, 'Done');
    });

    test('dueThisMonthTotal sums payment renewals in current month', () {
      final service = makeService();
      service.addRenewal(
        makeRenewal(
          id: '1',
          title: 'Gym',
          renewalDate: DateTime(now.year, now.month, 10),
          paymentRequired: true,
          amount: 1500,
        ),
      );
      service.addRenewal(
        makeRenewal(
          id: '2',
          title: 'Next month',
          renewalDate: now.month < 12
              ? DateTime(now.year, now.month + 1, 10)
              : DateTime(now.year + 1, 1, 10),
          paymentRequired: true,
          amount: 900,
        ),
      );
      expect(service.dueThisMonthTotal, 1500);
    });

    test('estimatedCost sums paymentRequired amounts per currency', () {
      final service = makeService();
      service.addRenewal(
        makeRenewal(
          id: '1',
          title: 'A',
          renewalDate: now.add(const Duration(days: 10)),
          paymentRequired: true,
          amount: 1500,
          currency: RenewalCurrency.inr,
        ),
      );
      service.addRenewal(
        makeRenewal(
          id: '2',
          title: 'B',
          renewalDate: now.add(const Duration(days: 20)),
          paymentRequired: true,
          amount: 800,
          currency: RenewalCurrency.inr,
        ),
      );
      service.addRenewal(
        makeRenewal(
          id: '3',
          title: 'C',
          renewalDate: now.add(const Duration(days: 30)),
          paymentRequired: false,
          amount: 999,
        ),
      );
      expect(service.estimatedCost[RenewalCurrency.inr], 2300);
      expect(service.hasPaidRenewals, isTrue);
    });

    test('nearestRenewal finds soonest by date regardless of priority', () {
      final service = makeService();
      service.addRenewal(
        makeRenewal(
          id: '1',
          title: 'Far critical',
          renewalDate: now.add(const Duration(days: 90)),
          priority: RenewalPriority.critical,
        ),
      );
      service.addRenewal(
        makeRenewal(
          id: '2',
          title: 'Near low',
          renewalDate: now.add(const Duration(days: 3)),
          priority: RenewalPriority.low,
        ),
      );
      expect(service.nearestRenewal?.title, 'Near low');
    });
  });

  // ─── Currency formatter tests ──────────────────────────────────────────────

  group('RenewalCurrency.formatAmount', () {
    test('formats with commas and symbol', () {
      expect(RenewalCurrency.inr.formatAmount(5000), '₹ 5,000');
      expect(RenewalCurrency.usd.formatAmount(1200), r'$ 1,200');
      expect(RenewalCurrency.inr.formatAmount(100), '₹ 100');
      expect(RenewalCurrency.inr.formatAmount(1000000), '₹ 1,000,000');
    });
  });

  // ─── RenewalListItem.daysColor tests ──────────────────────────────────────

  group('RenewalListItem.daysColor', () {
    test('red for <=3 days (covers overdue)', () {
      expect(RenewalListItem.daysColor(-5), const Color(0xFFDC2626));
      expect(RenewalListItem.daysColor(0), const Color(0xFFDC2626));
      expect(RenewalListItem.daysColor(3), const Color(0xFFDC2626));
    });
    test('orange for <=7 days', () {
      expect(RenewalListItem.daysColor(4), const Color(0xFFEA580C));
      expect(RenewalListItem.daysColor(7), const Color(0xFFEA580C));
    });
    test('blue for <=30 days', () {
      expect(RenewalListItem.daysColor(8), const Color(0xFF2563EB));
      expect(RenewalListItem.daysColor(30), const Color(0xFF2563EB));
    });
    test('green for >30 days', () {
      expect(RenewalListItem.daysColor(31), AppColors.primaryGreen);
    });
  });

  // ─── Renewal model tests ──────────────────────────────────────────────────

  group('Renewal', () {
    test('isOverdue true when renewal date is in the past', () {
      final past = makeRenewal(
        id: '1',
        title: 'Test',
        renewalDate: now.subtract(const Duration(days: 3)),
      );
      expect(past.isOverdue, isTrue);
    });

    test('isOverdue false when renewal date is today or future', () {
      final future = makeRenewal(
        id: '1',
        title: 'Test',
        renewalDate: now.add(const Duration(days: 1)),
      );
      expect(future.isOverdue, isFalse);
    });

    test('copyWith replaces fields correctly', () {
      final original = makeRenewal(
        id: '1',
        title: 'Original',
        renewalDate: now.add(const Duration(days: 10)),
      );
      final updated = original.copyWith(title: 'Updated');
      expect(updated.id, '1');
      expect(updated.title, 'Updated');
      expect(updated.renewalDate, original.renewalDate);
    });

    test('categoryLabel uses customEventType when set', () {
      final r = makeRenewal(
        id: '1',
        title: 'Birthday',
        renewalDate: now.add(const Duration(days: 5)),
        category: RenewalCategory.other,
        customEventType: 'Birthday',
      );
      expect(r.categoryLabel, 'Birthday');
    });

    test('categoryLabel falls back to category.label when customEventType is null', () {
      final r = makeRenewal(
        id: '1',
        title: 'Insurance',
        renewalDate: now.add(const Duration(days: 5)),
        category: RenewalCategory.insurance,
      );
      expect(r.categoryLabel, 'Insurance');
    });
  });

  // ─── Statistics unit tests ─────────────────────────────────────────────────

  group('RenewalService statistics', () {
    test('totalRenewalCount / paymentRenewalCount / nonPaymentRenewalCount', () {
      final service = makeService();
      service.addRenewal(
        makeRenewal(id: '1', title: 'A', renewalDate: now.add(const Duration(days: 10)), paymentRequired: true, amount: 500),
      );
      service.addRenewal(
        makeRenewal(id: '2', title: 'B', renewalDate: now.add(const Duration(days: 20)), paymentRequired: false),
      );
      service.addRenewal(
        Renewal(
          id: '3', title: 'Cancelled', category: RenewalCategory.other,
          renewalDate: now.add(const Duration(days: 30)),
          status: RenewalStatus.cancelled, createdAt: now, updatedAt: now,
        ),
      );
      expect(service.totalRenewalCount, 2);
      expect(service.paymentRenewalCount, 1);
      expect(service.nonPaymentRenewalCount, 1);
    });

    test('primaryCurrency picks most frequent currency', () {
      final service = makeService();
      service.addRenewal(makeRenewal(id: '1', title: 'A', renewalDate: now.add(const Duration(days: 10)), paymentRequired: true, amount: 100, currency: RenewalCurrency.usd));
      service.addRenewal(makeRenewal(id: '2', title: 'B', renewalDate: now.add(const Duration(days: 20)), paymentRequired: true, amount: 200, currency: RenewalCurrency.inr));
      service.addRenewal(makeRenewal(id: '3', title: 'C', renewalDate: now.add(const Duration(days: 30)), paymentRequired: true, amount: 300, currency: RenewalCurrency.inr));
      expect(service.primaryCurrency, RenewalCurrency.inr);
    });

    test('primaryCurrency defaults to INR with no payment renewals', () {
      final service = makeService();
      service.addRenewal(makeRenewal(id: '1', title: 'A', renewalDate: now.add(const Duration(days: 10))));
      expect(service.primaryCurrency, RenewalCurrency.inr);
    });

    test('monthlySummary counts renewals in the current month', () {
      final service = makeService();
      final thisMonth = DateTime(now.year, now.month, 15);
      final nextMonth = now.month < 12
          ? DateTime(now.year, now.month + 1, 15)
          : DateTime(now.year + 1, 1, 15);

      service.addRenewal(makeRenewal(id: '1', title: 'This month', renewalDate: thisMonth, paymentRequired: true, amount: 1000));
      service.addRenewal(makeRenewal(id: '2', title: 'Next month', renewalDate: nextMonth, paymentRequired: true, amount: 2000));

      expect(service.monthlySummary.count, 1);
      expect(service.monthlySummary.amount, 1000);
    });

    test('monthlySummary amount is 0 when renewals have no payment', () {
      final service = makeService();
      service.addRenewal(makeRenewal(id: '1', title: 'Free', renewalDate: DateTime(now.year, now.month, 10), paymentRequired: false));
      expect(service.monthlySummary.count, 1);
      expect(service.monthlySummary.amount, 0);
    });

    test('yearlySummary counts renewals in the current year', () {
      final service = makeService();
      service.addRenewal(makeRenewal(id: '1', title: 'This year', renewalDate: DateTime(now.year, 6, 1), paymentRequired: true, amount: 3000));
      service.addRenewal(makeRenewal(id: '2', title: 'Last year', renewalDate: DateTime(now.year - 1, 6, 1), paymentRequired: true, amount: 5000));
      expect(service.yearlySummary.count, 1);
      expect(service.yearlySummary.amount, 3000);
      expect(service.yearlySummary.avgMonthly, 3000 / 12);
    });

    test('categoryTotals sums amounts per category sorted desc', () {
      final service = makeService();
      service.addRenewal(makeRenewal(id: '1', title: 'Ins1', renewalDate: now.add(const Duration(days: 10)), category: RenewalCategory.insurance, paymentRequired: true, amount: 5000));
      service.addRenewal(makeRenewal(id: '2', title: 'Gym', renewalDate: now.add(const Duration(days: 20)), category: RenewalCategory.gym, paymentRequired: true, amount: 2000));
      service.addRenewal(makeRenewal(id: '3', title: 'Ins2', renewalDate: now.add(const Duration(days: 30)), category: RenewalCategory.insurance, paymentRequired: true, amount: 3000));

      final totals = service.categoryTotals;
      expect(totals[0].category, RenewalCategory.insurance);
      expect(totals[0].amount, 8000);
      expect(totals[0].count, 2);
      expect(totals[1].category, RenewalCategory.gym);
      expect(totals[1].amount, 2000);
    });

    test('categoryTotals includes categories with zero payment amount', () {
      final service = makeService();
      service.addRenewal(makeRenewal(id: '1', title: 'Passport', renewalDate: now.add(const Duration(days: 10)), category: RenewalCategory.passport, paymentRequired: false));
      service.addRenewal(makeRenewal(id: '2', title: 'Gym', renewalDate: now.add(const Duration(days: 20)), category: RenewalCategory.gym, paymentRequired: true, amount: 1000));

      final totals = service.categoryTotals;
      expect(totals[0].category, RenewalCategory.gym);
      expect(totals[0].amount, 1000);
      expect(totals[1].category, RenewalCategory.passport);
      expect(totals[1].amount, 0);
    });

    test('largestRenewal returns renewal with highest amount', () {
      final service = makeService();
      service.addRenewal(makeRenewal(id: '1', title: 'Small', renewalDate: now.add(const Duration(days: 5)), paymentRequired: true, amount: 500));
      service.addRenewal(makeRenewal(id: '2', title: 'Large', renewalDate: now.add(const Duration(days: 10)), paymentRequired: true, amount: 9000));
      service.addRenewal(makeRenewal(id: '3', title: 'Free', renewalDate: now.add(const Duration(days: 15)), paymentRequired: false));
      expect(service.largestRenewal?.title, 'Large');
    });

    test('largestRenewal returns null when no payment renewals', () {
      final service = makeService();
      service.addRenewal(makeRenewal(id: '1', title: 'Free', renewalDate: now.add(const Duration(days: 10))));
      expect(service.largestRenewal, isNull);
    });

    test('next30DayCost includes only renewals within 30 days', () {
      final service = makeService();
      service.addRenewal(makeRenewal(id: '1', title: 'Near', renewalDate: now.add(const Duration(days: 10)), paymentRequired: true, amount: 500));
      service.addRenewal(makeRenewal(id: '2', title: 'Far', renewalDate: now.add(const Duration(days: 60)), paymentRequired: true, amount: 1000));
      expect(service.next30DayCost.count, 1);
      expect(service.next30DayCost.amount, 500);
    });

    test('next90DayCost includes renewals within 90 days', () {
      final service = makeService();
      service.addRenewal(makeRenewal(id: '1', title: 'In30', renewalDate: now.add(const Duration(days: 20)), paymentRequired: true, amount: 300));
      service.addRenewal(makeRenewal(id: '2', title: 'In90', renewalDate: now.add(const Duration(days: 80)), paymentRequired: true, amount: 700));
      service.addRenewal(makeRenewal(id: '3', title: 'Beyond', renewalDate: now.add(const Duration(days: 200)), paymentRequired: true, amount: 1000));
      expect(service.next90DayCost.count, 2);
      expect(service.next90DayCost.amount, 1000);
    });

    test('next365DayCost includes renewals within 365 days', () {
      final service = makeService();
      service.addRenewal(makeRenewal(id: '1', title: 'Soon', renewalDate: now.add(const Duration(days: 100)), paymentRequired: true, amount: 400));
      service.addRenewal(makeRenewal(id: '2', title: 'Later', renewalDate: now.add(const Duration(days: 360)), paymentRequired: true, amount: 600));
      service.addRenewal(makeRenewal(id: '3', title: 'TooFar', renewalDate: now.add(const Duration(days: 400)), paymentRequired: true, amount: 800));
      expect(service.next365DayCost.count, 2);
      expect(service.next365DayCost.amount, 1000);
    });

    test('upcoming cost methods exclude overdue renewals', () {
      final service = makeService();
      service.addRenewal(makeRenewal(id: '1', title: 'Overdue', renewalDate: now.subtract(const Duration(days: 5)), paymentRequired: true, amount: 999));
      service.addRenewal(makeRenewal(id: '2', title: 'Upcoming', renewalDate: now.add(const Duration(days: 10)), paymentRequired: true, amount: 100));
      expect(service.next30DayCost.count, 1);
      expect(service.next30DayCost.amount, 100);
    });
  });
}
