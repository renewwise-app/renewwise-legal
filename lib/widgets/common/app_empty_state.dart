import 'package:flutter/material.dart';

import 'package:renew_wise/widgets/common/app_motion.dart';
import 'package:renew_wise/widgets/common/renew_wise_empty_state.dart';

/// Consistent empty state used across list screens.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    return AppFadeSlideIn(
      child: RenewWiseEmptyState(
        icon: icon,
        title: title,
        subtitle: subtitle,
        actionLabel: actionLabel,
        onAction: onAction,
        actionIcon: actionIcon,
      ),
    );
  }
}
