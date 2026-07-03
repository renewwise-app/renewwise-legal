import 'package:flutter/material.dart';

import 'package:renew_wise/widgets/common/renew_wise_empty_state.dart';

/// Premium empty state for event list screens.
class EventListEmptyState extends StatelessWidget {
  const EventListEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.event_available_rounded,
    this.onAddReminder,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onAddReminder;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    final label = actionLabel ?? (onAddReminder != null ? 'Add Reminder' : null);
    final handler = onAction ?? onAddReminder;

    return RenewWiseEmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
      actionLabel: label,
      onAction: handler,
      actionIcon: actionIcon,
    );
  }
}
