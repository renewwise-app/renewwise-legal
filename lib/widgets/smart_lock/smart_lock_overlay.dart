import 'package:flutter/material.dart';

import 'package:renew_wise/services/document_protection_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/services/smart_lock_service.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/widgets/renew_wise_logo.dart';

/// Full-screen lock shown when Smart Lock requires authentication.
class SmartLockOverlay extends StatelessWidget {
  const SmartLockOverlay({
    super.key,
    required this.onUnlocked,
  });

  final VoidCallback onUnlocked;

  Future<void> _unlock(BuildContext context) async {
    final result = await SmartLockService.authenticate(
      reason: 'Unlock RenewWise',
    );
    if (result == DocumentAuthResult.success) {
      onUnlocked();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RenewWisePalette.pageBackground,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.page),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const RenewWiseLogo(size: 72),
                  const SizedBox(height: AppSpacing.section),
                  Icon(
                    Icons.shield_outlined,
                    size: 40,
                    color: AppColors.primary.withAlpha(200),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'RenewWise is locked',
                    style: RenewWiseTypography.screenTitle.copyWith(
                      fontSize: 24,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Authenticate to continue.',
                    style: RenewWiseTypography.secondary.copyWith(
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.section),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _unlock(context),
                      icon: const Icon(Icons.lock_open_rounded),
                      label: const Text('Unlock'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps the main shell and enforces Smart Lock on resume.
class SmartLockGate extends StatefulWidget {
  const SmartLockGate({
    super.key,
    required this.settingsService,
    required this.child,
  });

  final SettingsService settingsService;
  final Widget child;

  @override
  State<SmartLockGate> createState() => _SmartLockGateState();
}

class _SmartLockGateState extends State<SmartLockGate>
    with WidgetsBindingObserver {
  bool _locked = false;
  DateTime? _pausedAt;
  bool _skipNextResumeLock = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pausedAt ??= DateTime.now();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      if (_skipNextResumeLock) {
        _skipNextResumeLock = false;
        _pausedAt = null;
        return;
      }
      if (SmartLockService.shouldLockAfterBackground(_pausedAt)) {
        setState(() => _locked = true);
      }
      _pausedAt = null;
    }
  }

  void _unlock() => setState(() => _locked = false);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settingsService,
      builder: (context, _) {
        final showLock = _locked && SmartLockService.locksApp;
        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (showLock)
              SmartLockOverlay(onUnlocked: _unlock),
          ],
        );
      },
    );
  }
}
