import 'package:flutter/material.dart';

import 'package:renew_wise/theme/design_tokens.dart';

/// Soft scale feedback for tappable elements.
class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.enabled = true,
    this.scaleDown = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;
  final bool enabled;
  final double scaleDown;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? AppRadius.buttonBorder;
    final active = widget.enabled && widget.onTap != null;

    return AnimatedScale(
      scale: _pressed && active ? widget.scaleDown : 1,
      duration: const Duration(milliseconds: 120),
      curve: AppMotion.curve,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: active ? widget.onTap : null,
          onLongPress: active ? widget.onLongPress : null,
          onHighlightChanged:
              active ? (value) => setState(() => _pressed = value) : null,
          borderRadius: radius,
          splashColor: Theme.of(context).colorScheme.primary.withAlpha(28),
          highlightColor: Theme.of(context).colorScheme.primary.withAlpha(14),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Tappable card with subtle press elevation and scale.
class AppInteractiveCard extends StatefulWidget {
  const AppInteractiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.margin = EdgeInsets.zero,
    this.color,
    this.border,
    this.hero = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final BorderSide? border;
  final bool hero;

  @override
  State<AppInteractiveCard> createState() => _AppInteractiveCardState();
}

class _AppInteractiveCardState extends State<AppInteractiveCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = widget.borderRadius ?? AppRadius.cardBorder;
    final enabled = widget.onTap != null;
    final pressedElevation = widget.hero ? 1.0 : 0.5;

    return AnimatedScale(
      scale: _pressed && enabled ? 0.985 : 1,
      duration: const Duration(milliseconds: 120),
      curve: AppMotion.curve,
      child: AnimatedContainer(
        duration: AppMotion.duration,
        curve: AppMotion.curve,
        margin: widget.margin,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: enabled && _pressed
              ? [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withAlpha(28),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: widget.color ?? theme.cardTheme.color,
          elevation: _pressed && enabled ? pressedElevation : 0,
          shadowColor: theme.colorScheme.shadow.withAlpha(40),
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: widget.border ??
                BorderSide(
                  color: theme.colorScheme.outlineVariant.withAlpha(120),
                ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: enabled
                ? (value) => setState(() => _pressed = value)
                : null,
            borderRadius: radius,
            splashColor: theme.colorScheme.primary.withAlpha(24),
            highlightColor: theme.colorScheme.primary.withAlpha(12),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
