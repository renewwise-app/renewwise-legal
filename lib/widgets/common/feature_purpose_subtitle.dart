import 'package:flutter/material.dart';

import 'package:renew_wise/theme/renew_wise_design_system.dart';

/// Subtle benefit-oriented guidance below a section title.
class FeaturePurposeSubtitle extends StatelessWidget {
  const FeaturePurposeSubtitle(
    this.message, {
    super.key,
    this.padding,
  });

  final String message;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Text(
        message,
        style: RenewWiseTypography.secondary.copyWith(height: 1.45),
      ),
    );
  }
}
