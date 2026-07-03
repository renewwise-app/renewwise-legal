import 'package:flutter/material.dart';

import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/widgets/common/renew_wise_back_button.dart';

/// Compact header for Packet 02.1 event list screens.
class EventListHeader extends StatelessWidget {
  const EventListHeader({
    super.key,
    required this.title,
    required this.eventCount,
    required this.dueLabel,
    required this.onBack,
    required this.onSort,
  });

  final String title;
  final int eventCount;
  final String? dueLabel;
  final VoidCallback onBack;
  final VoidCallback onSort;

  @override
  Widget build(BuildContext context) {
    final eventLabel = '$eventCount Event${eventCount == 1 ? '' : 's'}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RenewWiseBackButton(onPressed: onBack),
              const SizedBox(width: 4),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: RenewWiseTypography.cardTitle,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        eventLabel,
                        style: RenewWiseTypography.tileEventCount,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _RoundIconButton(
                  icon: Icons.swap_vert_rounded,
                  onTap: onSort,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.primary.withAlpha(200),
                ),
                const SizedBox(width: 6),
                Text(
                  eventLabel,
                  style: RenewWiseTypography.tileEventCount,
                ),
                if (dueLabel != null) ...[
                  Container(
                    width: 1,
                    height: 14,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: const Color(0xFFE2E8F0),
                  ),
                  Text(
                    dueLabel!,
                    style: RenewWiseTypography.tileAmount.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: RenewWisePalette.cardSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: AppIconSize.sm + 2,
            color: RenewWisePalette.textPrimary,
          ),
        ),
      ),
    );
  }
}
