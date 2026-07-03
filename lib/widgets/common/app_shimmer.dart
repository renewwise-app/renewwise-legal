import 'package:flutter/material.dart';

import 'package:renew_wise/theme/design_tokens.dart';

/// Lightweight shimmer placeholder — no external packages.
class AppShimmer extends StatefulWidget {
  const AppShimmer({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlight = Theme.of(context).colorScheme.surfaceContainerHigh;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value.clamp(0.0, 1.0),
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class AppShimmerBox extends StatelessWidget {
  const AppShimmerBox({
    super.key,
    this.height = 16,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  final double height;
  final double? width;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

/// Card-shaped skeleton for list loading states.
class AppCardSkeleton extends StatelessWidget {
  const AppCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            AppShimmerBox(
              height: 48,
              width: 48,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            const SizedBox(width: AppSpacing.lg),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppShimmerBox(height: 14, width: 140),
                  SizedBox(height: 8),
                  AppShimmerBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dashboard card skeleton matching Home / Smart Insights tiles.
class AppDashboardCardSkeleton extends StatelessWidget {
  const AppDashboardCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final fill = Theme.of(context).colorScheme.surfaceContainerHighest;

    return AppShimmer(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 196),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppRadius.homeCard),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(height: 16, width: 100, color: fill),
            const SizedBox(height: AppSpacing.sm),
            Container(height: 12, width: double.infinity, color: fill),
            const SizedBox(height: 6),
            Container(height: 12, width: 130, color: fill),
            const Spacer(),
            Container(height: 12, width: 72, color: fill),
          ],
        ),
      ),
    );
  }
}
