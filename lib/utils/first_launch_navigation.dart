import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:renew_wise/screens/main_shell_screen.dart';
import 'package:renew_wise/screens/onboarding_screen.dart';
import 'package:renew_wise/screens/welcome_login_screen.dart';
import 'package:renew_wise/screens/welcome_name_screen.dart';
import 'package:renew_wise/services/assistant_draft_service.dart';
import 'package:renew_wise/services/backup/backup_service.dart';
import 'package:renew_wise/services/developer_service.dart';
import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/notification_service.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/services/sharing_service.dart';

/// Shared dependencies for post-splash first-launch routing.
class FirstLaunchShellArgs {
  const FirstLaunchShellArgs({
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

  Widget buildMainShell() {
    return MainShellScreen(
      renewalService: renewalService,
      settingsService: settingsService,
      notificationService: notificationService,
      reminderStateService: reminderStateService,
      assistantDraftService: assistantDraftService,
      eventExtrasService: eventExtrasService,
      developerService: kReleaseMode ? null : developerService,
      backupService: backupService,
      sharingService: sharingService,
    );
  }

  Widget buildOnboarding() {
    return OnboardingScreen(
      settingsService: settingsService,
      renewalService: renewalService,
      notificationService: notificationService,
      reminderStateService: reminderStateService,
      assistantDraftService: assistantDraftService,
      eventExtrasService: eventExtrasService,
      developerService: kReleaseMode ? null : developerService,
      shellArgs: this,
    );
  }

  Widget buildWelcomeLogin() {
    return WelcomeLoginScreen(
      settingsService: settingsService,
      shellArgs: this,
    );
  }

  Widget buildWelcomeName() {
    return WelcomeNameScreen(
      settingsService: settingsService,
      shellArgs: this,
    );
  }
}

/// Determines the first screen after splash based on persisted first-launch state.
abstract final class FirstLaunchNavigation {
  static Widget resolveInitialScreen({
    required SettingsService settingsService,
    required FirstLaunchShellArgs args,
  }) {
    if (!settingsService.hasSeenOnboarding) {
      return args.buildOnboarding();
    }
    if (!settingsService.hasCompletedWelcomeLogin) {
      return args.buildWelcomeLogin();
    }
    if (settingsService.userName.trim().isEmpty) {
      return args.buildWelcomeName();
    }
    return args.buildMainShell();
  }

  static PageRouteBuilder<void> fadeRoute(Widget page) {
    return PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 450),
    );
  }

  static void replaceWith(BuildContext context, Widget page) {
    Navigator.of(context).pushReplacement(fadeRoute(page));
  }
}
