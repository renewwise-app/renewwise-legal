import 'package:flutter/material.dart';

import 'package:renew_wise/models/smart_lock_models.dart';
import 'package:renew_wise/services/document_protection_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/services/smart_lock_service.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/widgets/common/feature_purpose_subtitle.dart';
import 'package:renew_wise/widgets/common/renew_wise_primary_button.dart';

/// Smart Lock configuration — privacy protection for app and documents.
class SmartLockScreen extends StatefulWidget {
  const SmartLockScreen({
    super.key,
    required this.settingsService,
  });

  final SettingsService settingsService;

  @override
  State<SmartLockScreen> createState() => _SmartLockScreenState();
}

class _SmartLockScreenState extends State<SmartLockScreen> {
  bool _faceUnlockAvailable = false;
  bool _deviceAuthAvailable = false;
  bool _configuring = false;
  bool _saving = false;

  SmartLockScope _draftScope = SmartLockScope.both;
  SmartLockAuthMethod _draftAuth = SmartLockAuthMethod.fingerprint;
  SmartLockAutoLock _draftAutoLock = SmartLockAutoLock.after5Minutes;

  @override
  void initState() {
    super.initState();
    _loadCapabilities();
  }

  Future<void> _loadCapabilities() async {
    final deviceAuth = await DocumentProtectionService.isDeviceAuthAvailable();
    final face = await SmartLockService.isFaceUnlockAvailable();
    if (mounted) {
      setState(() {
        _deviceAuthAvailable = deviceAuth;
        _faceUnlockAvailable = face;
      });
    }
  }

  void _hydrateDraftFromSettings(SettingsService ss) {
    _draftScope = ss.smartLockScope;
    _draftAuth = _preferredAuthMethod(ss.smartLockAuthMethod);
    _draftAutoLock = ss.smartLockAutoLock;
  }

  SmartLockAuthMethod _preferredAuthMethod(SmartLockAuthMethod saved) {
    if (!_deviceAuthAvailable) {
      return SmartLockAuthMethod.deviceScreenLock;
    }
    if (saved == SmartLockAuthMethod.faceUnlock && !_faceUnlockAvailable) {
      return SmartLockAuthMethod.fingerprint;
    }
    return saved;
  }

  void _onEnableSwitchChanged(bool value, SettingsService ss) {
    if (value) {
      setState(() {
        _configuring = true;
        _hydrateDraftFromSettings(ss);
      });
      return;
    }
    setState(() => _configuring = false);
  }

  Future<void> _saveConfiguration(SettingsService ss) async {
    setState(() => _saving = true);
    await ss.applySmartLockConfiguration(
      scope: _draftScope,
      authMethod: _draftAuth,
      autoLock: _draftAutoLock,
    );
    if (mounted) {
      setState(() {
        _saving = false;
        _configuring = false;
      });
    }
  }

  Future<void> _disableSmartLock(SettingsService ss) async {
    await ss.setSmartLockEnabled(false);
    if (mounted) {
      setState(() => _configuring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hPad =
        MediaQuery.sizeOf(context).width > 600 ? 32.0 : AppSpacing.page;

    return Scaffold(
      backgroundColor: RenewWisePalette.pageBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: RenewWisePalette.pageBackground,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 0,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListenableBuilder(
              listenable: widget.settingsService,
              builder: (context, _) {
                final ss = widget.settingsService;
                final isEnabled = ss.smartLockEnabled;

                return ListView(
                  padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 96),
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(18),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.shield_outlined,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Smart Lock',
                            style: RenewWiseTypography.screenTitle.copyWith(
                              fontSize: 26,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const FeaturePurposeSubtitle(
                      'Protect your reminders and documents using your '
                      "phone's built-in security.",
                    ),
                    if (!_deviceAuthAvailable) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _InfoBanner(
                        icon: Icons.info_outline_rounded,
                        message:
                            'Enable a screen lock on your device to use Smart Lock.',
                      ),
                    ],
                    if (isEnabled) ...[
                      const SizedBox(height: AppSpacing.section),
                      _EnabledCard(
                        scope: ss.smartLockScope,
                        authMethod: ss.smartLockAuthMethod,
                        autoLock: ss.smartLockAutoLock,
                        onDisable: () => _disableSmartLock(ss),
                      ),
                    ] else ...[
                      const SizedBox(height: AppSpacing.section),
                      _EnableSwitchCard(
                        value: _configuring,
                        onChanged: _deviceAuthAvailable
                            ? (value) => _onEnableSwitchChanged(value, ss)
                            : null,
                      ),
                      if (_configuring) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _SectionLabel('Protection'),
                        _OptionCard(
                          children: [
                            for (var i = 0;
                                i < SmartLockScope.values.length;
                                i++)
                              _RadioTile<SmartLockScope>(
                                value: SmartLockScope.values[i],
                                groupValue: _draftScope,
                                title: SmartLockScope.values[i].label,
                                onChanged: (value) =>
                                    setState(() => _draftScope = value),
                                showDivider:
                                    i < SmartLockScope.values.length - 1,
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _SectionLabel('Authentication Method'),
                        _OptionCard(
                          children: [
                            _RadioTile<SmartLockAuthMethod>(
                              value: SmartLockAuthMethod.fingerprint,
                              groupValue: _draftAuth,
                              title: SmartLockAuthMethod.fingerprint.label,
                              onChanged: _deviceAuthAvailable
                                  ? (value) =>
                                      setState(() => _draftAuth = value)
                                  : null,
                              showDivider: true,
                            ),
                            _RadioTile<SmartLockAuthMethod>(
                              value: SmartLockAuthMethod.faceUnlock,
                              groupValue: _draftAuth,
                              title: SmartLockAuthMethod.faceUnlock.label,
                              subtitle: _faceUnlockAvailable
                                  ? null
                                  : 'Not available on this device',
                              onChanged: _deviceAuthAvailable &&
                                      _faceUnlockAvailable
                                  ? (value) =>
                                      setState(() => _draftAuth = value)
                                  : null,
                              showDivider: true,
                            ),
                            _RadioTile<SmartLockAuthMethod>(
                              value: SmartLockAuthMethod.deviceScreenLock,
                              groupValue: _draftAuth,
                              title:
                                  SmartLockAuthMethod.deviceScreenLock.label,
                              onChanged: _deviceAuthAvailable
                                  ? (value) =>
                                      setState(() => _draftAuth = value)
                                  : null,
                              showDivider: false,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _SectionLabel('Auto Lock'),
                        _OptionCard(
                          children: [
                            for (var i = 0;
                                i < SmartLockAutoLock.values.length;
                                i++)
                              _RadioTile<SmartLockAutoLock>(
                                value: SmartLockAutoLock.values[i],
                                groupValue: _draftAutoLock,
                                title: SmartLockAutoLock.values[i].label,
                                onChanged: _draftScope.locksApp
                                    ? (value) =>
                                        setState(() => _draftAutoLock = value)
                                    : null,
                                showDivider:
                                    i < SmartLockAutoLock.values.length - 1,
                              ),
                          ],
                        ),
                        if (!_draftScope.locksApp) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Auto Lock applies when the app is included in your protection setting.',
                            style: RenewWiseTypography.secondary.copyWith(
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.section),
                        RenewWisePrimaryButton(
                          label: 'Save',
                          loading: _saving,
                          onPressed: _deviceAuthAvailable && !_saving
                              ? () => _saveConfiguration(ss)
                              : null,
                        ),
                      ],
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _EnableSwitchCard extends StatelessWidget {
  const _EnableSwitchCard({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RenewWisePalette.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.homeCard),
        border: Border.all(color: AppColors.primary.withAlpha(10)),
        boxShadow: RenewWiseShadows.listCard(),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          'Enable Smart Lock',
          style: RenewWiseTypography.tileEventCount.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
      ),
    );
  }
}

class _EnabledCard extends StatelessWidget {
  const _EnabledCard({
    required this.scope,
    required this.authMethod,
    required this.autoLock,
    required this.onDisable,
  });

  final SmartLockScope scope;
  final SmartLockAuthMethod authMethod;
  final SmartLockAutoLock autoLock;
  final VoidCallback onDisable;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(14),
        borderRadius: BorderRadius.circular(AppRadius.homeCard),
        border: Border.all(color: AppColors.primary.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Smart Lock Enabled',
                  style: RenewWiseTypography.tileEventCount.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${scope.label} · ${authMethod.label}'
            '${scope.locksApp ? ' · ${autoLock.label}' : ''}',
            style: RenewWiseTypography.secondary.copyWith(height: 1.4),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onDisable,
            style: OutlinedButton.styleFrom(
              foregroundColor: RenewWisePalette.textPrimary,
              side: BorderSide(color: AppColors.primary.withAlpha(40)),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Disable Smart Lock'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: 2),
      child: Text(
        title.toUpperCase(),
        style: RenewWiseTypography.caption.copyWith(
          color: AppColors.primaryGreen,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.children});

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

class _RadioTile<T> extends StatelessWidget {
  const _RadioTile({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.onChanged,
    required this.showDivider,
    this.subtitle,
  });

  final T value;
  final T groupValue;
  final String title;
  final String? subtitle;
  final ValueChanged<T>? onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? () => onChanged!(value) : null,
            borderRadius: BorderRadius.circular(AppRadius.homeCard),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: RenewWiseTypography.tileEventCount.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: enabled
                                ? RenewWisePalette.textPrimary
                                : RenewWisePalette.textCaption,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: RenewWiseTypography.secondary.copyWith(
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (value == groupValue)
                    Icon(Icons.check_circle_rounded,
                        color: AppColors.primary, size: 22)
                  else
                    Icon(
                      Icons.circle_outlined,
                      color: enabled
                          ? RenewWisePalette.textCaption
                          : RenewWisePalette.textCaption.withAlpha(120),
                      size: 22,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: RenewWisePalette.textCaption.withAlpha(35),
          ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.gold.withAlpha(18),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.gold.withAlpha(40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: RenewWiseTypography.secondary.copyWith(
                color: RenewWisePalette.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
