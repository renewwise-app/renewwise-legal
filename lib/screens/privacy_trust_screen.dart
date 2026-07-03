import 'package:flutter/material.dart';

import 'package:renew_wise/screens/about_renewwise_screen.dart';
import 'package:renew_wise/screens/document_vault_screen.dart';
import 'package:renew_wise/screens/legal_document_screen.dart';
import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/notification_service.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/widgets/common/app_dialogs.dart';
import 'package:renew_wise/widgets/common/app_feedback.dart';

class PrivacyTrustScreen extends StatelessWidget {
  const PrivacyTrustScreen({
    super.key,
    required this.settingsService,
    required this.renewalService,
    required this.eventExtrasService,
    required this.reminderStateService,
    required this.notificationService,
  });

  final SettingsService settingsService;
  final RenewalService renewalService;
  final EventExtrasService eventExtrasService;
  final ReminderStateService reminderStateService;
  final NotificationService notificationService;

  static Future<void> push(
    BuildContext context, {
    required SettingsService settingsService,
    required RenewalService renewalService,
    required EventExtrasService eventExtrasService,
    required ReminderStateService reminderStateService,
    required NotificationService notificationService,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PrivacyTrustScreen(
          settingsService: settingsService,
          renewalService: renewalService,
          eventExtrasService: eventExtrasService,
          reminderStateService: reminderStateService,
          notificationService: notificationService,
        ),
      ),
    );
  }

  Future<void> _deleteAllData(BuildContext context) async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: 'Delete all data?',
      message:
          'This permanently removes all events, documents, and scheduled reminders. '
          'This cannot be undone.',
      confirmLabel: 'Delete All Data',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await renewalService.clearAll();
    await eventExtrasService.clearAll();
    if (context.mounted) {
      AppFeedback.show(
        context,
        message: 'All data deleted. You can start fresh anytime.',
        haptic: true,
      );
    }
  }

  void _openDocuments(BuildContext context) {
    DocumentVaultScreen.push(
      context,
      eventExtrasService: eventExtrasService,
      renewalService: renewalService,
      settingsService: settingsService,
      reminderStateService: reminderStateService,
      notificationService: notificationService,
    );
  }

  void _openLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'RenewWise',
      applicationVersion: '1.0.0',
      applicationLegalese: '© RenewWise',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RenewWisePalette.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Privacy & Trust'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _PrivacyAmbientBackground(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    0,
                    AppSpacing.page,
                    AppSpacing.divider,
                  ),
                  children: [
                    const _PrivacyHeroCard(),
                    const SizedBox(height: AppSpacing.lg),
                    const _CompactInfoCard(
                      icon: Icons.smartphone_outlined,
                      title: 'Offline First',
                      description: 'Your reminders stay on your device.',
                      badge: 'Enabled',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const _CompactInfoCard(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      description: 'Used only for reminder alerts.',
                      badge: 'Required',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const _CompactInfoCard(
                      icon: Icons.description_outlined,
                      title: 'Documents',
                      description: 'Protected using your phone lock.',
                      badge: 'Available',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const _CompactInfoCard(
                      icon: Icons.cloud_outlined,
                      title: 'Cloud Backup',
                      description: 'Optional encrypted backup.',
                      badge: 'Coming Soon',
                      mutedBadge: true,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const _CompactInfoCard(
                      icon: Icons.language_outlined,
                      title: 'Internet Usage',
                      description: 'Only used for optional online features.',
                      badge: 'Minimal',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const _CompactInfoCard(
                      icon: Icons.shield_outlined,
                      title: 'Your Privacy',
                      description: 'Your personal information is never sold.',
                      badge: 'Protected',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _SectionHeading(title: 'Legal'),
                    _SettingsCard(
                      children: [
                        _SettingsRow(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          onTap: () => LegalDocumentScreen.push(
                            context,
                            LegalDocumentKind.privacyPolicy,
                          ),
                        ),
                        _SettingsRow(
                          icon: Icons.article_outlined,
                          title: 'Terms & Conditions',
                          onTap: () => LegalDocumentScreen.push(
                            context,
                            LegalDocumentKind.terms,
                          ),
                        ),
                        _SettingsRow(
                          icon: Icons.info_outline_rounded,
                          title: 'Disclaimer',
                          onTap: () => LegalDocumentScreen.push(
                            context,
                            LegalDocumentKind.disclaimer,
                          ),
                        ),
                        _SettingsRow(
                          icon: Icons.code_outlined,
                          title: 'Open Source Licenses',
                          onTap: () => _openLicenses(context),
                        ),
                        _SettingsRow(
                          icon: Icons.apps_outlined,
                          title: 'About RenewWise',
                          onTap: () => AboutRenewWiseScreen.push(context),
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _SectionHeading(title: 'Your Data'),
                    _SettingsCard(
                      children: [
                        _SettingsRow(
                          icon: Icons.delete_outline_rounded,
                          title: 'Delete All Data',
                          iconColor: AppColors.critical,
                          titleColor: AppColors.critical,
                          onTap: () => _deleteAllData(context),
                        ),
                        _SettingsRow(
                          icon: Icons.folder_outlined,
                          title: 'Manage Documents',
                          onTap: () => _openDocuments(context),
                        ),
                        _SettingsRow(
                          icon: Icons.upload_outlined,
                          title: 'Export Data',
                          trailing: const _StatusBadge(
                            label: 'Coming Soon',
                            muted: true,
                          ),
                          showDivider: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyAmbientBackground extends StatelessWidget {
  const _PrivacyAmbientBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            RenewWisePalette.brandSoftStart.withAlpha(220),
            RenewWisePalette.pageBackground,
            RenewWisePalette.pageBackground,
          ],
          stops: const [0, 0.38, 1],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -24,
            right: -32,
            child: Icon(
              Icons.waves_rounded,
              size: 160,
              color: AppColors.primary.withAlpha(12),
            ),
          ),
          Positioned(
            top: 120,
            left: -40,
            child: Icon(
              Icons.spa_outlined,
              size: 120,
              color: AppColors.primary.withAlpha(10),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyHeroCard extends StatelessWidget {
  const _PrivacyHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: 24,
            child: Icon(
              Icons.waves_rounded,
              size: 110,
              color: AppColors.primary.withAlpha(16),
            ),
          ),
          Positioned(
            top: -8,
            left: -12,
            child: Icon(
              Icons.spa_outlined,
              size: 72,
              color: AppColors.primary.withAlpha(12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withAlpha(40),
                        AppColors.primary.withAlpha(16),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Your Privacy Matters',
                  style: RenewWiseTypography.cardTitle.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your reminders stay on your device by default.',
                  style: RenewWiseTypography.secondary.copyWith(
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _HeroChip(
                      icon: Icons.lock_outline_rounded,
                      label: 'Offline First',
                    ),
                    _HeroChip(
                      icon: Icons.cloud_outlined,
                      label: 'Optional Cloud Backup',
                    ),
                    _HeroChip(
                      icon: Icons.verified_user_outlined,
                      label: 'No Data Selling',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: RenewWisePalette.cardSurface.withAlpha(210),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.primary.withAlpha(24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: RenewWiseTypography.caption.copyWith(
              color: RenewWisePalette.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactInfoCard extends StatelessWidget {
  const _CompactInfoCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
    this.mutedBadge = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final String badge;
  final bool mutedBadge;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: RenewWisePalette.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.primary.withAlpha(12)),
        boxShadow: RenewWiseShadows.listCard(),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withAlpha(28),
                  AppColors.primary.withAlpha(10),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: RenewWiseTypography.cardTitle.copyWith(fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: RenewWiseTypography.caption.copyWith(
                    color: RenewWisePalette.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusBadge(label: badge, muted: mutedBadge),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final bg = muted
        ? Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(18)
        : AppColors.primary.withAlpha(18);
    final fg = muted
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: muted
              ? Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(30)
              : AppColors.primary.withAlpha(40),
        ),
      ),
      child: Text(
        label,
        style: RenewWiseTypography.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: 2),
      child: Text(
        title.toUpperCase(),
        style: RenewWiseTypography.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RenewWisePalette.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.homeCard),
        border: Border.all(color: AppColors.primary.withAlpha(10)),
        boxShadow: RenewWiseShadows.listCard(),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  _SettingsRow({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
    Color? iconColor,
    this.titleColor,
    this.showDivider = true,
  }) : iconColor = iconColor ?? AppColors.primaryGreen;

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color iconColor;
  final Color? titleColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.homeCard),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? RenewWisePalette.textPrimary,
                      ),
                    ),
                  ),
                  trailing ??
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 66,
            endIndent: 16,
            color: RenewWisePalette.textCaption.withAlpha(35),
          ),
      ],
    );
  }
}
