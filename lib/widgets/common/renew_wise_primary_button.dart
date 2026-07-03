import 'package:flutter/material.dart';

import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/widgets/common/app_loading_button.dart';

/// Full-width primary action — consistent height, radius, and typography app-wide.
class RenewWisePrimaryButton extends StatelessWidget {
  const RenewWisePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return AppLoadingButton(
      label: label,
      onPressed: onPressed,
      loading: loading,
      icon: icon == null
          ? null
          : Icon(icon, size: AppIconSize.sm),
    );
  }
}
