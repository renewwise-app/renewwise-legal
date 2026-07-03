import 'package:flutter/material.dart';

import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/utils/assistant_reminder_suggestions.dart';

/// Animated dot progress — no "Step X of Y" text.
class AssistantProgressBar extends StatelessWidget {
  const AssistantProgressBar({
    super.key,
    required this.activeIndex,
    this.total = 5,
    this.messageIndex = 0,
  });

  /// 0-based index of current question (0..4).
  final int activeIndex;
  final int total;
  final int messageIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = AssistantEncouragements.forStepIndex(messageIndex);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: List.generate(total, (i) {
              final isActive = i <= activeIndex;
              final isCurrent = i == activeIndex;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    height: isCurrent ? 8 : 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: Text(
              message,
              key: ValueKey(message),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
