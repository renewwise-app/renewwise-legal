import 'package:flutter/material.dart';

import 'package:renew_wise/models/history_entry.dart';
import 'package:renew_wise/models/renewal_currency.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/utils/date_utils.dart';
import 'package:renew_wise/widgets/event_list/event_list_reminder_card.dart';

/// Premium completed reminder card — mirrors [EventListReminderCard].
class HistoryCompletedListCard extends StatefulWidget {
  const HistoryCompletedListCard({
    super.key,
    required this.entry,
    required this.onTap,
  });

  final HistoryEntry entry;
  final VoidCallback onTap;

  @override
  State<HistoryCompletedListCard> createState() =>
      _HistoryCompletedListCardState();
}

class _HistoryCompletedListCardState extends State<HistoryCompletedListCard> {
  bool _pressed = false;

  String? _amountLabel() {
    final entry = widget.entry;
    if (entry.amount == null || entry.currencyCode == null) return null;
    final currency = RenewalCurrency.values.byName(entry.currencyCode!);
    return currency.formatAmount(entry.amount!);
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final accent = EventListReminderCard.categoryAccent(entry.category);
    final amount = _amountLabel();
    final hasPayment = entry.paymentRequired && amount != null;
    final completedLabel =
        RenewalDateUtils.formatDisplayDate(entry.completionDate);

    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minHeight: 100),
        decoration: BoxDecoration(
          color: RenewWisePalette.cardSurface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: RenewWiseShadows.listCard(pressed: _pressed),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: RenewWisePalette.cardSurface,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (value) => setState(() => _pressed = value),
            splashColor: AppColors.primary.withAlpha(24),
            highlightColor: AppColors.primary.withAlpha(12),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: accent.withAlpha(28),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      entry.category.icon,
                      color: accent,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          entry.title,
                          style: RenewWiseTypography.cardTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.categoryLabel,
                          style: RenewWiseTypography.tileEventCount.copyWith(
                            color: RenewWisePalette.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        _CompletedChip(label: completedLabel),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        hasPayment ? amount : 'No payment',
                        style: RenewWiseTypography.tileAmount.copyWith(
                          color: hasPayment
                              ? AppColors.primary
                              : RenewWisePalette.textCaption,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFCBD5E1),
                        size: 22,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletedChip extends StatelessWidget {
  const _CompletedChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF16A34A),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: RenewWiseTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF15803D),
            ),
          ),
        ],
      ),
    );
  }
}
