import 'package:flutter/material.dart';

import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';

/// Soft pulse for the green status dot in the Home header (Design Lock v1.0).
class HomePulsingStatusDot extends StatefulWidget {
  const HomePulsingStatusDot({super.key});

  @override
  State<HomePulsingStatusDot> createState() => _HomePulsingStatusDotState();
}

class _HomePulsingStatusDotState extends State<HomePulsingStatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: RenewWiseHomeMotion.statusPulse,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final opacity = 0.55 + (t * 0.45);
        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Gentle breathing scale for the Home FAB (Design Lock v1.0).
class HomeBreathingFab extends StatefulWidget {
  const HomeBreathingFab({
    super.key,
    required this.onPressed,
    required this.child,
  });

  final VoidCallback onPressed;
  final Widget child;

  @override
  State<HomeBreathingFab> createState() => _HomeBreathingFabState();
}

class _HomeBreathingFabState extends State<HomeBreathingFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: RenewWiseHomeMotion.fabBreath,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final scale = 1 + (t * 0.04);
        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF34D399), Color(0xFF059669)],
              ),
              boxShadow: RenewWiseShadows.fab(),
            ),
            child: child,
          ),
        );
      },
      child: FloatingActionButton(
        onPressed: widget.onPressed,
        tooltip: 'Add Event',
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        child: widget.child,
      ),
    );
  }
}
