import 'package:flutter/material.dart';

import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/widgets/home/home_micro_interactions.dart';
import 'package:renew_wise/widgets/renew_wise_logo.dart';

/// RenewWise brand block shown at the top of the Home dashboard.
class HomeBrandHeader extends StatelessWidget {
  const HomeBrandHeader({
    super.key,
    required this.greeting,
    required this.todayEventCount,
    this.welcomePurposeMessage,
  });

  final String greeting;
  final int todayEventCount;
  final String? welcomePurposeMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const RenewWiseLogo(size: 52),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RenewWise',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: RenewWisePalette.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Because Peace of Mind Matters.',
                    style: RenewWiseTypography.secondary.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          '$greeting 👋',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: RenewWisePalette.textPrimary,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        if (welcomePurposeMessage != null &&
            welcomePurposeMessage!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            welcomePurposeMessage!,
            style: RenewWiseTypography.secondary.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            const HomePulsingStatusDot(),
            const SizedBox(width: AppSpacing.sm),
            Text(
              todayEventCount == 0
                  ? 'Nothing due today.'
                  : todayEventCount == 1
                      ? 'You have 1 event today.'
                      : 'You have $todayEventCount events today.',
              style: RenewWiseTypography.secondary,
            ),
          ],
        ),
      ],
    );
  }
}
