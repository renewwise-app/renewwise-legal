import 'package:flutter/material.dart';

import 'package:renew_wise/screens/home_events_list_screen.dart';
import 'package:renew_wise/services/assistant_draft_service.dart';
import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/notification_service.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/services/sharing_service.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/utils/date_utils.dart';
import 'package:renew_wise/utils/empty_state_guidance.dart';
import 'package:renew_wise/utils/home_events_scope.dart';
import 'package:renew_wise/widgets/common/renew_wise_back_button.dart';
import 'package:renew_wise/widgets/common/renew_wise_primary_button.dart';

/// Pick a date range and browse matching reminders.
class CustomSearchScreen extends StatefulWidget {
  const CustomSearchScreen({
    super.key,
    required this.renewalService,
    required this.settingsService,
    required this.reminderStateService,
    required this.notificationService,
    required this.eventExtrasService,
    this.sharingService,
    this.assistantDraftService,
  });

  final RenewalService renewalService;
  final SettingsService settingsService;
  final ReminderStateService reminderStateService;
  final NotificationService notificationService;
  final EventExtrasService eventExtrasService;
  final SharingService? sharingService;
  final AssistantDraftService? assistantDraftService;

  static Future<void> push(
    BuildContext context, {
    required RenewalService renewalService,
    required SettingsService settingsService,
    required ReminderStateService reminderStateService,
    required NotificationService notificationService,
    required EventExtrasService eventExtrasService,
    SharingService? sharingService,
    AssistantDraftService? assistantDraftService,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CustomSearchScreen(
          renewalService: renewalService,
          settingsService: settingsService,
          reminderStateService: reminderStateService,
          notificationService: notificationService,
          eventExtrasService: eventExtrasService,
          sharingService: sharingService,
          assistantDraftService: assistantDraftService,
        ),
      ),
    );
  }

  @override
  State<CustomSearchScreen> createState() => _CustomSearchScreenState();
}

class _CustomSearchScreenState extends State<CustomSearchScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;

  Future<void> _pickFromDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      helpText: 'From date',
    );
    if (picked != null && mounted) {
      setState(() {
        _fromDate = picked;
        if (_toDate != null &&
            RenewalDateUtils.dateOnly(_toDate!)
                .isBefore(RenewalDateUtils.dateOnly(picked))) {
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
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      helpText: 'To date',
    );
    if (picked != null && mounted) {
      setState(() {
        _toDate = picked;
        if (_fromDate != null &&
            RenewalDateUtils.dateOnly(picked)
                .isBefore(RenewalDateUtils.dateOnly(_fromDate!))) {
          _fromDate = picked;
        }
      });
    }
  }

  void _apply() {
    if (_fromDate == null || _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both dates.')),
      );
      return;
    }

    HomeEventsListScreen.push(
      context,
      title: 'Custom Search',
      scope: HomeEventsScope.customRange,
      fromDate: _fromDate,
      toDate: _toDate,
      renewalService: widget.renewalService,
      settingsService: widget.settingsService,
      reminderStateService: widget.reminderStateService,
      notificationService: widget.notificationService,
      eventExtrasService: widget.eventExtrasService,
      sharingService: widget.sharingService,
      assistantDraftService: widget.assistantDraftService,
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Tap to select';
    return RenewalDateUtils.formatDisplayDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final canApply = _fromDate != null && _toDate != null;
    final hPad =
        MediaQuery.sizeOf(context).width > 600 ? 32.0 : AppSpacing.page;

    return ListenableBuilder(
      listenable: widget.renewalService,
      builder: (context, _) {
        final hasReminders = widget.renewalService.renewals.isNotEmpty;
        final searchEnabled = hasReminders;

        return Scaffold(
          backgroundColor: RenewWisePalette.pageBackground,
          appBar: AppBar(
            backgroundColor: RenewWisePalette.pageBackground,
            surfaceTintColor: Colors.transparent,
            leading: const RenewWiseAppBarBackButton(),
            title: const Text('Custom Search'),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.page),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Find reminders between any two dates.',
                        style:
                            RenewWiseTypography.secondary.copyWith(height: 1.45),
                      ),
                      if (!searchEnabled) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Container(
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
                              Icon(
                                Icons.info_outline_rounded,
                                size: 20,
                                color: AppColors.gold,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  EmptyStateGuidance.customSearchNoReminders,
                                  style: RenewWiseTypography.secondary.copyWith(
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.section),
                      Opacity(
                        opacity: searchEnabled ? 1 : 0.45,
                        child: IgnorePointer(
                          ignoring: !searchEnabled,
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: RenewWisePalette.cardSurface,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.homeCard),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(8),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withAlpha(24),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        Icons.date_range_rounded,
                                        color: AppColors.primary,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Date Range',
                                      style: RenewWiseTypography.sectionTitle,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _DateRangeRow(
                                  label: 'From',
                                  value: _formatDate(_fromDate),
                                  onTap: _pickFromDate,
                                  isPlaceholder: _fromDate == null,
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: const Color(0xFFE2E8F0),
                                          height: 1,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: Text(
                                          'to',
                                          style: RenewWiseTypography.caption
                                              .copyWith(
                                            color: RenewWisePalette.textCaption,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: const Color(0xFFE2E8F0),
                                          height: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _DateRangeRow(
                                  label: 'To',
                                  value: _formatDate(_toDate),
                                  onTap: _pickToDate,
                                  isPlaceholder: _toDate == null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      RenewWisePrimaryButton(
                        label: 'Search Reminders',
                        onPressed: searchEnabled && canApply ? _apply : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DateRangeRow extends StatelessWidget {
  const _DateRangeRow({
    required this.label,
    required this.value,
    required this.onTap,
    required this.isPlaceholder,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RenewWisePalette.pageBackground,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: RenewWiseTypography.caption.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: RenewWiseTypography.tileEventCount.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isPlaceholder
                            ? RenewWisePalette.textCaption
                            : RenewWisePalette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.calendar_today_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
