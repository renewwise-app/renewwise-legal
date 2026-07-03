import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:renew_wise/database/database_helper.dart';
import 'package:renew_wise/repository/sqlite_renewal_repository.dart';
import 'package:renew_wise/screens/splash_screen.dart';
import 'package:renew_wise/services/assistant_draft_service.dart';
import 'package:renew_wise/services/backup/backup_service.dart';
import 'package:renew_wise/services/developer_service.dart';
import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/expense_service.dart';
import 'package:renew_wise/services/goal_planner_service.dart';
import 'package:renew_wise/services/local_notification_service.dart';
import 'package:renew_wise/services/notification_action_handler.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/renewwise_assistant_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/services/sharing_service.dart';
import 'package:renew_wise/services/smart_lock_service.dart';
import 'package:renew_wise/theme/app_theme.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsService = SettingsService();
  await settingsService.initialize();
  SmartLockService.attach(settingsService);

  final reminderStateService = ReminderStateService();
  await reminderStateService.initialize();

  final assistantDraftService = AssistantDraftService();
  await assistantDraftService.initialize();

  final eventExtrasService = EventExtrasService();
  await eventExtrasService.initialize();

  final sharingService = SharingService();
  await sharingService.initialize(settingsService);

  final notificationService = LocalNotificationService();
  await notificationService.initialize();
  notificationService.attach(
    settings: settingsService,
    reminderState: reminderStateService,
    sharingService: sharingService,
  );

  final repository = SqliteRenewalRepository(
    databaseHelper: DatabaseHelper(),
  );

  final renewalService = RenewalService(
    repository: repository,
    notificationService: notificationService,
  );
  await renewalService.loadRenewals();
  await reminderStateService.evaluateMissedReminders(renewalService.renewals);

  await initializeExpenseService();

  final goalPlannerService = GoalPlannerService();
  await goalPlannerService.initialize();

  RenewWiseAssistantService.attach(
    RenewWiseAssistantService(
      renewalService: renewalService,
      expenseService: expenseService,
      goalPlannerService: goalPlannerService,
      eventExtrasService: eventExtrasService,
      reminderStateService: reminderStateService,
      settingsService: settingsService,
    ),
  );

  final actionHandler = NotificationActionHandler(
    navigatorKey: _navigatorKey,
    renewalService: renewalService,
    settingsService: settingsService,
    reminderStateService: reminderStateService,
    notificationService: notificationService,
    eventExtrasService: eventExtrasService,
    sharingService: sharingService,
  );
  notificationService.setActionCallback(
    (payload, actionId) =>
        actionHandler.handle(rawPayload: payload, actionId: actionId),
  );

  final launchDetails = await notificationService.getLaunchDetails();
  if (launchDetails != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      actionHandler.handle(
        rawPayload: launchDetails.payload,
        actionId: launchDetails.actionId,
      );
    });
  }

  final DeveloperService? devService =
      kReleaseMode ? null : DeveloperService();
  if (devService != null) await devService.initialize();

  final backupService = BackupService(
    settingsService: settingsService,
    renewalService: renewalService,
    reminderStateService: reminderStateService,
    eventExtrasService: eventExtrasService,
    assistantDraftService: assistantDraftService,
    forceLocalDrive: Platform.environment.containsKey('FLUTTER_TEST'),
  );
  await backupService.initialize();

  runApp(
    _App(
      navigatorKey: _navigatorKey,
      settingsService: settingsService,
      renewalService: renewalService,
      reminderStateService: reminderStateService,
      assistantDraftService: assistantDraftService,
      eventExtrasService: eventExtrasService,
      notificationService: notificationService,
      developerService: devService,
      backupService: backupService,
      sharingService: sharingService,
    ),
  );
}

class _App extends StatefulWidget {
  const _App({
    required this.navigatorKey,
    required this.settingsService,
    required this.renewalService,
    required this.reminderStateService,
    required this.assistantDraftService,
    required this.eventExtrasService,
    required this.notificationService,
    this.developerService,
    required this.backupService,
    required this.sharingService,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final SettingsService settingsService;
  final RenewalService renewalService;
  final ReminderStateService reminderStateService;
  final AssistantDraftService assistantDraftService;
  final EventExtrasService eventExtrasService;
  final LocalNotificationService notificationService;
  final DeveloperService? developerService;
  final BackupService backupService;
  final SharingService sharingService;

  @override
  State<_App> createState() => _AppState();
}

class _AppState extends State<_App> with WidgetsBindingObserver {
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
    if (state == AppLifecycleState.resumed) {
      widget.reminderStateService.evaluateMissedReminders(
        widget.renewalService.renewals,
      );
      unawaited(widget.backupService.maybeRunScheduledBackup());
    }
  }

  Widget _buildMaterialApp(ThemeMode themeMode) {
    return MaterialApp(
      navigatorKey: widget.navigatorKey,
      title: 'RenewWise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: SplashScreen(
        settingsService: widget.settingsService,
        renewalService: widget.renewalService,
        reminderStateService: widget.reminderStateService,
        assistantDraftService: widget.assistantDraftService,
        eventExtrasService: widget.eventExtrasService,
        notificationService: widget.notificationService,
        developerService: widget.developerService,
        backupService: widget.backupService,
        sharingService: widget.sharingService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode || widget.developerService == null) {
      return _buildMaterialApp(ThemeMode.system);
    }
    return ListenableBuilder(
      listenable: widget.developerService!,
      builder: (_, _) =>
          _buildMaterialApp(widget.developerService!.themeMode),
    );
  }
}
