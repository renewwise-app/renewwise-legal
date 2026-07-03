import 'package:flutter/material.dart';

import 'package:renew_wise/models/sharing_models.dart';
import 'package:renew_wise/theme/app_theme.dart';

class ShareVisibilityBadge extends StatelessWidget {
  const ShareVisibilityBadge({
    super.key,
    required this.visibility,
    this.compact = false,
  });

  final ShareVisibility visibility;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isShared = visibility == ShareVisibility.shared;
    final color = isShared ? AppColors.teal : Theme.of(context).colorScheme.onSurfaceVariant;
    final emoji = isShared ? '👥' : '🔒';
    final label = isShared ? 'Shared' : 'Private';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: compact ? 11 : 12)),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SharedDocumentBadge extends StatelessWidget {
  const SharedDocumentBadge({super.key, this.compact = true});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('👥', style: TextStyle(fontSize: 11)),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              'Shared',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.teal,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.name,
    this.hue = 200,
    this.radius = 20,
  });

  final String name;
  final int hue;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final color = HSLColor.fromAHSL(1, hue.toDouble(), 0.45, 0.48).toColor();
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.18),
      child: Text(
        initial,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.85,
        ),
      ),
    );
  }
}

class PermissionChip extends StatelessWidget {
  const PermissionChip({super.key, required this.permission});

  final SharePermission permission;

  @override
  Widget build(BuildContext context) {
    final color = switch (permission) {
      SharePermission.owner => AppColors.primary,
      SharePermission.editor => AppColors.gold,
      SharePermission.viewer => Theme.of(context).colorScheme.onSurfaceVariant,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        permission.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
