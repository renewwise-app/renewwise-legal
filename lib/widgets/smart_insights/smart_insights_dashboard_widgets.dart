import 'package:flutter/material.dart';

import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/utils/feature_purpose_messaging.dart';
import 'package:renew_wise/widgets/common/feature_purpose_subtitle.dart';

/// Smart Insights dashboard header.
class SmartInsightsPageHeader extends StatelessWidget {
  const SmartInsightsPageHeader({
    super.key,
    this.purposeMessage,
  });

  final String? purposeMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Smart Insights', style: RenewWiseTypography.screenTitle),
        const SizedBox(height: 8),
        FeaturePurposeSubtitle(
          purposeMessage ?? FeaturePurposeMessaging.smartInsights,
        ),
      ],
    );
  }
}
