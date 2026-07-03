import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:renew_wise/theme/renew_wise_design_system.dart';

enum HomeWatermarkKind {
  wave,
  bars,
  calendar,
  search,
}

/// Animated watermark decorations clipped inside Home dashboard tiles.
class HomeCardWatermark extends StatefulWidget {
  const HomeCardWatermark({
    super.key,
    required this.kind,
    required this.accent,
  });

  final HomeWatermarkKind kind;
  final Color accent;

  @override
  State<HomeCardWatermark> createState() => _HomeCardWatermarkState();
}

class _HomeCardWatermarkState extends State<HomeCardWatermark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _durationForKind(widget.kind),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant HomeCardWatermark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      _controller
        ..duration = _durationForKind(widget.kind)
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Duration _durationForKind(HomeWatermarkKind kind) => switch (kind) {
        HomeWatermarkKind.wave => RenewWiseHomeMotion.wave,
        HomeWatermarkKind.bars => RenewWiseHomeMotion.bars,
        HomeWatermarkKind.calendar => RenewWiseHomeMotion.calendar,
        HomeWatermarkKind.search => RenewWiseHomeMotion.searchDrift,
      };

  double get _phase => _controller.value * math.pi * 2;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: RepaintBoundary(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return switch (widget.kind) {
                HomeWatermarkKind.wave => _WaveWatermark(
                    phase: _phase,
                    accent: widget.accent,
                  ),
                HomeWatermarkKind.bars => _BarsWatermark(
                    phase: _phase,
                    accent: widget.accent,
                  ),
                HomeWatermarkKind.calendar => _CalendarWatermark(
                    phase: _phase,
                    accent: widget.accent,
                  ),
                HomeWatermarkKind.search => _SearchWatermark(
                    phase: _phase,
                    accent: widget.accent,
                  ),
              };
            },
          ),
        ),
      ),
    );
  }
}

/// Keeps decorative art in the tile corner with room for motion.
class _TileWatermarkAnchor extends StatelessWidget {
  const _TileWatermarkAnchor({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 14, bottom: 14),
        child: child,
      ),
    );
  }
}

class _WaveWatermark extends StatelessWidget {
  const _WaveWatermark({required this.phase, required this.accent});

  final double phase;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final dx = math.sin(phase) * 12;
    return _TileWatermarkAnchor(
      child: Transform.translate(
        offset: Offset(dx, 0),
        child: Icon(
          Icons.waves_rounded,
          size: 76,
          color: accent.withAlpha(22),
        ),
      ),
    );
  }
}

class _BarsWatermark extends StatelessWidget {
  const _BarsWatermark({required this.phase, required this.accent});

  final double phase;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    const heights = [28.0, 42.0, 34.0, 48.0];
    const delays = [0.0, 0.18, 0.36, 0.54];

    return _TileWatermarkAnchor(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(4, (i) {
          final barPhase = phase + (delays[i] * math.pi * 2);
          final dy = math.sin(barPhase) * 3;
          return Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 5),
            child: Transform.translate(
              offset: Offset(0, dy),
              child: Container(
                width: 8,
                height: heights[i],
                decoration: BoxDecoration(
                  color: accent.withAlpha(24),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _CalendarWatermark extends StatelessWidget {
  const _CalendarWatermark({required this.phase, required this.accent});

  final double phase;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final dy = math.sin(phase) * 3;
    return _TileWatermarkAnchor(
      child: Transform.translate(
        offset: Offset(0, dy),
        child: Icon(
          Icons.calendar_month_outlined,
          size: 76,
          color: accent.withAlpha(22),
        ),
      ),
    );
  }
}

class _SearchWatermark extends StatelessWidget {
  const _SearchWatermark({required this.phase, required this.accent});

  final double phase;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final dx = math.sin(phase) * 2.5;
    final dy = math.cos(phase) * 2.5;
    return _TileWatermarkAnchor(
      child: Transform.translate(
        offset: Offset(dx, dy),
        child: Icon(
          Icons.manage_search_rounded,
          size: 76,
          color: accent.withAlpha(22),
        ),
      ),
    );
  }
}
