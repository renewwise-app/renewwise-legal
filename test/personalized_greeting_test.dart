import 'package:flutter_test/flutter_test.dart';
import 'package:renew_wise/utils/personalized_greeting.dart';

void main() {
  group('PersonalizedGreeting.timeOfDayPeriod', () {
    test('morning is 5:00 AM through 11:59 AM', () {
      expect(
        PersonalizedGreeting.timeOfDayPeriod(DateTime(2026, 6, 1, 5, 0)),
        'Good Morning',
      );
      expect(
        PersonalizedGreeting.timeOfDayPeriod(DateTime(2026, 6, 1, 11, 59)),
        'Good Morning',
      );
    });

    test('afternoon is 12:00 PM through 4:59 PM', () {
      expect(
        PersonalizedGreeting.timeOfDayPeriod(DateTime(2026, 6, 1, 12, 0)),
        'Good Afternoon',
      );
      expect(
        PersonalizedGreeting.timeOfDayPeriod(DateTime(2026, 6, 1, 16, 59)),
        'Good Afternoon',
      );
    });

    test('evening is 5:00 PM through 4:59 AM', () {
      expect(
        PersonalizedGreeting.timeOfDayPeriod(DateTime(2026, 6, 1, 17, 0)),
        'Good Evening',
      );
      expect(
        PersonalizedGreeting.timeOfDayPeriod(DateTime(2026, 6, 1, 4, 59)),
        'Good Evening',
      );
    });
  });

  group('PersonalizedGreeting.greeting', () {
    test('includes trimmed name after period', () {
      expect(
        PersonalizedGreeting.greeting(
          userName: '  Ujjal  ',
          now: DateTime(2026, 6, 1, 9, 0),
        ),
        'Good Morning, Ujjal',
      );
    });

    test('returns period only when name is empty', () {
      expect(
        PersonalizedGreeting.greeting(
          userName: '   ',
          now: DateTime(2026, 6, 1, 18, 0),
        ),
        'Good Evening',
      );
    });
  });
}
