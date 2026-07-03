import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/renewal_category.dart';
import 'package:renew_wise/models/renewal_currency.dart';
import 'package:renew_wise/models/renewal_priority.dart';
import 'package:renew_wise/models/renewal_status.dart';

/// Internal developer service — only instantiated in non-release builds.
///
/// Responsibilities:
///   • Time-travel date override (effectiveToday).
///   • Persistent feature flags (SharedPreferences, prefixed "dev_flag_").
///   • UI overrides: ThemeMode, layout bounds.
///   • Static factories for demo / test / random Renewal data.
class DeveloperService extends ChangeNotifier {
  // ── Feature flag SharedPreferences keys ────────────────────────────────────
  static const kFlagFamilySharing = 'dev_flag_family_sharing';
  static const kFlagDriveBackup = 'dev_flag_drive_backup';
  static const kFlagMultiDocuments = 'dev_flag_multi_documents';
  static const kFlagAIAssistant = 'dev_flag_ai_assistant';
  static const kFlagTimelineView = 'dev_flag_timeline_view';
  static const kFlagNewDashboard = 'dev_flag_new_dashboard';

  static const List<({String key, String label, String desc})> featureFlags = [
    (
      key: kFlagFamilySharing,
      label: 'Family Sharing',
      desc: 'Multi-user family plan',
    ),
    (
      key: kFlagDriveBackup,
      label: 'Google Drive Backup',
      desc: 'Back up to your own Google Drive',
    ),
    (
      key: kFlagMultiDocuments,
      label: 'Multiple Documents',
      desc: 'Attach multiple files per event',
    ),
    (
      key: kFlagAIAssistant,
      label: 'AI Assistant',
      desc: 'Smart event suggestions and summaries',
    ),
    (
      key: kFlagTimelineView,
      label: 'Timeline View',
      desc: 'Visualise events on a scrollable timeline',
    ),
    (
      key: kFlagNewDashboard,
      label: 'New Dashboard',
      desc: 'Redesigned home screen layout',
    ),
  ];

  // ── State ───────────────────────────────────────────────────────────────────
  final Map<String, bool> _flags = {};
  DateTime? _dateOverride;
  ThemeMode _themeMode = ThemeMode.light;
  bool _layoutBounds = false;

  // ── Getters ─────────────────────────────────────────────────────────────────
  DateTime? get dateOverride => _dateOverride;
  ThemeMode get themeMode => _themeMode;
  bool get layoutBounds => _layoutBounds;

  /// Returns the overridden date when time-travel is active, otherwise today.
  DateTime get effectiveToday => _dateOverride ?? DateTime.now();

  bool getFlag(String key) => _flags[key] ?? false;

  // ── Initialization ──────────────────────────────────────────────────────────

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    for (final f in featureFlags) {
      _flags[f.key] = prefs.getBool(f.key) ?? false;
    }
    final idx = (prefs.getInt('dev_theme_mode') ?? 0)
        .clamp(0, ThemeMode.values.length - 1);
    _themeMode = ThemeMode.values[idx];
    // Time-travel is intentionally NOT persisted — it resets on restart.
  }

  // ── Time travel ─────────────────────────────────────────────────────────────

  void setDateOverride(DateTime? date) {
    _dateOverride = date;
    notifyListeners();
  }

  // ── Feature flags ────────────────────────────────────────────────────────────

  Future<void> setFlag(String key, bool value) async {
    _flags[key] = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    notifyListeners();
  }

  // ── UI overrides ─────────────────────────────────────────────────────────────

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dev_theme_mode', mode.index);
    notifyListeners();
  }

  void setLayoutBounds(bool enabled) {
    _layoutBounds = enabled;
    debugPaintSizeEnabled = enabled;
    notifyListeners();
  }

  // ── Demo tag ────────────────────────────────────────────────────────────────

  /// Tag embedded in `notes` for every demo/test renewal so we can batch-delete.
  static const demoTag = '[DEMO]';

  static bool isDemoRenewal(Renewal r) =>
      r.notes?.contains(demoTag) ?? false;

  // ── Demo data factories ──────────────────────────────────────────────────────

  static Renewal _make({
    required String id,
    required String title,
    required RenewalCategory category,
    required DateTime date,
    double? amount,
    RenewalPriority priority = RenewalPriority.medium,
    RenewalStatus status = RenewalStatus.upcoming,
    String notes = '[DEMO]',
  }) {
    final now = DateTime.now();
    return Renewal(
      id: id,
      title: title,
      category: category,
      renewalDate: date,
      paymentRequired: amount != null,
      amount: amount,
      currency: RenewalCurrency.inr,
      priority: priority,
      status: status,
      createdAt: now,
      updatedAt: now,
      notes: notes,
    );
  }

  /// A curated set of 10 realistic demo renewals.
  static List<Renewal> buildDemoSet() {
    final t = DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    return [
      _make(id: 'demo_01', title: 'Car Insurance [DEMO]', category: RenewalCategory.insurance, date: today.add(const Duration(days: 7)), amount: 12000, priority: RenewalPriority.high),
      _make(id: 'demo_02', title: 'Health Insurance [DEMO]', category: RenewalCategory.insurance, date: today.add(const Duration(days: 30)), amount: 25000),
      _make(id: 'demo_03', title: 'Passport [DEMO]', category: RenewalCategory.passport, date: today.add(const Duration(days: 180)), priority: RenewalPriority.critical),
      _make(id: 'demo_04', title: 'Driving Licence [DEMO]', category: RenewalCategory.drivingLicence, date: today.add(const Duration(days: 45)), priority: RenewalPriority.high),
      _make(id: 'demo_05', title: 'Netflix [DEMO]', category: RenewalCategory.subscription, date: today.add(const Duration(days: 5)), amount: 649),
      _make(id: 'demo_06', title: 'Car EMI [DEMO]', category: RenewalCategory.loanEmi, date: today.add(const Duration(days: 3)), amount: 15000, priority: RenewalPriority.high),
      _make(id: 'demo_07', title: 'Electricity [DEMO]', category: RenewalCategory.electricity, date: today.add(const Duration(days: 12)), amount: 2200),
      _make(id: 'demo_08', title: 'Water Bill [DEMO]', category: RenewalCategory.water, date: today.subtract(const Duration(days: 2)), amount: 450, status: RenewalStatus.overdue),
      _make(id: 'demo_09', title: 'Vehicle Tax [DEMO]', category: RenewalCategory.vehicle, date: today.add(const Duration(days: 90)), amount: 5000),
      _make(id: 'demo_10', title: 'Gym Membership [DEMO]', category: RenewalCategory.gym, date: today.add(const Duration(days: 20)), amount: 2500),
    ];
  }

  /// Specific test events for individual scenario testing.
  static List<Renewal> buildTestEventSet() {
    final t = DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    final ts = t.millisecondsSinceEpoch;
    return [
      _make(id: 'test_1_$ts', title: '[TEST] Insurance Expiring Today', category: RenewalCategory.insurance, date: today, amount: 12000, priority: RenewalPriority.critical),
      _make(id: 'test_2_$ts', title: '[TEST] Insurance Expiring Tomorrow', category: RenewalCategory.insurance, date: today.add(const Duration(days: 1)), amount: 8000, priority: RenewalPriority.high),
      _make(id: 'test_3_$ts', title: '[TEST] Passport in 30 Days', category: RenewalCategory.passport, date: today.add(const Duration(days: 30))),
      _make(id: 'test_4_$ts', title: '[TEST] Expired Driving Licence', category: RenewalCategory.drivingLicence, date: today.subtract(const Duration(days: 45)), status: RenewalStatus.overdue),
      _make(id: 'test_5_$ts', title: '[TEST] Medical Reminder', category: RenewalCategory.other, date: today.add(const Duration(days: 14))),
      _make(id: 'test_6_$ts', title: '[TEST] EMI Reminder', category: RenewalCategory.loanEmi, date: today.add(const Duration(days: 2)), amount: 20000, priority: RenewalPriority.high),
      _make(id: 'test_7_$ts', title: '[TEST] Vehicle Tax', category: RenewalCategory.vehicle, date: today.add(const Duration(days: 60)), amount: 4500),
    ];
  }

  /// [count] random renewals covering all categories and priorities.
  static List<Renewal> buildRandomSet(int count) {
    final rng = Random();
    final t = DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    final cats = RenewalCategory.values;
    final pris = RenewalPriority.values;
    return List.generate(count, (i) {
      final daysOffset = rng.nextInt(400) - 50;
      final date = today.add(Duration(days: daysOffset));
      final cat = cats[rng.nextInt(cats.length)];
      final hasAmount = rng.nextBool();
      return _make(
        id: 'rand_${t.millisecondsSinceEpoch}_$i',
        title: '${cat.label} ${i + 1} [DEMO]',
        category: cat,
        date: date,
        amount: hasAmount ? (rng.nextInt(50000) + 100).toDouble() : null,
        priority: pris[rng.nextInt(pris.length)],
      );
    });
  }

  /// Events with missing docs, notes, amounts — for intelligence QA.
  static List<Renewal> buildLowQualityEvents() {
    final t = DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    final ts = t.millisecondsSinceEpoch;
    return [
      Renewal(
        id: 'intel_low_$ts',
        title: 'Incomplete Insurance [DEMO]',
        category: RenewalCategory.insurance,
        renewalDate: today.add(const Duration(days: 20)),
        paymentRequired: true,
        priority: RenewalPriority.high,
        reminderSchedule: const [7],
        createdAt: t,
        updatedAt: t,
        notes: demoTag,
      ),
      Renewal(
        id: 'intel_low2_$ts',
        title: 'No Notes Passport [DEMO]',
        category: RenewalCategory.passport,
        renewalDate: today.add(const Duration(days: 40)),
        priority: RenewalPriority.medium,
        createdAt: t,
        updatedAt: t,
        notes: demoTag,
      ),
    ];
  }

  /// Events explicitly missing documents (for health-check QA).
  static List<Renewal> buildMissingDocumentEvents() {
    final t = DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    final ts = t.millisecondsSinceEpoch;
    return [
      _make(
        id: 'intel_nodoc_$ts',
        title: 'Policy Without Document [DEMO]',
        category: RenewalCategory.insurance,
        date: today.add(const Duration(days: 15)),
        amount: 8000,
        notes: '$demoTag Missing attachment',
      ),
    ];
  }

  /// Overdue events for intelligence testing.
  static List<Renewal> buildOverdueIntelligenceEvents() {
    final t = DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    final ts = t.millisecondsSinceEpoch;
    return [
      _make(
        id: 'intel_overdue_$ts',
        title: 'Overdue Licence [DEMO]',
        category: RenewalCategory.drivingLicence,
        date: today.subtract(const Duration(days: 12)),
        status: RenewalStatus.overdue,
        priority: RenewalPriority.critical,
      ),
    ];
  }

  /// Duplicate-title events for duplicate detection QA.
  static List<Renewal> buildDuplicateEvents() {
    final t = DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    final ts = t.millisecondsSinceEpoch;
    return [
      _make(
        id: 'intel_dup_a_$ts',
        title: 'Netflix Subscription [DEMO]',
        category: RenewalCategory.subscription,
        date: today.add(const Duration(days: 10)),
        amount: 649,
      ),
      _make(
        id: 'intel_dup_b_$ts',
        title: 'Netflix Subscription [DEMO]',
        category: RenewalCategory.subscription,
        date: today.add(const Duration(days: 35)),
        amount: 649,
      ),
    ];
  }

  /// Life Insights — diverse categories for statistics QA.
  static List<Renewal> buildInsightsStatisticsSet() {
    final t = DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    final ts = t.millisecondsSinceEpoch;
    return [
      _make(
        id: 'ins_stat_$ts',
        title: 'Health Cover [DEMO]',
        category: RenewalCategory.insurance,
        date: today.add(const Duration(days: 14)),
        amount: 18000,
      ),
      _make(
        id: 'ins_stat2_$ts',
        title: 'Car Service [DEMO]',
        category: RenewalCategory.vehicle,
        date: today.add(const Duration(days: 21)),
        amount: 6500,
      ),
      _make(
        id: 'ins_stat3_$ts',
        title: 'Spotify [DEMO]',
        category: RenewalCategory.subscription,
        date: today.add(const Duration(days: 8)),
        amount: 119,
      ),
      _make(
        id: 'ins_stat4_$ts',
        title: 'Property Tax [DEMO]',
        category: RenewalCategory.loanEmi,
        date: today.add(const Duration(days: 45)),
        amount: 32000,
      ),
      _make(
        id: 'ins_stat5_$ts',
        title: 'Passport Renewal [DEMO]',
        category: RenewalCategory.passport,
        date: today.add(const Duration(days: 60)),
      ),
    ];
  }

  /// Life Insights — payment events spread across months.
  static List<Renewal> buildInsightsSpendingSet() {
    final t = DateTime.now();
    final ts = t.millisecondsSinceEpoch;
    return List.generate(6, (i) {
      final offset = i - 5;
      var month = t.month + offset;
      var year = t.year;
      while (month < 1) {
        month += 12;
        year--;
      }
      while (month > 12) {
        month -= 12;
        year++;
      }
      return _make(
        id: 'ins_spend_${ts}_$i',
        title: 'Monthly Bill ${i + 1} [DEMO]',
        category: RenewalCategory.electricity,
        date: DateTime(year, month, 15),
        amount: (1500 + i * 400).toDouble(),
      );
    });
  }

  /// Life Insights — upcoming events across 7/30/90 day windows.
  static List<Renewal> buildInsightsTimelineSet() {
    final t = DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    final ts = t.millisecondsSinceEpoch;
    return [
      _make(
        id: 'ins_tl1_$ts',
        title: 'Due in 3 Days [DEMO]',
        category: RenewalCategory.subscription,
        date: today.add(const Duration(days: 3)),
        amount: 499,
      ),
      _make(
        id: 'ins_tl2_$ts',
        title: 'Due in 14 Days [DEMO]',
        category: RenewalCategory.insurance,
        date: today.add(const Duration(days: 14)),
        amount: 9000,
      ),
      _make(
        id: 'ins_tl3_$ts',
        title: 'Due in 45 Days [DEMO]',
        category: RenewalCategory.vehicle,
        date: today.add(const Duration(days: 45)),
        amount: 12000,
      ),
      _make(
        id: 'ins_tl4_$ts',
        title: 'Due in 75 Days [DEMO]',
        category: RenewalCategory.water,
        date: today.add(const Duration(days: 75)),
        amount: 800,
      ),
    ];
  }
}
