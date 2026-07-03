import 'package:flutter/material.dart';

import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/repeat_cycle.dart';
import 'package:renew_wise/utils/recurrence_utils.dart';

/// User-facing reminder creation paths for the guided Add Reminder workflow.
enum ReminderWorkflowType {
  oneTime(
    title: 'One-Time Reminder',
    description: 'A single date — passport, appointment, birthday, or expiry.',
    examples: 'Passport · Appointment · Birthday · Document Expiry',
    icon: Icons.event_available_outlined,
  ),
  recurring(
    title: 'Recurring Reminder',
    description: 'Repeats on a schedule — daily habits, weekly meetings, bills.',
    examples: 'Daily Medicine · Gym · Weekly Meeting · Monthly Bill',
    icon: Icons.repeat_rounded,
  ),
  renewal(
    title: 'Renewal Reminder',
    description: 'Renewals with advance reminders — insurance, licences, subscriptions.',
    examples: 'Insurance · Vehicle · Driving Licence · Subscription',
    icon: Icons.autorenew_rounded,
  );

  const ReminderWorkflowType({
    required this.title,
    required this.description,
    required this.examples,
    required this.icon,
  });

  final String title;
  final String description;
  final String examples;
  final IconData icon;
}

/// Renewal-cycle options shown in the Renewal Reminder path.
const kRenewalWorkflowCycles = <RepeatCycle>[
  RepeatCycle.yearly,
  RepeatCycle.monthly,
  RepeatCycle.quarterly,
];

ReminderWorkflowType inferReminderWorkflowType(Renewal renewal) {
  if (!RecurrenceUtils.isRecurring(renewal)) {
    return ReminderWorkflowType.oneTime;
  }
  if (kRenewalWorkflowCycles.contains(renewal.repeatCycle)) {
    return ReminderWorkflowType.renewal;
  }
  return ReminderWorkflowType.recurring;
}
