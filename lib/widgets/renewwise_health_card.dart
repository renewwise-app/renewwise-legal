import 'package:flutter/material.dart';

import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/utils/renewwise_health.dart';

class RenewWiseHealthCard extends StatelessWidget {
  const RenewWiseHealthCard({
    super.key,
    required this.report,
    required this.onIssueTap,
    this.compact = false,
    this.onReviewTap,
  });

  final HealthReport report;
  final ValueChanged<HealthIssueKind> onIssueTap;
  final bool compact;
  final VoidCallback? onReviewTap;

  static int scoreFor(HealthReport report) {
    if (report.isHealthy) return 100;
    return (100 - report.totalIssues * 8).clamp(50, 99);
  }

  static String summaryFor(HealthReport report) {
    if (report.isHealthy) return 'Everything looks good';
    if (report.totalIssues == 1) return '1 item to review';
    return '${report.totalIssues} items to review';
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _CompactHealthCard(
        report: report,
        onReviewTap: onReviewTap,
      );
    }

    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  report.isHealthy
                      ? Icons.favorite_rounded
                      : Icons.health_and_safety_outlined,
                  color: report.isHealthy
                      ? AppColors.primaryGreen
                      : AppColors.gold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'RenewWise Health',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (report.isHealthy)
                  Text(
                    'All clear',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...HealthIssueKind.values.map((kind) {
              final count = report.countFor(kind);
              return _HealthRow(
                kind: kind,
                count: count,
                onTap: count > 0 ? () => onIssueTap(kind) : null,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CompactHealthCard extends StatelessWidget {
  const _CompactHealthCard({
    required this.report,
    this.onReviewTap,
  });

  final HealthReport report;
  final VoidCallback? onReviewTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = RenewWiseHealthCard.scoreFor(report);
    final accent =
        report.isHealthy ? AppColors.primaryGreen : AppColors.gold;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(120),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onReviewTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withAlpha(22),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$score%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health Score',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      RenewWiseHealthCard.summaryFor(report),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                'Tap to Review',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: accent.withAlpha(180),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  const _HealthRow({
    required this.kind,
    required this.count,
    this.onTap,
  });

  final HealthIssueKind kind;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = count > 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                kind.icon,
                size: 18,
                color: enabled
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  kind.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: enabled
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '$count',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: enabled
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (enabled) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(180),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
