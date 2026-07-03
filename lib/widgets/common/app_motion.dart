import 'package:flutter/material.dart';

import 'package:renew_wise/theme/design_tokens.dart';

/// Standard RenewWise page transition — fade + slight upward slide.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.curve,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

/// Shared route helper for push navigation.
abstract final class AppPageRoute {
  static Route<T> fadeSlide<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, _, _) => page,
      transitionDuration: AppMotion.duration,
      reverseTransitionDuration: AppMotion.duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return const AppPageTransitionsBuilder().buildTransitions(
          _DummyRoute<T>(),
          context,
          animation,
          secondaryAnimation,
          child,
        );
      },
    );
  }
}

class _DummyRoute<T> extends PageRoute<T> {
  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get barrierDismissible => false;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) =>
      const SizedBox.shrink();

  @override
  bool get maintainState => false;

  @override
  Duration get transitionDuration => AppMotion.duration;
}

/// Card/list item entrance — fade with slight upward movement.
class AppFadeSlideIn extends StatelessWidget {
  const AppFadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.duration + delay,
      curve: AppMotion.curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Animated expand/collapse wrapper for sections.
class AppExpandable extends StatelessWidget {
  const AppExpandable({
    super.key,
    required this.expanded,
    required this.child,
  });

  final bool expanded;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppMotion.duration,
      curve: AppMotion.curve,
      alignment: Alignment.topCenter,
      child: expanded ? child : const SizedBox.shrink(),
    );
  }
}
