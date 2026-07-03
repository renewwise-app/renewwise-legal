import 'package:flutter/material.dart';

import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/widgets/add_reminder/add_reminder_widgets.dart';

class AddReminderReviewSection {
  const AddReminderReviewSection({
    required this.title,
    required this.lines,
    required this.editStep,
    this.icon = Icons.edit_outlined,
  });

  final String title;
  final List<(String label, String value)> lines;
  final int editStep;
  final IconData icon;
}

class AddReminderReviewCards extends StatelessWidget {
  const AddReminderReviewCards({
    super.key,
    required this.sections,
    required this.onEdit,
  });

  final List<AddReminderReviewSection> sections;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Review & Save',
          style: RenewWiseTypography.screenTitle.copyWith(fontSize: 24),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Everything looks good? Tap a section to edit, then save.',
          style: RenewWiseTypography.secondary,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ...sections.map(
          (section) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ReviewGroupCard(
              section: section,
              onEdit: () => onEdit(section.editStep),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewGroupCard extends StatelessWidget {
  const _ReviewGroupCard({
    required this.section,
    required this.onEdit,
  });

  final AddReminderReviewSection section;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            RenewWisePalette.brandSoftStart,
            RenewWisePalette.brandSoftEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.homeCard),
        border: Border.all(color: AppColors.primary.withAlpha(28)),
        boxShadow: RenewWiseShadows.homeCard(AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                section.title,
                style: AddReminderStyles.heading.copyWith(fontSize: 17),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onEdit,
                icon: Icon(section.icon, size: 16),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: RenewWiseTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...section.lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.$1,
                    style: RenewWiseTypography.caption.copyWith(
                      color: RenewWisePalette.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    line.$2,
                    style: RenewWiseTypography.secondary.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
