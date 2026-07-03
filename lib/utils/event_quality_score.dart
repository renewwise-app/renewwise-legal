import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/renewal_priority.dart';
import 'package:renew_wise/utils/smart_suggestions.dart';

enum QualityLevel {
  excellent('Excellent'),
  good('Good'),
  needsAttention('Needs Attention');

  const QualityLevel(this.label);
  final String label;
}

class EventQualityResult {
  const EventQualityResult({
    required this.score,
    required this.level,
    required this.reasons,
    required this.suggestions,
  });

  final int score;
  final QualityLevel level;
  final List<String> reasons;
  final List<SmartSuggestion> suggestions;
}

/// Offline reminder quality score (0–100).
abstract final class EventQualityScore {
  static EventQualityResult compute(
    Renewal renewal, {
    int documentCount = 0,
  }) {
    var score = 0;
    final reasons = <String>[];
    final gaps = <String>[];

    if (documentCount > 0) {
      score += 25;
      reasons.add('Documents attached');
    } else {
      gaps.add('No documents attached');
    }

    final hasNotes =
        renewal.notes != null && renewal.notes!.trim().isNotEmpty;
    if (hasNotes) {
      score += 20;
      reasons.add('Notes added');
    } else {
      gaps.add('No notes');
    }

    final schedule = renewal.customReminderDates.isNotEmpty
        ? null
        : renewal.reminderSchedule;
    final hasSchedule = renewal.customReminderDates.isNotEmpty ||
        (schedule != null && schedule.isNotEmpty);
    if (hasSchedule) {
      final scheduleSize = renewal.customReminderDates.isNotEmpty
          ? renewal.customReminderDates.length
          : schedule!.length;
      score += scheduleSize >= 3 ? 20 : 12;
      reasons.add('Reminder schedule configured');
    } else {
      gaps.add('No reminder schedule');
    }

    if (renewal.paymentRequired) {
      if (renewal.amount != null && renewal.amount! > 0) {
        score += 20;
        reasons.add('Amount recorded');
      } else {
        gaps.add('Payment event missing amount');
      }
    } else {
      score += 20;
      reasons.add('Non-payment event');
    }

    score += 8;
    reasons.add('Category: ${renewal.categoryLabel}');

    if (renewal.priority != RenewalPriority.low) {
      score += 7;
      reasons.add('Priority set to ${renewal.priority.label}');
    } else {
      gaps.add('Priority is low — consider reviewing');
    }

    score = score.clamp(0, 100);

    final level = score >= 85
        ? QualityLevel.excellent
        : score >= 60
            ? QualityLevel.good
            : QualityLevel.needsAttention;

    if (gaps.isEmpty && level == QualityLevel.excellent) {
      reasons.add('Fully prepared reminder');
    }

    return EventQualityResult(
      score: score,
      level: level,
      reasons: reasons,
      suggestions: SmartSuggestions.forRenewal(
        renewal,
        documentCount: documentCount,
      ),
    );
  }
}
