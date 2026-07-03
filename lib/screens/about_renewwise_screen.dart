import 'package:flutter/material.dart';

import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/widgets/renew_wise_logo.dart';

class AboutRenewWiseScreen extends StatelessWidget {
  const AboutRenewWiseScreen({super.key});

  static Future<void> push(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AboutRenewWiseScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RenewWisePalette.pageBackground,
      appBar: AppBar(
        backgroundColor: RenewWisePalette.pageBackground,
        surfaceTintColor: Colors.transparent,
        title: const Text('About RenewWise'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.md,
                AppSpacing.page,
                AppSpacing.divider,
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(10),
                    borderRadius: BorderRadius.circular(AppRadius.homeCard),
                    border: Border.all(color: AppColors.primary.withAlpha(35)),
                  ),
                  child: Column(
                    children: [
                      const RenewWiseLogo(size: 72),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'RenewWise',
                        style: RenewWiseTypography.screenTitle.copyWith(
                          fontSize: 28,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Because Peace of Mind Matters.',
                        style: RenewWiseTypography.secondary.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Version 1.0.0',
                          style: RenewWiseTypography.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: RenewWisePalette.cardSurface,
                    borderRadius: BorderRadius.circular(AppRadius.homeCard),
                    boxShadow: RenewWiseShadows.listCard(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calm reminders for life\'s renewals.',
                        style: RenewWiseTypography.cardTitle,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'RenewWise helps you remember passports, insurance, subscriptions, '
                        'and everything else that quietly expires — without stress, clutter, or noise.',
                        style: RenewWiseTypography.secondary.copyWith(
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: const [
                          _PillarChip(
                            icon: Icons.lock_outline_rounded,
                            label: 'Privacy First',
                          ),
                          _PillarChip(
                            icon: Icons.offline_bolt_outlined,
                            label: 'Offline First',
                          ),
                          _PillarChip(
                            icon: Icons.notifications_none_rounded,
                            label: 'No Ads',
                          ),
                        ],
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

class _PillarChip extends StatelessWidget {
  const _PillarChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: RenewWiseTypography.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
