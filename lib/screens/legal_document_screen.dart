import 'package:flutter/material.dart';

import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';

enum LegalDocumentKind {
  privacyPolicy('Privacy Policy'),
  terms('Terms & Conditions'),
  disclaimer('Disclaimer');

  const LegalDocumentKind(this.title);
  final String title;

  List<String> get paragraphs => switch (this) {
        LegalDocumentKind.privacyPolicy => const [
            'RenewWise is built around a simple promise: your reminders belong to you.',
            'We store your reminders and attached documents on your device. RenewWise does not sell your personal information or use your data for advertising.',
            'Optional features such as cloud backup will always require your explicit choice before any data leaves your device.',
            'If you have questions about how your information is handled, contact us through Send Feedback when it becomes available.',
          ],
        LegalDocumentKind.terms => const [
            'By using RenewWise, you agree to use the app responsibly for managing your own reminders and documents.',
            'RenewWise is provided to help you stay organised. It does not replace professional, legal, financial, or medical advice.',
            'You remain responsible for the accuracy of the reminders and documents you add.',
            'We may update these terms as RenewWise evolves. Continued use of the app means you accept the updated terms.',
          ],
        LegalDocumentKind.disclaimer => const [
            'RenewWise is designed to help you remember important renewals and deadlines.',
            'Reminder timing, notifications, and stored information depend on your device settings and how you use the app.',
            'RenewWise is not liable for missed deadlines, incomplete records, or losses arising from reliance on reminders alone.',
            'Always verify critical dates and documents independently when the stakes are high.',
          ],
      };
}

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.kind});

  final LegalDocumentKind kind;

  static Future<void> push(BuildContext context, LegalDocumentKind kind) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalDocumentScreen(kind: kind),
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
        title: Text(kind.title),
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
                for (final paragraph in kind.paragraphs) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: RenewWisePalette.cardSurface,
                      borderRadius: BorderRadius.circular(AppRadius.homeCard),
                      boxShadow: RenewWiseShadows.listCard(),
                    ),
                    child: Text(
                      paragraph,
                      style: RenewWiseTypography.secondary.copyWith(
                        color: RenewWisePalette.textPrimary,
                        height: 1.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
