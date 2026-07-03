import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';

/// Screen 1 — organised reminders and calendar.
class OnboardingOrganisedLifeIllustration extends StatelessWidget {
  const OnboardingOrganisedLifeIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight * 0.95);
        return SizedBox(
          width: size,
          height: size * 0.72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size * 0.88,
                height: size * 0.72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.homeCard),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      RenewWisePalette.brandSoftStart,
                      RenewWisePalette.brandSoftEnd,
                    ],
                  ),
                  boxShadow: RenewWiseShadows.homeCard(AppColors.primary),
                ),
              ),
              Positioned(
                left: size * 0.08,
                top: size * 0.1,
                child: _MiniChip(
                  icon: Icons.notifications_active_outlined,
                  label: 'Reminder',
                  width: size * 0.36,
                ),
              ),
              Positioned(
                right: size * 0.06,
                top: size * 0.14,
                child: _MiniChip(
                  icon: Icons.calendar_month_rounded,
                  label: 'Today',
                  width: size * 0.34,
                ),
              ),
              _IllustrationCard(
                width: size * 0.72,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ReminderRow(
                      icon: Icons.shield_outlined,
                      label: 'Insurance',
                      meta: 'Due Fri',
                      size: size,
                    ),
                    SizedBox(height: size * 0.03),
                    _ReminderRow(
                      icon: Icons.subscriptions_outlined,
                      label: 'Subscription',
                      meta: 'Done',
                      size: size,
                      done: true,
                    ),
                    SizedBox(height: size * 0.03),
                    _ReminderRow(
                      icon: Icons.directions_car_outlined,
                      label: 'Vehicle',
                      meta: '12 Apr',
                      size: size,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Screen 2 — offline, private, optional cloud.
class OnboardingPrivacyIllustration extends StatelessWidget {
  const OnboardingPrivacyIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight * 0.95);
        return SizedBox(
          width: size,
          height: size * 0.72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size * 0.88,
                height: size * 0.72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.homeCard),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                  ),
                  boxShadow: RenewWiseShadows.listCard(),
                ),
              ),
              CustomPaint(
                size: Size(size * 0.78, size * 0.68),
                painter: _ShieldBackdropPainter(),
              ),
              Container(
                width: size * 0.34,
                height: size * 0.52,
                decoration: BoxDecoration(
                  color: RenewWisePalette.cardSurface,
                  borderRadius: BorderRadius.circular(size * 0.05),
                  border: Border.all(color: AppColors.primary.withAlpha(30)),
                  boxShadow: RenewWiseShadows.listCard(),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline_rounded,
                        color: AppColors.primary, size: size * 0.09),
                    SizedBox(height: size * 0.03),
                    Container(
                      width: size * 0.18,
                      height: 4,
                      decoration: BoxDecoration(
                        color: RenewWisePalette.brandSoftEnd,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: size * 0.08,
                right: size * 0.12,
                child: Icon(
                  Icons.cloud_outlined,
                  size: size * 0.12,
                  color: AppColors.primary.withAlpha(40),
                ),
              ),
              Positioned(
                bottom: size * 0.1,
                left: size * 0.1,
                child: _MiniChip(
                  icon: Icons.offline_bolt_outlined,
                  label: 'Offline',
                  width: size * 0.32,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Screen 3 — planning outcomes with Smart Insights.
class OnboardingPlanningIllustration extends StatelessWidget {
  const OnboardingPlanningIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight * 0.95);
        return SizedBox(
          width: size,
          height: size * 0.72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size * 0.88,
                height: size * 0.72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.homeCard),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF3EFFE), Color(0xFFEDE9FE)],
                  ),
                  boxShadow: RenewWiseShadows.listCard(),
                ),
              ),
              _IllustrationCard(
                width: size * 0.74,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.insights_outlined,
                            color: RenewWisePalette.purple, size: size * 0.07),
                        const SizedBox(width: 8),
                        Text(
                          'Smart Insights',
                          style: RenewWiseTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: RenewWisePalette.purple,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: size * 0.035),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < 5; i++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Container(
                                height: size * (0.06 + i * 0.022),
                                decoration: BoxDecoration(
                                  color: RenewWisePalette.purple
                                      .withAlpha(50 + i * 35),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: size * 0.035),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        minHeight: 7,
                        value: 0.68,
                        backgroundColor: RenewWisePalette.purpleSoftStart,
                        color: RenewWisePalette.purple,
                      ),
                    ),
                    SizedBox(height: size * 0.02),
                    Text(
                      'On track for your goal',
                      style: RenewWiseTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: size * 0.08,
                right: size * 0.1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: RenewWisePalette.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.savings_outlined,
                          color: Colors.white, size: size * 0.06),
                      const SizedBox(width: 4),
                      Text(
                        'Peace of mind',
                        style: RenewWiseTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IllustrationCard extends StatelessWidget {
  const _IllustrationCard({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: EdgeInsets.all(width * 0.1),
      decoration: BoxDecoration(
        color: RenewWisePalette.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white.withAlpha(180)),
        boxShadow: RenewWiseShadows.listCard(),
      ),
      child: child,
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.icon,
    required this.label,
    required this.width,
  });

  final IconData icon;
  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: RenewWisePalette.cardSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: RenewWiseShadows.listCard(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: RenewWiseTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.icon,
    required this.label,
    required this.meta,
    required this.size,
    this.done = false,
  });

  final IconData icon;
  final String label;
  final String meta;
  final double size;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: size * 0.05, color: AppColors.primary),
        SizedBox(width: size * 0.025),
        Expanded(
          child: Text(
            label,
            style: RenewWiseTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          meta,
          style: RenewWiseTypography.caption.copyWith(
            color: done ? RenewWisePalette.green : RenewWisePalette.textCaption,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ShieldBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.06)
      ..lineTo(size.width * 0.9, size.height * 0.18)
      ..lineTo(size.width * 0.82, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.92,
        size.width * 0.18,
        size.height * 0.62,
      )
      ..lineTo(size.width * 0.1, size.height * 0.18)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primary.withAlpha(18)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primary.withAlpha(60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
