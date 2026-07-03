import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/widgets/renew_wise_logo.dart';

/// Shield → checkmark → logo success sequence after save.
class AssistantSuccessSequence extends StatefulWidget {
  const AssistantSuccessSequence({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<AssistantSuccessSequence> createState() =>
      _AssistantSuccessSequenceState();
}

class _AssistantSuccessSequenceState extends State<AssistantSuccessSequence>
    with TickerProviderStateMixin {
  late final AnimationController _shieldCtrl;
  late final AnimationController _checkCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _shieldScale;
  late final Animation<double> _checkProgress;
  late final Animation<double> _contentOpacity;

  @override
  void initState() {
    super.initState();
    HapticFeedback.lightImpact();

    _shieldCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shieldScale = CurvedAnimation(
      parent: _shieldCtrl,
      curve: Curves.easeOutBack,
    );
    _checkProgress = CurvedAnimation(
      parent: _checkCtrl,
      curve: Curves.easeInOutCubic,
    );
    _contentOpacity = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    unawaited(_runSequence());
  }

  Future<void> _runSequence() async {
    await _shieldCtrl.forward();
    await _checkCtrl.forward();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await _fadeCtrl.forward();
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted) widget.onComplete();
  }

  @override
  void dispose() {
    _shieldCtrl.dispose();
    _checkCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _shieldScale,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(24),
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 64,
                          color: AppColors.primary.withAlpha(180),
                        ),
                        AnimatedBuilder(
                          animation: _checkProgress,
                          builder: (_, _) => CustomPaint(
                            size: const Size(48, 48),
                            painter: _CheckmarkPainter(
                              progress: _checkProgress.value,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FadeTransition(
                  opacity: _contentOpacity,
                  child: Column(
                    children: [
                      const RenewWiseLogo(size: 56),
                      const SizedBox(height: 24),
                      Text(
                        "You're all set.",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "We'll remember it…\nso you don't have to.",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  _CheckmarkPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.52)
      ..lineTo(size.width * 0.42, size.height * 0.75)
      ..lineTo(size.width * 0.88, size.height * 0.28);

    final metrics = path.computeMetrics().first;
    final extract = metrics.extractPath(0, metrics.length * progress);
    canvas.drawPath(extract, paint);
  }

  @override
  bool shouldRepaint(_CheckmarkPainter old) => old.progress != progress;
}
