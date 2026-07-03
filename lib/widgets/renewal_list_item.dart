import 'package:flutter/material.dart';



import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/sharing_models.dart';
import 'package:renew_wise/models/smart_badge.dart';

import 'package:renew_wise/theme/app_theme.dart';

import 'package:renew_wise/utils/event_quality_score.dart';

import 'package:renew_wise/widgets/quality_score_sheet.dart';

import 'package:renew_wise/widgets/sharing_widgets.dart';
import 'package:renew_wise/widgets/smart_badge_chip.dart';



class RenewalListItem extends StatelessWidget {

  const RenewalListItem({

    super.key,

    required this.renewal,

    this.onTap,

    this.onLongPress,

    this.documentCount = 0,

    this.qualityResult,

    this.onQualityTap,

    this.showSmartBadges = true,
    this.shareVisibility,
  });



  final Renewal renewal;

  final VoidCallback? onTap;

  final VoidCallback? onLongPress;

  final int documentCount;

  final EventQualityResult? qualityResult;

  final VoidCallback? onQualityTap;

  final bool showSmartBadges;
  final ShareVisibility? shareVisibility;



  /// Red ≤3 days (covers overdue), Orange ≤7, Blue ≤30, Green otherwise.

  static Color daysColor(int days) {

    if (days <= 3) return const Color(0xFFDC2626);

    if (days <= 7) return const Color(0xFFEA580C);

    if (days <= 30) return const Color(0xFF2563EB);

    return AppColors.primaryGreen;

  }



  @override

  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    final days = renewal.daysRemaining;

    final color = daysColor(days);

    final isOverdue = renewal.isOverdue;

    final badges = showSmartBadges

        ? SmartBadgeResolver.forRenewal(

            renewal,

            documentCount: documentCount,

          )

        : const <SmartBadgeKind>[];



    return Material(

      color: Colors.transparent,

      child: InkWell(

        borderRadius: BorderRadius.circular(16),

        onTap: onTap,

        onLongPress: onLongPress,

        child: AnimatedContainer(

          duration: const Duration(milliseconds: 200),

          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(

            color: isOverdue

                ? AppColors.critical.withAlpha(8)

                : Theme.of(context).colorScheme.surfaceContainer,

            borderRadius: BorderRadius.circular(16),

            border: Border.all(

              color: isOverdue

                  ? AppColors.critical.withAlpha(80)

                  : Theme.of(context).colorScheme.outlineVariant.withAlpha(120),

              width: isOverdue ? 1.5 : 1,

            ),

          ),

          child: Row(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Container(

                width: 44,

                height: 44,

                decoration: BoxDecoration(

                  color: isOverdue

                      ? AppColors.critical.withAlpha(20)

                      : AppColors.primaryGreen.withAlpha(20),

                  borderRadius: BorderRadius.circular(12),

                ),

                child: Icon(

                  renewal.category.icon,

                  size: 20,

                  color:

                      isOverdue ? AppColors.critical : AppColors.primaryGreen,

                ),

              ),

              const SizedBox(width: 12),

              Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Row(

                      crossAxisAlignment: CrossAxisAlignment.center,

                      children: [

                        Expanded(

                          child: Text(

                            renewal.title,

                            style: theme.textTheme.titleSmall?.copyWith(

                              fontWeight: FontWeight.w600,

                              color: theme.colorScheme.onSurface,

                            ),

                            maxLines: 1,

                            overflow: TextOverflow.ellipsis,

                          ),

                        ),

                        if (qualityResult != null) ...[

                          const SizedBox(width: 8),

                          QualityScoreChip(

                            result: qualityResult!,

                            compact: true,

                            onTap: onQualityTap ??

                                () => showQualityScoreSheet(

                                      context,

                                      qualityResult!,

                                    ),

                          ),

                        ],

                      ],

                    ),

                    const SizedBox(height: 4),

                    Text(

                      '${renewal.categoryLabel}  •  ${renewal.formattedRenewalDate}',

                      style: theme.textTheme.bodySmall?.copyWith(

                        color: theme.colorScheme.onSurfaceVariant,

                      ),

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                    ),

                    if (shareVisibility != null) ...[
                      const SizedBox(height: 8),
                      ShareVisibilityBadge(
                        visibility: shareVisibility!,
                        compact: true,
                      ),
                    ],
                    if (badges.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SmartBadgeRow(badges: badges, compact: true),
                    ],

                    const SizedBox(height: 8),

                    Row(

                      children: [

                        _DaysChip(

                          label: renewal.daysRemainingLabel,

                          color: color,

                        ),

                        const Spacer(),

                        Text(

                          renewal.displayAmount,

                          style: theme.textTheme.titleSmall?.copyWith(

                            color: renewal.paymentRequired &&

                                    renewal.amount != null

                                ? theme.colorScheme.onSurface

                                : theme.colorScheme.onSurfaceVariant,

                            fontWeight: FontWeight.w600,

                          ),

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,

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

    );

  }

}



class _DaysChip extends StatelessWidget {

  const _DaysChip({required this.label, required this.color});



  final String label;

  final Color color;



  @override

  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),

      decoration: BoxDecoration(

        color: color.withAlpha(20),

        borderRadius: BorderRadius.circular(20),

      ),

      child: Text(

        label,

        style: Theme.of(context).textTheme.labelSmall?.copyWith(

              color: color,

              fontWeight: FontWeight.w600,

            ),

      ),

    );

  }

}

