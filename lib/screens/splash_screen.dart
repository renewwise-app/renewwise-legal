import 'package:flutter/material.dart';

import 'package:renew_wise/services/assistant_draft_service.dart';
import 'package:renew_wise/services/backup/backup_service.dart';
import 'package:renew_wise/services/developer_service.dart';
import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/notification_service.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/services/sharing_service.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/utils/first_launch_navigation.dart';
import 'package:renew_wise/widgets/renew_wise_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.settingsService,
    required this.renewalService,
    required this.notificationService,
    required this.reminderStateService,
    required this.assistantDraftService,
    required this.eventExtrasService,
    this.developerService,
    this.backupService,
    this.sharingService,
  });

  final SettingsService settingsService;
  final RenewalService renewalService;
  final NotificationService notificationService;
  final ReminderStateService reminderStateService;
  final AssistantDraftService assistantDraftService;
  final EventExtrasService eventExtrasService;
  final DeveloperService? developerService;
  final BackupService? backupService;
  final SharingService? sharingService;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoScale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _opacity = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.15, 1, curve: Curves.easeOut),
    );

    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2200), _navigate);
  }

  FirstLaunchShellArgs get _shellArgs => FirstLaunchShellArgs(
        settingsService: widget.settingsService,
        renewalService: widget.renewalService,
        notificationService: widget.notificationService,
        reminderStateService: widget.reminderStateService,
        assistantDraftService: widget.assistantDraftService,
        eventExtrasService: widget.eventExtrasService,
        developerService: widget.developerService,
        backupService: widget.backupService,
        sharingService: widget.sharingService,
      );

  void _navigate() {
    if (!mounted) return;
    final next = FirstLaunchNavigation.resolveInitialScreen(
      settingsService: widget.settingsService,
      args: _shellArgs,
    );
    FirstLaunchNavigation.replaceWith(context, next);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RenewWisePalette.pageBackground,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              RenewWisePalette.brandSoftStart.withAlpha(240),
              RenewWisePalette.pageBackground,
              RenewWisePalette.pageBackground,
            ],
            stops: const [0, 0.45, 1],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _opacity,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _logoScale,
                    child: const RenewWiseLogo(size: 104),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'RenewWise',
                    style: RenewWiseTypography.screenTitle.copyWith(
                      fontSize: 34,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Because Peace of Mind Matters.',
                    style: RenewWiseTypography.secondary.copyWith(
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
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
