import 'package:flutter/material.dart';

import 'package:renew_wise/models/history_entry.dart';
import 'package:renew_wise/models/renewal_category.dart';
import 'package:renew_wise/models/renewal_currency.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/utils/history_completed_filter.dart';
import 'package:renew_wise/utils/history_completed_sort.dart';
import 'package:renew_wise/utils/history_events_scope.dart';
import 'package:renew_wise/widgets/event_list/event_list_empty_state.dart';
import 'package:renew_wise/widgets/event_list/event_list_header.dart';
import 'package:renew_wise/widgets/history/history_completed_list_card.dart';

/// Completed reminders list — mirrors [HomeEventsListScreen] layout.
class HistoryCompletedListScreen extends StatefulWidget {
  const HistoryCompletedListScreen({
    super.key,
    required this.title,
    required this.scope,
    required this.reminderStateService,
    required this.onOpenEntry,
    this.fromDate,
    this.toDate,
  });

  final String title;
  final HistoryEventsScope scope;
  final ReminderStateService reminderStateService;
  final void Function(HistoryEntry entry) onOpenEntry;
  final DateTime? fromDate;
  final DateTime? toDate;

  static Future<void> push(
    BuildContext context, {
    required String title,
    required HistoryEventsScope scope,
    required ReminderStateService reminderStateService,
    required void Function(HistoryEntry entry) onOpenEntry,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => HistoryCompletedListScreen(
          title: title,
          scope: scope,
          reminderStateService: reminderStateService,
          onOpenEntry: onOpenEntry,
          fromDate: fromDate,
          toDate: toDate,
        ),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: RenewWiseHomeMotion.shellFade,
      ),
    );
  }

  @override
  State<HistoryCompletedListScreen> createState() =>
      _HistoryCompletedListScreenState();
}

class _HistoryCompletedListScreenState extends State<HistoryCompletedListScreen> {
  final _searchCtrl = TextEditingController();
  HistoryCompletedSortOption _sort = HistoryCompletedSortOption.completionDate;
  HistoryCompletedFilter _paymentFilter = HistoryCompletedFilter.all;
  RenewalCategory? _categoryFilter;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _search = _searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _pageTitle => switch (widget.scope) {
        HistoryEventsScope.completedToday => 'Completed Today',
        HistoryEventsScope.completedThisWeek => 'Completed This Week',
        HistoryEventsScope.completedThisMonth => 'Completed This Month',
        HistoryEventsScope.customPeriod => 'Choose Period',
      };

  bool get _hasActiveFilters =>
      _categoryFilter != null ||
      _paymentFilter != HistoryCompletedFilter.all;

  void _clearFilters() {
    setState(() {
      _categoryFilter = null;
      _paymentFilter = HistoryCompletedFilter.all;
      _searchCtrl.clear();
    });
  }

  ({
    String title,
    String subtitle,
    IconData icon,
    String? actionLabel,
    VoidCallback? onAction,
    IconData? actionIcon,
  }) _resolveEmptyState({
    required List<HistoryEntry> scoped,
    required List<HistoryEntry> entries,
  }) {
    if (entries.isNotEmpty) {
      return (
        title: '',
        subtitle: '',
        icon: Icons.event_available_rounded,
        actionLabel: null,
        onAction: null,
        actionIcon: null,
      );
    }

    if (_search.trim().isNotEmpty) {
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

    if (scoped.isEmpty) {
      final base = _emptyState;
      return (
        title: base.title,
        subtitle: base.subtitle,
        icon: Icons.event_available_rounded,
        actionLabel: null,
        onAction: null,
        actionIcon: null,
      );
    }

    return (
      title: 'No matching reminders found.',
      subtitle: 'Try another keyword or remove some filters.',
      icon: Icons.search_off_rounded,
      actionLabel: null,
      onAction: null,
      actionIcon: null,
    );
  }

  ({String title, String subtitle}) get _emptyState => switch (widget.scope) {
        HistoryEventsScope.completedToday => (
            title: 'Nothing completed today.',
            subtitle: 'Completed reminders will appear here.',
          ),
        HistoryEventsScope.completedThisWeek => (
            title: 'No reminders completed this week.',
            subtitle: 'Take it one step at a time.',
          ),
        HistoryEventsScope.completedThisMonth => (
            title: 'No reminders completed this month.',
            subtitle: 'Your archive is ready when you need it.',
          ),
        HistoryEventsScope.customPeriod => (
            title: 'No completed reminders found.',
            subtitle: 'Try a different date range.',
          ),
      };

  List<HistoryEntry> _scopedEntries() {
    return HistoryEventsScopeUtils.scopedEntries(
      widget.reminderStateService.history,
      scope: widget.scope,
      fromDate: widget.fromDate,
      toDate: widget.toDate,
    );
  }

  List<HistoryEntry> _displayList() {
    final q = _search.trim().toLowerCase();
    final list = _scopedEntries().where((entry) {
      if (q.isNotEmpty && !entry.title.toLowerCase().contains(q)) {
        return false;
      }
      if (!HistoryCompletedFilterUtils.matchesCategory(
        entry,
        _categoryFilter,
      )) {
        return false;
      }
      return HistoryCompletedFilterUtils.matchesPaymentFilter(
        entry,
        _paymentFilter,
      );
    }).toList();

    HistoryCompletedSortUtils.sort(list, _sort);
    return list;
  }

  double _completedTotal(List<HistoryEntry> entries) {
    var total = 0.0;
    for (final entry in entries) {
      if (entry.amount != null) total += entry.amount!;
    }
    return total;
  }

  String? _amountLabel(List<HistoryEntry> entries) {
    final total = _completedTotal(entries);
    if (total <= 0) return null;

    final currencyFreq = <RenewalCurrency, int>{};
    for (final entry in entries) {
      if (entry.amount != null && entry.currencyCode != null) {
        final currency = RenewalCurrency.values.byName(entry.currencyCode!);
        currencyFreq[currency] = (currencyFreq[currency] ?? 0) + 1;
      }
    }
    final primary = currencyFreq.isEmpty
        ? RenewalCurrency.inr
        : currencyFreq.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    return primary.formatAmount(total);
  }

  Future<void> _showSortSheet() async {
    final picked = await showModalBottomSheet<HistoryCompletedSortOption>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text('Sort by', style: RenewWiseTypography.cardTitle),
              ),
              ...HistoryCompletedSortOption.values.map(
                (option) => ListTile(
                  title: Text(
                    option.label,
                    style: RenewWiseTypography.tileEventCount.copyWith(
                      fontWeight:
                          _sort == option ? FontWeight.w600 : FontWeight.w500,
                      color: _sort == option
                          ? AppColors.primary
                          : const Color(0xFF334155),
                    ),
                  ),
                  trailing: _sort == option
                      ? Icon(
                          Icons.check_rounded,
                          color: AppColors.primary,
                        )
                      : null,
                  onTap: () => Navigator.pop(ctx, option),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (picked != null && mounted) setState(() => _sort = picked);
  }

  Future<void> _showFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Filter by', style: RenewWiseTypography.cardTitle),
                const SizedBox(height: 16),
                Text(
                  'Category',
                  style: RenewWiseTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: RenewWisePalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _categoryFilter == null,
                      onSelected: (_) {
                        setState(() => _categoryFilter = null);
                        Navigator.pop(ctx);
                      },
                    ),
                    ...RenewalCategory.values.map(
                      (category) => FilterChip(
                        label: Text(category.label),
                        selected: _categoryFilter == category,
                        onSelected: (_) {
                          setState(() => _categoryFilter = category);
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Payment',
                  style: RenewWiseTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: RenewWisePalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: HistoryCompletedFilter.values.map((filter) {
                    return FilterChip(
                      label: Text(filter.label),
                      selected: _paymentFilter == filter,
                      onSelected: (_) {
                        setState(() => _paymentFilter = filter);
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.reminderStateService,
      builder: (context, _) {
        final scoped = _scopedEntries();
        final entries = _displayList();
        final dueLabel = _amountLabel(scoped);
        final empty = _resolveEmptyState(scoped: scoped, entries: entries);

        return Scaffold(
          backgroundColor: RenewWisePalette.listBackground,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EventListHeader(
                      title: _pageTitle,
                      eventCount: scoped.length,
                      dueLabel: dueLabel,
                      onBack: () => Navigator.of(context).pop(),
                      onSort: _showSortSheet,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.page,
                        0,
                        AppSpacing.page,
                        12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              decoration: InputDecoration(
                                hintText: 'Search reminder name',
                                prefixIcon: const Icon(Icons.search_rounded),
                                filled: true,
                                fillColor: RenewWisePalette.cardSurface,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  borderSide: BorderSide(
                                    color: AppColors.primary.withAlpha(120),
                                  ),
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Material(
                            color: RenewWisePalette.cardSurface,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              onTap: _showFilterSheet,
                              borderRadius: BorderRadius.circular(14),
                              child: const SizedBox(
                                width: 44,
                                height: 44,
                                child: Icon(
                                  Icons.filter_list_rounded,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: entries.isEmpty
                          ? EventListEmptyState(
                              title: empty.title,
                              subtitle: empty.subtitle,
                              icon: empty.icon,
                              actionLabel: empty.actionLabel,
                              onAction: empty.onAction,
                              actionIcon: empty.actionIcon,
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.page,
                                0,
                                AppSpacing.page,
                                AppSpacing.xxl,
                              ),
                              itemCount: entries.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final entry = entries[index];
                                return HistoryCompletedListCard(
                                  entry: entry,
                                  onTap: () => widget.onOpenEntry(entry),
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
