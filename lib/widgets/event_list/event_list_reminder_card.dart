import 'package:flutter/material.dart';

import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/renewal_category.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';

/// Premium reminder card for Packet 02.1 event list screens.
class EventListReminderCard extends StatefulWidget {
  const EventListReminderCard({
    super.key,
    required this.renewal,
    required this.onTap,
  });

  final Renewal renewal;
  final VoidCallback onTap;

  static String statusLabel(Renewal renewal) {
    if (renewal.isOverdue) {
      final days = renewal.daysRemaining.abs();
      return days == 1 ? '1 Day Late' : '$days Days Late';
    }
    if (renewal.daysRemaining == 0) return 'Today';
    if (renewal.daysRemaining == 1) return 'Tomorrow';
    return '${renewal.daysRemaining} Days';
  }

  static ({Color dot, Color bg, Color text}) statusColors(Renewal renewal) {
    if (renewal.isOverdue) {
      return (
        dot: const Color(0xFFF87171),
        bg: const Color(0xFFFEE2E2),
        text: const Color(0xFFB91C1C),
      );
    }
    if (renewal.daysRemaining == 0) {
      return (
        dot: const Color(0xFFFB923C),
        bg: const Color(0xFFFFEDD5),
        text: const Color(0xFFC2410C),
      );
    }
    if (renewal.daysRemaining == 1) {
      return (
        dot: const Color(0xFF4ADE80),
        bg: const Color(0xFFDCFCE7),
        text: const Color(0xFF15803D),
      );
    }
    return (
      dot: const Color(0xFF93C5FD),
      bg: const Color(0xFFDBEAFE),
      text: const Color(0xFF1D4ED8),
    );
  }

  static Color categoryAccent(RenewalCategory category) {
    return switch (category) {
      RenewalCategory.insurance => const Color(0xFF10B981),
      RenewalCategory.vehicle => const Color(0xFF059669),
      RenewalCategory.drivingLicence => const Color(0xFF0EA5E9),
      RenewalCategory.passport => const Color(0xFF6366F1),
      RenewalCategory.internet => const Color(0xFFEF4444),
      RenewalCategory.electricity => const Color(0xFFF59E0B),
      RenewalCategory.water => const Color(0xFF3B82F6),
      RenewalCategory.gas => const Color(0xFFF97316),
      RenewalCategory.gym => const Color(0xFFEC4899),
      RenewalCategory.subscription => const Color(0xFF8B5CF6),
      RenewalCategory.loanEmi => const Color(0xFF64748B),
      RenewalCategory.creditCard => const Color(0xFF8B5CF6),
      RenewalCategory.warranty => const Color(0xFF14B8A6),
      RenewalCategory.other => const Color(0xFF10B981),
    };
  }

  @override
  State<EventListReminderCard> createState() => _EventListReminderCardState();
}

class _EventListReminderCardState extends State<EventListReminderCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final renewal = widget.renewal;
    final accent = EventListReminderCard.categoryAccent(renewal.category);
    final status = EventListReminderCard.statusColors(renewal);
    final hasPayment = renewal.paymentRequired && renewal.amount != null;

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
                      renewal.category.icon,
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
                          renewal.title,
                          style: RenewWiseTypography.cardTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          renewal.categoryLabel,
                          style: RenewWiseTypography.tileEventCount.copyWith(
                            color: RenewWisePalette.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        _StatusChip(
                          label: EventListReminderCard.statusLabel(renewal),
                          dotColor: status.dot,
                          backgroundColor: status.bg,
                          textColor: status.text,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        hasPayment
                            ? renewal.formattedAmount!
                            : 'No payment',
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.dotColor,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color dotColor;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: RenewWiseTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
