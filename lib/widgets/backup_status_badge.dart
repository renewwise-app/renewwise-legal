import 'package:flutter/material.dart';

import 'package:renew_wise/models/backup_models.dart';
import 'package:renew_wise/theme/app_theme.dart';

class BackupStatusBadge extends StatelessWidget {
  const BackupStatusBadge({super.key, required this.status});

  final BackupStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      BackupStatus.protected => (AppColors.primary, Icons.verified_user_outlined),
      BackupStatus.pending => (AppColors.gold, Icons.hourglass_top_rounded),
      BackupStatus.failed => (AppColors.critical, Icons.error_outline_rounded),
      BackupStatus.notConnected => (
          Theme.of(context).colorScheme.onSurfaceVariant,
          Icons.cloud_off_outlined,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
