import 'package:flutter/material.dart';

import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/sharing_models.dart';
import 'package:renew_wise/services/sharing_service.dart';
import 'package:renew_wise/screens/add_renewal_screen.dart';
import 'package:renew_wise/screens/event_details_screen.dart';
import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/notification_service.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/utils/event_quality_score.dart';
import 'package:renew_wise/utils/dashboard_list_utils.dart';
import 'package:renew_wise/utils/dashboard_sort.dart';
import 'package:renew_wise/utils/dashboard_time_filter.dart';
import 'package:renew_wise/widgets/event_list/event_list_empty_state.dart';
import 'package:renew_wise/widgets/renewal_list_item.dart';

enum DashboardListKind {
  critical('Critical Events', Icons.warning_amber_rounded),
  upcoming('Upcoming', Icons.schedule_rounded),
  dueThisMonth('Due This Month', Icons.payments_outlined),
  completed('Completed', Icons.check_circle_outline_rounded);

  const DashboardListKind(this.title, this.icon);
  final String title;
  final IconData icon;

  Color get accent => switch (this) {
        DashboardListKind.critical => AppColors.critical,
        DashboardListKind.upcoming => AppColors.gold,
        DashboardListKind.dueThisMonth => AppColors.teal,
        DashboardListKind.completed => AppColors.success,
      };
}

/// Unified drill-down list for all dashboard summary cards.
class DashboardEventsScreen extends StatefulWidget {
  const DashboardEventsScreen({
    super.key,
    required this.kind,
    required this.renewalService,
    required this.settingsService,
    required this.reminderStateService,
    required this.notificationService,
    required this.eventExtrasService,
    this.sharingService,
    this.initialFilter,
    this.titleOverride,
  });

  final DashboardListKind kind;
  final RenewalService renewalService;
  final SettingsService settingsService;
  final ReminderStateService reminderStateService;
  final NotificationService notificationService;
  final EventExtrasService eventExtrasService;
  final SharingService? sharingService;
  final DashboardTimeFilter? initialFilter;
  final String? titleOverride;

  static Future<void> push(
    BuildContext context, {
    required DashboardListKind kind,
    required RenewalService renewalService,
    required SettingsService settingsService,
    required ReminderStateService reminderStateService,
    required NotificationService notificationService,
    required EventExtrasService eventExtrasService,
    SharingService? sharingService,
    DashboardTimeFilter? initialFilter,
    String? titleOverride,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => DashboardEventsScreen(
          kind: kind,
          renewalService: renewalService,
          settingsService: settingsService,
          reminderStateService: reminderStateService,
          notificationService: notificationService,
          eventExtrasService: eventExtrasService,
          sharingService: sharingService,
          initialFilter: initialFilter,
          titleOverride: titleOverride,
        ),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  @override
  State<DashboardEventsScreen> createState() => _DashboardEventsScreenState();
}

class _DashboardEventsScreenState extends State<DashboardEventsScreen> {
  DashboardTimeFilter _filter = DashboardTimeFilter.all;
  DashboardSortOption _sort = DashboardSortOption.nearestFirst;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  SharingListFilter _sharingFilter = SharingListFilter.all;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter ?? widget.settingsService.dashboardTimeFilter;
    _sort = widget.settingsService.dashboardSort;
    _selectedYear = widget.settingsService.dashboardFilterYear;
    _selectedMonth = widget.settingsService.dashboardFilterMonth;
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  void _persistListPreferences() {
    widget.settingsService.setDashboardListPreferences(
      filter: _filter,
      sort: _sort,
      year: _selectedYear,
      month: _selectedMonth,
    );
  }

  void _updateFilter(DashboardTimeFilter filter) {
    setState(() => _filter = filter);
    _persistListPreferences();
  }

  void _updateSort(DashboardSortOption sort) {
    setState(() => _sort = sort);
    _persistListPreferences();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Renewal> _sourceList() {
    switch (widget.kind) {
      case DashboardListKind.critical:
        return widget.renewalService.criticalRenewals;
      case DashboardListKind.upcoming:
        return widget.renewalService.upcomingRenewals;
      case DashboardListKind.dueThisMonth:
        return widget.renewalService.paymentDueRenewals;
      case DashboardListKind.completed:
        return widget.renewalService.completedRenewals;
    }
  }

  List<Renewal> _displayList() => DashboardListUtils.apply(
        source: _sourceList(),
        filter: _filter,
        sort: _sort,
        searchQuery: _searchQuery,
        year: _selectedYear,
        month: _selectedMonth,
        eventExtras: widget.eventExtrasService,
        sharingService: widget.sharingService,
        sharingFilter: _sharingFilter,
      );

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_selectedYear, _selectedMonth, 1),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      helpText: 'Select month',
    );
    if (picked != null && mounted) {
      setState(() {
        _filter = DashboardTimeFilter.specificMonth;
        _selectedYear = picked.year;
        _selectedMonth = picked.month;
      });
      _persistListPreferences();
    }
  }

  Future<void> _pickYear() async {
    final now = DateTime.now();
    final years = List.generate(11, (i) => now.year - 5 + i);
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select year'),
        children: years
            .map(
              (y) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, y),
                child: Text('$y'),
              ),
            )
            .toList(),
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _filter = DashboardTimeFilter.specificYear;
        _selectedYear = picked;
      });
      _persistListPreferences();
    }
  }

  bool get _hasActiveFilters =>
      _filter != DashboardTimeFilter.all ||
      _sharingFilter != SharingListFilter.all;

  void _clearFilters() {
    setState(() {
      _filter = DashboardTimeFilter.all;
      _sharingFilter = SharingListFilter.all;
      _searchController.clear();
    });
    _persistListPreferences();
  }

  void _openAddReminder() {
    AddRenewalScreen.push(
      context,
      renewalService: widget.renewalService,
      defaultCurrency: widget.settingsService.defaultCurrency,
      defaultReminderTimeMinutes:
          widget.settingsService.defaultReminderTimeMinutes,
    );
  }

  ({
    String title,
    String subtitle,
    IconData icon,
    String? actionLabel,
    VoidCallback? onAction,
    IconData? actionIcon,
  }) _resolveEmptyState() {
    if (_searchQuery.trim().isNotEmpty) {
      return (
        title: 'No matching reminders found.',
        subtitle: 'Try another keyword or remove some filters.',
        icon: Icons.search_off_rounded,
        actionLabel: null,
        onAction: null,
        actionIcon: null,
      );
    }

    if (_hasActiveFilters) {
      return (
        title: 'Nothing matches your filters.',
        subtitle: 'Try adjusting your filter options.',
        icon: Icons.filter_list_off_rounded,
        actionLabel: 'Clear Filters',
        onAction: _clearFilters,
        actionIcon: Icons.filter_alt_off_outlined,
      );
    }

    return (
      title: 'No reminders found.',
      subtitle: 'Try changing your filters or create a new reminder.',
      icon: widget.kind.icon,
      actionLabel: 'Add Reminder',
      onAction: _openAddReminder,
      actionIcon: Icons.add_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final currency = widget.renewalService.primaryCurrency;

    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.renewalService,
        widget.eventExtrasService,
      ]),
      builder: (context, _) {
        final filtered = _displayList();
        final empty = _resolveEmptyState();
        final filterLabel = DashboardTimeFilterUtils.filterDescription(
          filter: _filter,
          year: _selectedYear,
          month: _selectedMonth,
        );
        final totalLabel =
            DashboardListUtils.formatTotal(filtered, currency);

        final screenTitle = widget.titleOverride ?? kind.title;

        return Scaffold(
          appBar: AppBar(title: Text(screenTitle)),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Summary header ─────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.page, 12, AppSpacing.page, 0),
                      child: _SummaryHeader(
                        title: screenTitle,
                        count: filtered.length,
                        totalLabel: totalLabel,
                        filterLabel: filterLabel,
                        accent: kind.accent,
                      ),
                    ),

                    // ── Filters ────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.page, 16, AppSpacing.page, 0),
                      child: _TimeFilterBar(
                        filter: _filter,
                        filterLabel: filterLabel,
                        onFilterSelected: _updateFilter,
                        onPickMonth: _pickMonth,
                        onPickYear: _pickYear,
                      ),
                    ),

                    // ── Sort ─────────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.page, 12, AppSpacing.page, 0),
                      child: _SortRow(
                        selected: _sort,
                        onSelected: _updateSort,
                      ),
                    ),

                    // ── Sharing filter ─────────────────────────────────────
                    if (widget.sharingService != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.page, 12, AppSpacing.page, 0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: SharingListFilter.values.map((f) {
                              final selected = _sharingFilter == f;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(f.label),
                                  selected: selected,
                                  onSelected: (_) =>
                                      setState(() => _sharingFilter = f),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                    // ── Search ───────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.page, 12, AppSpacing.page, 8),
                      child: _SearchField(
                        controller: _searchController,
                        hasText: _searchQuery.isNotEmpty,
                        onClear: () => _searchController.clear(),
                      ),
                    ),

                    // ── Event list ───────────────────────────────────────────
                    Expanded(
                      child: filtered.isEmpty
                          ? EventListEmptyState(
                              title: empty.title,
                              subtitle: empty.subtitle,
                              icon: empty.icon,
                              actionLabel: empty.actionLabel,
                              onAction: empty.onAction,
                              actionIcon: empty.actionIcon,
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(AppSpacing.page, 4, AppSpacing.page, 24),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final renewal = filtered[index];
                                final docCount = widget.eventExtrasService
                                    .documentsFor(renewal.id)
                                    .length;
                                final quality = EventQualityScore.compute(
                                  renewal,
                                  documentCount: docCount,
                                );
                                return RenewalListItem(
                                  renewal: renewal,
                                  documentCount: docCount,
                                  qualityResult: quality,
                                  shareVisibility: widget.sharingService
                                      ?.metaFor(renewal.id)
                                      .visibility,
                                  onTap: () => EventDetailsScreen.push(
                                    context,
                                    renewal: renewal,
                                    renewalService: widget.renewalService,
                                    settingsService: widget.settingsService,
                                    reminderStateService:
                                        widget.reminderStateService,
                                    notificationService:
                                        widget.notificationService,
                                    eventExtrasService:
                                        widget.eventExtrasService,
                                    sharingService: widget.sharingService,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────── Summary header ─────────────────────────────────

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.title,
    required this.count,
    required this.totalLabel,
    required this.filterLabel,
    required this.accent,
  });

  final String title;
  final int count;
  final String totalLabel;
  final String filterLabel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatPill(
                  label: '$count ${count == 1 ? 'Event' : 'Events'}',
                  accent: accent,
                ),
                const SizedBox(width: 8),
                _StatPill(
                  label: '$totalLabel Total',
                  accent: Theme.of(context).colorScheme.onSurface,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              filterLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.accent});
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withAlpha(18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withAlpha(40)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: accent == Theme.of(context).colorScheme.onSurface
                  ? Theme.of(context).colorScheme.onSurface
                  : accent,
            ),
      ),
    );
  }
}

// ─────────────────────────── Filters ──────────────────────────────────────────

class _TimeFilterBar extends StatelessWidget {
  const _TimeFilterBar({
    required this.filter,
    required this.filterLabel,
    required this.onFilterSelected,
    required this.onPickMonth,
    required this.onPickYear,
  });

  final DashboardTimeFilter filter;
  final String filterLabel;
  final ValueChanged<DashboardTimeFilter> onFilterSelected;
  final VoidCallback onPickMonth;
  final VoidCallback onPickYear;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            selected: filter == DashboardTimeFilter.all,
            onTap: () => onFilterSelected(DashboardTimeFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Today',
            selected: filter == DashboardTimeFilter.today,
            onTap: () => onFilterSelected(DashboardTimeFilter.today),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'This Week',
            selected: filter == DashboardTimeFilter.thisWeek,
            onTap: () => onFilterSelected(DashboardTimeFilter.thisWeek),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'This Month',
            selected: filter == DashboardTimeFilter.thisMonth,
            onTap: () => onFilterSelected(DashboardTimeFilter.thisMonth),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: filter == DashboardTimeFilter.specificMonth
                ? filterLabel
                : 'Month…',
            selected: filter == DashboardTimeFilter.specificMonth,
            onTap: onPickMonth,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: filter == DashboardTimeFilter.specificYear
                ? filterLabel
                : 'Year…',
            selected: filter == DashboardTimeFilter.specificYear,
            onTap: onPickYear,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withAlpha(26),
      labelStyle: TextStyle(
        fontSize: 13,
        color: selected ? AppColors.primary : Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected ? AppColors.primary : Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

// ─────────────────────────── Sort ─────────────────────────────────────────────

class _SortRow extends StatelessWidget {
  const _SortRow({required this.selected, required this.onSelected});

  final DashboardSortOption selected;
  final ValueChanged<DashboardSortOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Sort',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: DashboardSortOption.values.map((option) {
                final isSelected = option == selected;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(option.label),
                    selected: isSelected,
                    showCheckmark: false,
                    onSelected: (_) => onSelected(option),
                    selectedColor: AppColors.primary.withAlpha(26),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? AppColors.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Search ───────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hasText,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool hasText;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search events…',
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 14,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 20,
        ),
        suffixIcon: hasText
            ? IconButton(
                icon: Icon(
                  Icons.clear_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withAlpha(180),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// Empty lists use AppEmptyState.
