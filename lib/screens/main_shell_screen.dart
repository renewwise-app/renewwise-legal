import 'package:flutter/material.dart';



import 'package:renew_wise/screens/document_vault_screen.dart';

import 'package:renew_wise/screens/history_detail_screen.dart';

import 'package:renew_wise/screens/history_screen.dart';

import 'package:renew_wise/screens/home_screen.dart';

import 'package:renew_wise/screens/smart_lock_screen.dart';

import 'package:renew_wise/services/assistant_draft_service.dart';

import 'package:renew_wise/services/developer_service.dart';

import 'package:renew_wise/services/event_extras_service.dart';

import 'package:renew_wise/services/notification_service.dart';

import 'package:renew_wise/services/reminder_state_service.dart';

import 'package:renew_wise/services/renewal_service.dart';

import 'package:renew_wise/services/backup/backup_service.dart';

import 'package:renew_wise/services/sharing_service.dart';

import 'package:renew_wise/services/settings_service.dart';

import 'package:renew_wise/theme/design_tokens.dart';

import 'package:renew_wise/theme/renew_wise_design_system.dart';

import 'package:renew_wise/widgets/smart_lock/smart_lock_overlay.dart';



/// Root shell with bottom navigation: Home, Vault, History, Smart Lock.

class MainShellScreen extends StatefulWidget {

  const MainShellScreen({

    super.key,

    required this.renewalService,

    required this.settingsService,

    required this.notificationService,

    required this.reminderStateService,

    required this.assistantDraftService,

    required this.eventExtrasService,

    this.developerService,

    this.backupService,

    this.sharingService,

    this.initialIndex = 0,

  });



  final RenewalService renewalService;

  final SettingsService settingsService;

  final NotificationService notificationService;

  final ReminderStateService reminderStateService;

  final AssistantDraftService assistantDraftService;

  final EventExtrasService eventExtrasService;

  final DeveloperService? developerService;

  final BackupService? backupService;

  final SharingService? sharingService;

  final int initialIndex;



  @override

  State<MainShellScreen> createState() => MainShellScreenState();

}



class MainShellScreenState extends State<MainShellScreen> {

  late int _index;

  late final List<Widget> _tabs;



  @override

  void initState() {

    super.initState();

    _index = widget.initialIndex.clamp(0, 3);

    _tabs = [

      HomeScreen(

        renewalService: widget.renewalService,

        settingsService: widget.settingsService,

        notificationService: widget.notificationService,

        reminderStateService: widget.reminderStateService,

        assistantDraftService: widget.assistantDraftService,

        eventExtrasService: widget.eventExtrasService,

        developerService: widget.developerService,

        backupService: widget.backupService,

        sharingService: widget.sharingService,

        onOpenHistory: goToHistory,

        onOpenVault: goToVault,

      ),

      DocumentVaultScreen(

        eventExtrasService: widget.eventExtrasService,

        renewalService: widget.renewalService,

        settingsService: widget.settingsService,

        reminderStateService: widget.reminderStateService,

        notificationService: widget.notificationService,

      ),

      HistoryScreen(

        renewalService: widget.renewalService,

        settingsService: widget.settingsService,

        notificationService: widget.notificationService,

        reminderStateService: widget.reminderStateService,

        onOpenEntry: (entry) => HistoryDetailScreen.push(

          context,

          entry: entry,

          renewalService: widget.renewalService,

          settingsService: widget.settingsService,

          reminderStateService: widget.reminderStateService,

          notificationService: widget.notificationService,

        ),

      ),

      SmartLockScreen(

        settingsService: widget.settingsService,

      ),

    ];

  }



  void goToHistory() => setState(() => _index = 2);



  void goToHome() => setState(() => _index = 0);



  void goToVault() => setState(() => _index = 1);



  void goToSmartLock() => setState(() => _index = 3);



  @override

  Widget build(BuildContext context) {

    return SmartLockGate(

      settingsService: widget.settingsService,

      child: Scaffold(

        body: Stack(

          fit: StackFit.expand,

          children: List.generate(_tabs.length, (i) {

            final active = _index == i;

            return IgnorePointer(

              ignoring: !active,

              child: AnimatedOpacity(

                opacity: active ? 1 : 0,

                duration: RenewWiseHomeMotion.shellFade,

                curve: AppMotion.curve,

                child: _tabs[i],

              ),

            );

          }),

        ),

        bottomNavigationBar: NavigationBar(

          animationDuration: RenewWiseHomeMotion.shellFade,

          selectedIndex: _index,

          onDestinationSelected: (i) => setState(() => _index = i),

          destinations: const [

            NavigationDestination(

              icon: Icon(Icons.home_outlined),

              selectedIcon: Icon(Icons.home_rounded),

              label: 'Home',

            ),

            NavigationDestination(

              icon: Icon(Icons.folder_outlined),

              selectedIcon: Icon(Icons.folder_rounded),

              label: 'Vault',

            ),

            NavigationDestination(

              icon: Icon(Icons.history_outlined),

              selectedIcon: Icon(Icons.history_rounded),

              label: 'History',

            ),

            NavigationDestination(

              icon: Icon(Icons.shield_outlined),

              selectedIcon: Icon(Icons.shield_rounded),

              label: 'Smart Lock',

            ),

          ],

        ),

      ),

    );

  }

}


