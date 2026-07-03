import 'package:flutter_test/flutter_test.dart';
import 'package:renew_wise/utils/reminder_schedule_utils.dart';

void main() {
  group('ReminderScheduleUtils.availablePresetOptions', () {
    test('Example 1 — expiry 10 June shows 7, 3, 1 only', () {
      final now = DateTime(2026, 6, 1);
      final expiry = DateTime(2026, 6, 10);

      expect(
        ReminderScheduleUtils.availablePresetOptions(expiry, now: now),
        [7, 3, 1],
      );
    });

    test('Example 2 — expiry 25 June shows 15, 7, 3, 1', () {
      final now = DateTime(2026, 6, 1);
      final expiry = DateTime(2026, 6, 25);

      expect(
        ReminderScheduleUtils.availablePresetOptions(expiry, now: now),
        [15, 7, 3, 1],
      );
    });

    test('Example 3 — expiry 15 September shows all presets', () {
      final now = DateTime(2026, 6, 1);
      final expiry = DateTime(2026, 9, 15);

      expect(
        ReminderScheduleUtils.availablePresetOptions(expiry, now: now),
        ReminderScheduleUtils.presetOptions,
      );
    });
  });

  group('ReminderScheduleUtils custom date range', () {
    test('accepts today through expiry inclusive', () {
      final now = DateTime(2026, 6, 20, 16, 30);
      final expiry = DateTime(2026, 7, 5);

      expect(
        ReminderScheduleUtils.isValidCustomReminderDate(
          expiry,
          DateTime(2026, 6, 20),
          now: now,
        ),
        isTrue,
      );
      expect(
        ReminderScheduleUtils.isValidCustomReminderDate(
          expiry,
          DateTime(2026, 7, 5),
          now: now,
        ),
        isTrue,
      );
      expect(
        ReminderScheduleUtils.isValidCustomReminderDate(
          expiry,
          DateTime(2026, 6, 19),
          now: now,
        ),
        isFalse,
      );
      expect(
        ReminderScheduleUtils.isValidCustomReminderDate(
          expiry,
          DateTime(2026, 7, 6),
          now: now,
        ),
        isFalse,
      );
    });
  });

  group('ReminderScheduleUtils custom days validation', () {
    test('Example — expiry 20 June allows days 1 through 10 only', () {
      final now = DateTime(2026, 6, 10);
      final expiry = DateTime(2026, 6, 20);

      expect(ReminderScheduleUtils.maxValidDaysBefore(expiry, now: now), 10);
      expect(
        ReminderScheduleUtils.isValidDaysBefore(expiry, 10, now: now),
        isTrue,
      );
      expect(
        ReminderScheduleUtils.isValidDaysBefore(expiry, 1, now: now),
        isTrue,
      );
      expect(
        ReminderScheduleUtils.isValidDaysBefore(expiry, 11, now: now),
        isFalse,
      );
      expect(
        ReminderScheduleUtils.reminderDateForDaysBefore(expiry, 12, now: now),
        DateTime(2026, 6, 8),
      );
      expect(
        ReminderScheduleUtils.reminderDateForDaysBefore(expiry, 5, now: now),
        DateTime(2026, 6, 15),
      );
    });

    test('maps invalid custom days to between-today-and-expiry message', () {
      final now = DateTime(2026, 6, 10);
      final expiry = DateTime(2026, 6, 20);

      expect(
        ReminderScheduleUtils.validateSchedule(
          expiry: expiry,
          reminderDays: [11],
          customDates: const [],
          reminderHour: 9,
          reminderMinute: 0,
          now: now,
        ),
        ReminderScheduleUtils.betweenTodayAndExpiryMessage,
      );
    });
  });

  group('ReminderScheduleUtils time validation', () {
    test('rejects past times when reminder date is today', () {
      final now = DateTime(2026, 6, 20, 16, 30);

      expect(
        ReminderScheduleUtils.isValidReminderTime(
          DateTime(2026, 6, 20),
          17,
          0,
          now: now,
        ),
        isTrue,
      );
      expect(
        ReminderScheduleUtils.isValidReminderTime(
          DateTime(2026, 6, 20),
          15,
          0,
          now: now,
        ),
        isFalse,
      );
    });

    test('allows any time on a future reminder date', () {
      final now = DateTime(2026, 6, 20, 16, 30);

      expect(
        ReminderScheduleUtils.isValidReminderTime(
          DateTime(2026, 6, 21),
          9,
          0,
          now: now,
        ),
        isTrue,
      );
    });
  });

  group('ReminderScheduleUtils custom selection helpers', () {
    test('requires future time when a preset fires today', () {
      final now = DateTime(2026, 6, 9, 16, 30);
      final expiry = DateTime(2026, 6, 10);

      expect(
        ReminderScheduleUtils.requiresFutureTimeToday(
          expiry: expiry,
          reminderDays: [1],
          customDates: const [],
          now: now,
        ),
        isTrue,
      );
      expect(
        ReminderScheduleUtils.hasReminderSelection(
          reminderDays: [7],
          customDates: const [],
        ),
        isTrue,
      );
    });
  });
}
