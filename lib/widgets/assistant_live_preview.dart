import 'package:flutter/material.dart';

import 'package:renew_wise/models/assistant_draft.dart';
import 'package:renew_wise/models/renewal_currency.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/utils/date_utils.dart';

/// Floating live preview card — updates as the user answers.
class AssistantLivePreview extends StatelessWidget {
  const AssistantLivePreview({
    super.key,
    required this.draft,
    this.currency = RenewalCurrency.inr,
  });

  final AssistantDraft draft;
  final RenewalCurrency currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = draft.categoryOption;
    final date = draft.renewalDate;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        elevation: 0,
        color: AppColors.primary.withAlpha(12),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withAlpha(40)),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    category?.icon ?? Icons.event_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Live Preview',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                draft.title.trim().isEmpty ? 'Your event' : draft.title.trim(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              _Row(
                icon: Icons.category_outlined,
                label: category?.displayLabel ?? 'Category',
              ),
              if (date != null) ...[
                _Row(
                  icon: Icons.event_outlined,
                  label: RenewalDateUtils.formatDisplayDate(date),
                ),
                _Row(
                  icon: Icons.schedule_outlined,
                  label: RenewalDateUtils.daysRemainingLabel(date),
                ),
              ],
              if (draft.amount != null && draft.amount! > 0)
                _Row(
                  icon: Icons.payments_outlined,
                  label: currency.formatAmount(draft.amount!),
                ),
              if (draft.reminderSchedule.isNotEmpty)
                _Row(
                  icon: Icons.notifications_outlined,
                  label: draft.reminderSchedule
                      .map((d) => '$d days before')
                      .join(', '),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
