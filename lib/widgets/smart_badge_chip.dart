import 'package:flutter/material.dart';

import 'package:renew_wise/models/smart_badge.dart';

class SmartBadgeChip extends StatelessWidget {
  const SmartBadgeChip({
    super.key,
    required this.kind,
    this.compact = false,
  });

  final SmartBadgeKind kind;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: kind.color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kind.color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) ...[
            Icon(kind.icon, size: 12, color: kind.color),
            const SizedBox(width: 4),
          ],
          Text(
            kind.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: kind.color,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 10 : null,
                ),
          ),
        ],
      ),
    );
  }
}

class SmartBadgeRow extends StatelessWidget {
  const SmartBadgeRow({
    super.key,
    required this.badges,
    this.maxVisible = 3,
    this.compact = false,
  });

  final List<SmartBadgeKind> badges;
  final int maxVisible;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink();
    final visible = badges.take(maxVisible).toList();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: visible.map((b) => SmartBadgeChip(kind: b, compact: compact)).toList(),
    );
  }
}
