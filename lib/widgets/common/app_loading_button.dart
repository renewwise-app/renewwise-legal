import 'package:flutter/material.dart';

/// Primary/outlined button with inline loading indicator.
class AppLoadingButton extends StatelessWidget {
  const AppLoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.outlined = false,
    this.style,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Widget? icon;
  final bool outlined;
  final ButtonStyle? style;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = !loading && onPressed != null;
    final child = loading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: outlined
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onPrimary,
            ),
          )
        : icon == null
            ? Text(label)
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon!,
                  const SizedBox(width: 8),
                  Text(label),
                ],
              );

    final button = outlined
        ? OutlinedButton(
            onPressed: enabled ? onPressed : null,
            style: style,
            child: child,
          )
        : FilledButton(
            onPressed: enabled ? onPressed : null,
            style: style,
            child: child,
          );

    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
