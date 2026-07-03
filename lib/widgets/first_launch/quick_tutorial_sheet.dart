import 'package:flutter/material.dart';

import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';

/// Lightweight walkthrough — opened from the first-launch offer only.
class QuickTutorialSheet {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => const _QuickTutorialContent(),
    );
  }
}

class _QuickTutorialContent extends StatelessWidget {
  const _QuickTutorialContent();

  static const _steps = [
    (
      icon: Icons.home_outlined,
      title: 'Your dashboard',
      body: 'See today, this week, and this month at a glance from Home.',
    ),
    (
      icon: Icons.notifications_active_outlined,
      title: 'Add reminders',
      body: 'Capture renewals, bills, and important dates — RenewWise reminds you in time.',
    ),
    (
      icon: Icons.insights_outlined,
      title: 'Smart Insights',
      body: 'Understand spending and plan goals when you are ready — all offline.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Quick walkthrough', style: RenewWiseTypography.cardTitle),
            const SizedBox(height: 8),
            Text(
              'Three things to know before you begin.',
              style: RenewWiseTypography.secondary,
            ),
            const SizedBox(height: 16),
            ..._steps.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(step.icon, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: RenewWiseTypography.tileEventCount.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(step.body, style: RenewWiseTypography.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ],
        ),
      ),
    );
  }
}
