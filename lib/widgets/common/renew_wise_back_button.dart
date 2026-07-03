import 'package:flutter/material.dart';

import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';

/// Consistent back control for pushed screens — never appears disabled when tappable.
class RenewWiseBackButton extends StatelessWidget {
  const RenewWiseBackButton({
    super.key,
    this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed ?? () => Navigator.maybePop(context),
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
            Icons.arrow_back_rounded,
            size: AppIconSize.sm + 2,
            color: RenewWisePalette.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Standard [AppBar] leading back button matching [RenewWiseBackButton] styling.
class RenewWiseAppBarBackButton extends StatelessWidget {
  const RenewWiseAppBarBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.arrow_back_rounded,
        color: RenewWisePalette.textPrimary,
        size: AppIconSize.sm + 2,
      ),
      onPressed: () => Navigator.maybePop(context),
    );
  }
}
