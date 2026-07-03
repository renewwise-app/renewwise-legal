import 'package:flutter/material.dart';

import 'package:renew_wise/models/history_entry.dart';
import 'package:renew_wise/screens/history_completed_list_screen.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/utils/date_utils.dart';
import 'package:renew_wise/utils/history_events_scope.dart';

/// Pick a completion date range and browse matching history entries.
class HistoryPeriodScreen extends StatefulWidget {
  const HistoryPeriodScreen({
    super.key,
    required this.reminderStateService,
    required this.onOpenEntry,
  });

  final ReminderStateService reminderStateService;
  final void Function(HistoryEntry entry) onOpenEntry;

  static Future<void> push(
    BuildContext context, {
    required ReminderStateService reminderStateService,
    required void Function(HistoryEntry entry) onOpenEntry,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HistoryPeriodScreen(
          reminderStateService: reminderStateService,
          onOpenEntry: onOpenEntry,
        ),
      ),
    );
  }

  @override
  State<HistoryPeriodScreen> createState() => _HistoryPeriodScreenState();
}

class _HistoryPeriodScreenState extends State<HistoryPeriodScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;

  Future<void> _pickFromDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      helpText: 'From date',
    );
    if (picked != null && mounted) {
      setState(() {
        _fromDate = picked;
        if (_toDate != null && _toDate!.isBefore(picked)) {
          _toDate = picked;
        }
      });
    }
  }

  Future<void> _pickToDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? _fromDate ?? now,
      firstDate: _fromDate ?? DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      helpText: 'To date',
    );
    if (picked != null && mounted) setState(() => _toDate = picked);
  }

  void _browse() {
    if (_fromDate == null || _toDate == null) return;
    HistoryCompletedListScreen.push(
      context,
      title: 'Choose Period',
      scope: HistoryEventsScope.customPeriod,
      reminderStateService: widget.reminderStateService,
      onOpenEntry: widget.onOpenEntry,
      fromDate: _fromDate,
      toDate: _toDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canBrowse = _fromDate != null && _toDate != null;

    return Scaffold(
      backgroundColor: RenewWisePalette.pageBackground,
      appBar: AppBar(
        backgroundColor: RenewWisePalette.pageBackground,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Choose Period',
          style: RenewWiseTypography.cardTitle,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Select a date range to browse completed reminders.',
                    style: RenewWiseTypography.secondary,
                  ),
                  const SizedBox(height: AppSpacing.section),
                  _DateTile(
                    label: 'From',
                    value: _fromDate == null
                        ? 'Select start date'
                        : RenewalDateUtils.formatDisplayDate(_fromDate!),
                    onTap: _pickFromDate,
                  ),
                  const SizedBox(height: 12),
                  _DateTile(
                    label: 'To',
                    value: _toDate == null
                        ? 'Select end date'
                        : RenewalDateUtils.formatDisplayDate(_toDate!),
                    onTap: _pickToDate,
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: canBrowse ? _browse : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('View Completed Reminders'),
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

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RenewWisePalette.cardSurface,
      borderRadius: BorderRadius.circular(AppRadius.homeCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.homeCard),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.homeCard),
            boxShadow: RenewWiseShadows.listCard(),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: RenewWiseTypography.caption.copyWith(
                        color: RenewWisePalette.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: RenewWiseTypography.cardTitle.copyWith(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.calendar_today_outlined,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
