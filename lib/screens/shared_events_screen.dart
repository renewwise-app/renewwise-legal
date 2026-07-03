import 'package:flutter/material.dart';

import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/sharing_models.dart';
import 'package:renew_wise/screens/event_details_screen.dart';
import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/notification_service.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/services/sharing_service.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/utils/dashboard_list_utils.dart';
import 'package:renew_wise/utils/dashboard_sort.dart';
import 'package:renew_wise/widgets/renewal_list_item.dart';
import 'package:renew_wise/widgets/common/app_empty_state.dart';
class SharedEventsScreen extends StatefulWidget {
  const SharedEventsScreen({
    super.key,
    required this.sharingService,
    required this.renewalService,
    required this.settingsService,
    required this.reminderStateService,
    required this.notificationService,
    required this.eventExtrasService,
  });

  final SharingService sharingService;
  final RenewalService renewalService;
  final SettingsService settingsService;
  final ReminderStateService reminderStateService;
  final NotificationService notificationService;
  final EventExtrasService eventExtrasService;

  static Future<void> push(
    BuildContext context, {
    required SharingService sharingService,
    required RenewalService renewalService,
    required SettingsService settingsService,
    required ReminderStateService reminderStateService,
    required NotificationService notificationService,
    required EventExtrasService eventExtrasService,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SharedEventsScreen(
          sharingService: sharingService,
          renewalService: renewalService,
          settingsService: settingsService,
          reminderStateService: reminderStateService,
          notificationService: notificationService,
          eventExtrasService: eventExtrasService,
        ),
      ),
    );
  }

  @override
  State<SharedEventsScreen> createState() => _SharedEventsScreenState();
}

class _SharedEventsScreenState extends State<SharedEventsScreen> {
  SharingListFilter _filter = SharingListFilter.shared;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Renewal> _displayList() {
    var list = widget.sharingService.filterRenewals(
      widget.renewalService.renewals,
      _filter,
    );
    list = list
        .where(
          (r) => DashboardListUtils.matchesSearch(
            r,
            _searchQuery,
            eventExtras: widget.eventExtrasService,
            sharingService: widget.sharingService,
          ),
        )
        .toList();
    DashboardSortUtils.sort(list, DashboardSortOption.nearestFirst);
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shared Events')),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          widget.sharingService,
          widget.renewalService,
        ]),
        builder: (context, _) {
          final list = _displayList();
          final pending = widget.sharingService.pendingActionsCount(
            widget.renewalService.renewals,
          );

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.page, 12, AppSpacing.page, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (pending > 0)
                        Card(
                          color: AppColors.gold.withValues(alpha: 0.1),
                          child: ListTile(
                            leading: Icon(Icons.pending_actions, color: AppColors.gold),
                            title: Text('$pending pending action${pending == 1 ? '' : 's'}'),
                            subtitle: const Text('Shared events needing your attention'),
                          ),
                        ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: SharingListFilter.values.map((f) {
                            final selected = _filter == f;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(f.label),
                                selected: selected,
                                onSelected: (_) => setState(() => _filter = f),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search shared events…',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              if (list.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    icon: Icons.groups_outlined,
                    title: 'Nothing shared yet',
                    subtitle:
                        'Share important reminders with people you trust.',
                  ),
                )
              else
                SliverList.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final r = list[i];
                    final meta = widget.sharingService.metaFor(r.id);
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, 10),
                      child: RenewalListItem(
                        renewal: r,
                        documentCount: widget.eventExtrasService
                            .documentsFor(r.id)
                            .length,
                        shareVisibility: meta.visibility,
                        onTap: () => EventDetailsScreen.push(
                          context,
                          renewal: r,
                          renewalService: widget.renewalService,
                          settingsService: widget.settingsService,
                          reminderStateService: widget.reminderStateService,
                          notificationService: widget.notificationService,
                          eventExtrasService: widget.eventExtrasService,
                          sharingService: widget.sharingService,
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
