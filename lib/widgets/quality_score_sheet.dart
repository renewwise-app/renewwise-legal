import 'package:flutter/material.dart';

import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/utils/event_quality_score.dart';
import 'package:renew_wise/utils/smart_suggestions.dart';

Future<void> showQualityScoreSheet(
  BuildContext context,
  EventQualityResult result,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final levelColor = switch (result.level) {
        QualityLevel.excellent => AppColors.primaryGreen,
        QualityLevel.good => AppColors.primary,
        QualityLevel.needsAttention => AppColors.gold,
      };
      return Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          24 + MediaQuery.paddingOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reminder Quality',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: levelColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    result.level.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: levelColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${result.score}/100',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Why this score',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...result.reasons.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 16, color: AppColors.primaryGreen),
                    const SizedBox(width: 8),
                    Expanded(child: Text(r, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
            ),
            if (result.suggestions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Suggestions',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...result.suggestions.map(
                (s) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_iconFor(s.action), color: AppColors.primary),
                  title: Text(s.title),
                  subtitle: Text(s.subtitle),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

IconData _iconFor(SmartSuggestionAction action) => switch (action) {
      SmartSuggestionAction.attachDocument => Icons.attach_file_outlined,
      SmartSuggestionAction.addAmount => Icons.payments_outlined,
      SmartSuggestionAction.addNotes => Icons.notes_outlined,
      SmartSuggestionAction.reschedule => Icons.calendar_month_outlined,
      SmartSuggestionAction.prepareNextReminder => Icons.repeat_rounded,
      SmartSuggestionAction.editReminderSchedule =>
        Icons.notifications_active_outlined,
    };

class QualityScoreChip extends StatelessWidget {
  const QualityScoreChip({
    super.key,
    required this.result,
    this.onTap,
    this.compact = false,
  });

  final EventQualityResult result;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = switch (result.level) {
      QualityLevel.excellent => AppColors.primaryGreen,
      QualityLevel.good => AppColors.primary,
      QualityLevel.needsAttention => AppColors.gold,
    };
    return Material(
      color: color.withAlpha(18),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 3 : 5,
          ),
          child: Text(
            result.level.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 10 : null,
                ),
          ),
        ),
      ),
    );
  }
}
