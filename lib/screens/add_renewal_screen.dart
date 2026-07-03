import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:renew_wise/models/alert_style.dart';
import 'package:renew_wise/models/event_document.dart';
import 'package:renew_wise/models/recurrence_end_type.dart';
import 'package:renew_wise/models/reminder_workflow_type.dart';
import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/renewal_category.dart';
import 'package:renew_wise/models/renewal_currency.dart';
import 'package:renew_wise/models/renewal_importance.dart';
import 'package:renew_wise/models/renewal_priority.dart';
import 'package:renew_wise/models/renewal_status.dart';
import 'package:renew_wise/models/repeat_cycle.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/utils/add_reminder_step_flow.dart';
import 'package:renew_wise/utils/date_utils.dart';
import 'package:renew_wise/utils/document_attach_utils.dart';
import 'package:renew_wise/utils/document_open_utils.dart';
import 'package:renew_wise/utils/document_protection_dialogs.dart';
import 'package:renew_wise/utils/feature_purpose_messaging.dart';
import 'package:renew_wise/utils/recurrence_utils.dart';
import 'package:renew_wise/utils/reminder_schedule_utils.dart';
import 'package:renew_wise/widgets/add_reminder/add_reminder_review_cards.dart';
import 'package:renew_wise/widgets/add_reminder/add_reminder_widgets.dart';
import 'package:renew_wise/widgets/common/app_feedback.dart';
import 'package:renew_wise/widgets/common/app_motion.dart';

class AddRenewalScreen extends StatefulWidget {
  const AddRenewalScreen({
    super.key,
    required this.renewalService,
    this.renewal,
    this.defaultCurrency = RenewalCurrency.inr,
    this.defaultReminderTimeMinutes = 540,
    this.defaultAlertStyle = AlertStyle.standard,
  });

  final RenewalService renewalService;
  final Renewal? renewal;
  final RenewalCurrency defaultCurrency;
  final int defaultReminderTimeMinutes;
  final AlertStyle defaultAlertStyle;

  static Future<void> push(
    BuildContext context, {
    required RenewalService renewalService,
    Renewal? renewal,
    RenewalCurrency defaultCurrency = RenewalCurrency.inr,
    int defaultReminderTimeMinutes = 540,
    AlertStyle defaultAlertStyle = AlertStyle.standard,
  }) {
    return Navigator.of(context).push(
      AppPageRoute.fadeSlide(
        AddRenewalScreen(
          renewalService: renewalService,
          renewal: renewal,
          defaultCurrency: defaultCurrency,
          defaultReminderTimeMinutes: defaultReminderTimeMinutes,
          defaultAlertStyle: defaultAlertStyle,
        ),
      ),
    );
  }

  @override
  State<AddRenewalScreen> createState() => _AddRenewalScreenState();
}

class _AddRenewalScreenState extends State<AddRenewalScreen> {
  static const _formCategories = [
    RenewalCategory.insurance,
    RenewalCategory.vehicle,
    RenewalCategory.drivingLicence,
    RenewalCategory.passport,
    RenewalCategory.electricity,
    RenewalCategory.water,
    RenewalCategory.gas,
    RenewalCategory.internet,
    RenewalCategory.loanEmi,
    RenewalCategory.creditCard,
    RenewalCategory.gym,
    RenewalCategory.subscription,
    RenewalCategory.warranty,
    RenewalCategory.other,
  ];

  static const _stepOnePriorities = [
    RenewalPriority.high,
    RenewalPriority.medium,
    RenewalPriority.low,
  ];

  static const _reminderOptions = [90, 60, 30, 15, 7, 3, 1];
  static const _stepPadding = EdgeInsets.fromLTRB(
    AppSpacing.page,
    6,
    AppSpacing.page,
    12,
  );

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _customTypeController = TextEditingController();
  final _occurrenceCountController = TextEditingController();
  final _imagePicker = ImagePicker();

  int _stepIndex = 0;
  int _slideDirection = 1;
  ReminderWorkflowType? _workflowType;
  bool _repeatEndEnabled = false;
  RenewalCategory _category = RenewalCategory.insurance;
  DateTime? _renewalDate;
  bool _paymentRequired = false;
  late RenewalCurrency _currency;
  bool _isRecurring = false;
  RepeatCycle _recurrenceCycle = RepeatCycle.daily;
  RecurrenceEndType _recurrenceEndType = RecurrenceEndType.never;
  DateTime? _recurrenceEndDate;
  final Set<int> _reminderDays = {30, 7, 1};
  final List<DateTime> _customReminderDates = [];
  late int _reminderHour;
  late int _reminderMinute;
  RenewalPriority _priority = RenewalPriority.medium;
  AlertStyle _alertStyle = AlertStyle.standard;
  RenewalImportance _importance = RenewalImportance.important;
  final List<EventDocument> _attachedDocuments = [];

  bool get _isEditing => widget.renewal != null;

  List<AddReminderStepId> get _activeSteps => AddReminderStepFlow.build(
        workflowType: _workflowType,
        isEditing: _isEditing,
        paymentRequired: _paymentRequired,
        repeatEndEnabled: _repeatEndEnabled,
      );

  AddReminderStepId get _currentStep =>
      _activeSteps[_stepIndex.clamp(0, _activeSteps.length - 1)];

  List<RenewalCategory> get _dropdownCategories {
    if (_formCategories.contains(_category)) return _formCategories;
    return [..._formCategories, _category];
  }

  List<RenewalPriority> get _stepOnePriorityOptions {
    if (_stepOnePriorities.contains(_priority)) return _stepOnePriorities;
    return [_priority, ..._stepOnePriorities];
  }

  List<RepeatCycle> get _frequencyOptions {
    return switch (_workflowType) {
      ReminderWorkflowType.renewal => kRenewalWorkflowCycles,
      ReminderWorkflowType.recurring => kUserRecurrenceCycles,
      _ => kUserRecurrenceCycles,
    };
  }

  @override
  void initState() {
    super.initState();
    _currency = widget.renewal?.currency ?? widget.defaultCurrency;

    final defMinutes = widget.renewal?.reminderTimeMinutes ??
        widget.defaultReminderTimeMinutes;
    _reminderHour = defMinutes ~/ 60;
    _reminderMinute = defMinutes % 60;
    _alertStyle = widget.defaultAlertStyle;

    _titleController.addListener(_onChange);
    _amountController.addListener(_onChange);
    _customTypeController.addListener(_onChange);
    _occurrenceCountController.addListener(_onChange);

    final r = widget.renewal;
    if (r != null) {
      _workflowType = inferReminderWorkflowType(r);
      _titleController.text = r.title;
      _category = r.category;
      _customTypeController.text = r.customEventType ?? '';
      _renewalDate = r.renewalDate;
      _paymentRequired = r.paymentRequired;
      if (r.amount != null) {
        _amountController.text = r.amount!.toStringAsFixed(0);
      }
      _currency = r.currency;
      _isRecurring = RecurrenceUtils.isRecurring(r);
      if (_isRecurring) {
        _recurrenceCycle = r.repeatCycle;
        _recurrenceEndType = r.recurrenceEndType;
        _recurrenceEndDate = r.recurrenceEndDate;
        _repeatEndEnabled =
            r.recurrenceEndType != RecurrenceEndType.never;
        if (r.recurrenceOccurrenceLimit != null) {
          _occurrenceCountController.text =
              r.recurrenceOccurrenceLimit.toString();
        }
      }
      _reminderDays
        ..clear()
        ..addAll(r.reminderSchedule);
      _customReminderDates
        ..clear()
        ..addAll(r.customReminderDates);
      _priority = r.priority;
      _alertStyle = r.alertStyle;
      _importance = r.importance;
      _notesController.text = r.notes ?? '';
      _pruneInvalidReminders();
      _stepIndex = _activeSteps.indexOf(AddReminderStepId.title).clamp(0, 999);
    }
  }

  void _onChange() => setState(() {});

  @override
  void dispose() {
    _titleController.removeListener(_onChange);
    _amountController.removeListener(_onChange);
    _customTypeController.removeListener(_onChange);
    _occurrenceCountController.removeListener(_onChange);
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _customTypeController.dispose();
    _occurrenceCountController.dispose();
    super.dispose();
  }

  void _applyWorkflowDefaults(ReminderWorkflowType type) {
    _workflowType = type;
    switch (type) {
      case ReminderWorkflowType.oneTime:
        _isRecurring = false;
        _recurrenceCycle = RepeatCycle.oneTime;
        _repeatEndEnabled = false;
        _recurrenceEndType = RecurrenceEndType.never;
        _reminderDays
          ..clear()
          ..addAll({7, 1});
      case ReminderWorkflowType.recurring:
        _isRecurring = true;
        _recurrenceCycle = RepeatCycle.daily;
        _repeatEndEnabled = false;
        _recurrenceEndType = RecurrenceEndType.never;
        _reminderDays
          ..clear()
          ..add(0);
      case ReminderWorkflowType.renewal:
        _isRecurring = true;
        _recurrenceCycle = RepeatCycle.yearly;
        _repeatEndEnabled = false;
        _recurrenceEndType = RecurrenceEndType.never;
        _reminderDays
          ..clear()
          ..addAll({30, 7, 1});
    }
  }

  void _handleBack() {
    if (_stepIndex > 0) {
      setState(() {
        _slideDirection = -1;
        _stepIndex--;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  void _goNext() {
    if (!_canProceedCurrentStep) return;
    final error = _reminderValidationError ?? _recurrenceValidationError;
    if (error != null &&
        {
          AddReminderStepId.reminderSchedule,
          AddReminderStepId.reminderTime,
          AddReminderStepId.repeatEndConfig,
        }.contains(_currentStep)) {
      AppFeedback.info(context, error);
      return;
    }

    if (_currentStep == AddReminderStepId.review) {
      _save();
      return;
    }

    setState(() {
      _slideDirection = 1;
      _stepIndex = (_stepIndex + 1).clamp(0, _activeSteps.length - 1);
    });
  }

  void _goBack() {
    if (_stepIndex == 0) return;
    setState(() {
      _slideDirection = -1;
      _stepIndex--;
    });
  }

  bool get _canProceedCurrentStep {
    return switch (_currentStep) {
      AddReminderStepId.typeSelection => _workflowType != null,
      AddReminderStepId.title => _titleController.text.trim().isNotEmpty,
      AddReminderStepId.category =>
        _category != RenewalCategory.other ||
            _customTypeController.text.trim().isNotEmpty,
      AddReminderStepId.importance => true,
      AddReminderStepId.alertStyle => true,
      AddReminderStepId.eventDate => _renewalDate != null,
      AddReminderStepId.repeatFrequency => true,
      AddReminderStepId.reminderSchedule =>
        _reminderDays.isNotEmpty || _customReminderDates.isNotEmpty,
      AddReminderStepId.reminderTime => true,
      AddReminderStepId.repeatEndToggle => true,
      AddReminderStepId.repeatEndConfig =>
        _recurrenceValidationError == null &&
            (_recurrenceEndType == RecurrenceEndType.never ||
                (_recurrenceEndType == RecurrenceEndType.endDate &&
                    _recurrenceEndDate != null) ||
                (_recurrenceEndType == RecurrenceEndType.occurrenceCount &&
                    _recurrenceOccurrenceLimit != null)),
      AddReminderStepId.paymentToggle => true,
      AddReminderStepId.paymentDetails => _paymentAmountValid,
      AddReminderStepId.documents => true,
      AddReminderStepId.notes => true,
      AddReminderStepId.review => _canSave,
    };
  }

  bool get _paymentAmountValid {
    if (!_paymentRequired) return true;
    final amt = double.tryParse(_amountController.text.trim());
    return amt != null && amt > 0;
  }

  bool get _canSave {
    if (_titleController.text.trim().isEmpty) return false;
    if (_category == RenewalCategory.other &&
        _customTypeController.text.trim().isEmpty) {
      return false;
    }
    if (_renewalDate == null) return false;
    if (_paymentRequired && !_paymentAmountValid) return false;
    if (_workflowType != ReminderWorkflowType.recurring &&
        _reminderDays.isEmpty &&
        _customReminderDates.isEmpty) {
      return false;
    }
    if (_reminderValidationError != null) return false;
    if (_recurrenceValidationError != null) return false;
    return true;
  }

  bool get _isOptionalStep =>
      _currentStep == AddReminderStepId.documents ||
      _currentStep == AddReminderStepId.notes;

  String get _primaryButtonLabel {
    if (_currentStep == AddReminderStepId.review) {
      return _isEditing ? 'Update Reminder' : 'Save Reminder';
    }
    return 'Continue →';
  }

  Future<void> _pickDate({String? helpText}) async {
    final picked = await RenewalDateUtils.pickExpiryDate(
      context,
      helpText: helpText ?? 'Select date',
      initialDate: _renewalDate,
    );
    if (picked != null) {
      setState(() {
        _renewalDate = picked;
        _pruneInvalidReminders();
      });
    }
  }

  Future<void> _pickCustomReminderDate() async {
    if (_renewalDate == null) {
      AppFeedback.info(context, 'Choose a date first, then add reminder dates.');
      return;
    }

    final now = DateTime.now();
    final today = RenewalDateUtils.dateOnly(now);
    final expiry = RenewalDateUtils.dateOnly(_renewalDate!);
    final suggested = expiry.subtract(const Duration(days: 7));
    final initialDate = ReminderScheduleUtils.clampReminderDate(
      suggested,
      _renewalDate!,
      now: now,
    );

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: expiry,
      helpText: 'Select reminder date',
      selectableDayPredicate: (date) =>
          ReminderScheduleUtils.isValidCustomReminderDate(
        _renewalDate!,
        date,
        now: now,
      ),
    );
    if (picked != null) {
      setState(() {
        _reminderDays.clear();
        final exists = _customReminderDates.any(
          (d) =>
              d.year == picked.year &&
              d.month == picked.month &&
              d.day == picked.day,
        );
        if (!exists) _customReminderDates.add(picked);
      });
    }
  }

  Future<void> _attachDocument() async {
    final source = await DocumentAttachUtils.pickSource(context);
    if (source == null || !mounted) return;

    final docs = await DocumentAttachUtils.pickAndCopy(
      context: context,
      picker: _imagePicker,
      source: source,
      renewalId: 'pending',
    );
    if (docs.isEmpty) return;
    for (final doc in docs) {
      if (!mounted) return;
      final prepared = await DocumentProtectionFlow.applyAfterAttach(
        context,
        doc,
      );
      setState(() {
        final exists = _attachedDocuments.any((d) => d.name == prepared.name);
        if (!exists) _attachedDocuments.add(prepared);
      });
    }
  }

  Future<void> _viewAttachedDocument(EventDocument doc) async {
    await DocumentOpenUtils.open(context, doc);
  }

  Future<void> _replaceAttachedDocument(int index) async {
    final source = await DocumentAttachUtils.pickSource(context);
    if (source == null || !mounted) return;

    final docs = await DocumentAttachUtils.pickAndCopy(
      context: context,
      picker: _imagePicker,
      source: source,
      renewalId: 'pending',
    );
    if (docs.isEmpty) return;
    if (!mounted) return;
    final prepared = await DocumentProtectionFlow.applyAfterAttach(
      context,
      docs.first,
    );
    setState(() => _attachedDocuments[index] = prepared);
  }

  void _removeAttachedDocument(int index) {
    setState(() => _attachedDocuments.removeAt(index));
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final reminderError = _reminderValidationError ?? _recurrenceValidationError;
    if (reminderError != null) {
      AppFeedback.info(context, reminderError);
      return;
    }
    if (!_canSave) return;

    if (_workflowType == ReminderWorkflowType.recurring &&
        _reminderDays.isEmpty &&
        _customReminderDates.isEmpty) {
      _reminderDays.add(0);
    }

    final repeatCycle =
        _isRecurring ? _recurrenceCycle : RepeatCycle.oneTime;
    final recurrenceEndType =
        _isRecurring && _repeatEndEnabled
            ? _recurrenceEndType
            : RecurrenceEndType.never;
    final recurrenceEndDate = _isRecurring &&
            _repeatEndEnabled &&
            _recurrenceEndType == RecurrenceEndType.endDate
        ? _recurrenceEndDate
        : null;
    final recurrenceOccurrenceLimit = _isRecurring &&
            _repeatEndEnabled &&
            _recurrenceEndType == RecurrenceEndType.occurrenceCount
        ? _recurrenceOccurrenceLimit
        : null;

    final now = DateTime.now();
    final amountText = _amountController.text.trim();
    final parsedAmount = (_paymentRequired && amountText.isNotEmpty)
        ? double.tryParse(amountText)
        : null;
    final customType = (_category == RenewalCategory.other)
        ? _customTypeController.text.trim().isEmpty
            ? null
            : _customTypeController.text.trim()
        : null;

    final reminderTimeMinutes = _reminderHour * 60 + _reminderMinute;

    final renewal = Renewal(
      id: widget.renewal?.id ?? now.microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      category: _category,
      customEventType: customType,
      renewalDate: _renewalDate!,
      paymentRequired: _paymentRequired,
      amount: parsedAmount,
      currency: _currency,
      importance: _importance,
      priority: _priority,
      alertStyle: _alertStyle,
      status: widget.renewal?.status ?? RenewalStatus.upcoming,
      repeatCycle: repeatCycle,
      recurrenceEndType: recurrenceEndType,
      recurrenceEndDate: recurrenceEndDate,
      recurrenceOccurrenceLimit: recurrenceOccurrenceLimit,
      recurrenceCompletedCount: widget.renewal?.recurrenceCompletedCount ?? 0,
      reminderSchedule: (_reminderDays.toList()..sort((a, b) => b.compareTo(a))),
      customReminderDates: List.of(_customReminderDates),
      reminderTimeMinutes: reminderTimeMinutes,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: widget.renewal?.createdAt ?? now,
      updatedAt: now,
    );

    if (_isEditing) {
      widget.renewalService.updateRenewal(renewal);
      AppFeedback.updated(context);
    } else {
      widget.renewalService.addRenewal(renewal);
      AppFeedback.saved(context);
    }
    Navigator.of(context).pop();
  }

  String get _categoryLabel {
    if (_category == RenewalCategory.other &&
        _customTypeController.text.trim().isNotEmpty) {
      return _customTypeController.text.trim();
    }
    return _category.label;
  }

  String get _paymentSummary {
    if (!_paymentRequired) return 'No payment';
    final amt = double.tryParse(_amountController.text.trim());
    if (amt == null) return 'Payment required';
    return _currency.formatAmount(amt);
  }

  String get _documentsSummary {
    if (_attachedDocuments.isEmpty) return 'None attached';
    return '${_attachedDocuments.length} attached';
  }

  String get _notesSummary {
    final notes = _notesController.text.trim();
    return notes.isEmpty ? 'None' : notes;
  }

  String get _scheduleSummary {
    final chips = [
      ..._reminderDays.map(_reminderChipLabel),
      ..._customReminderDates.map(RenewalDateUtils.formatDisplayDate),
    ];
    return chips.isEmpty ? 'On the day' : chips.join(', ');
  }

  String _reminderChipLabel(int days) {
    if (_renewalDate == null || _reminderOptions.contains(days)) {
      return _daysBeforeLabel(days);
    }
    final reminderDate = ReminderScheduleUtils.reminderDateForDaysBefore(
      _renewalDate!,
      days,
    );
    return '${_daysBeforeLabel(days)} · '
        '${RenewalDateUtils.formatDisplayDate(reminderDate)}';
  }

  String _daysBeforeLabel(int days) {
    return days == 1 ? '1 Day Before' : '$days Days Before';
  }

  List<int> get _availableReminderOptions {
    if (_renewalDate == null) return const [];
    return ReminderScheduleUtils.availablePresetOptions(_renewalDate!);
  }

  String? get _reminderValidationError {
    if (_renewalDate == null) return null;
    if (_workflowType == ReminderWorkflowType.recurring) return null;
    return ReminderScheduleUtils.validateSchedule(
      expiry: _renewalDate!,
      reminderDays: _reminderDays.toList(),
      customDates: _customReminderDates,
      reminderHour: _reminderHour,
      reminderMinute: _reminderMinute,
    );
  }

  int? get _recurrenceOccurrenceLimit {
    if (!_isRecurring ||
        !_repeatEndEnabled ||
        _recurrenceEndType != RecurrenceEndType.occurrenceCount) {
      return null;
    }
    return int.tryParse(_occurrenceCountController.text.trim());
  }

  String? get _recurrenceValidationError {
    return RecurrenceUtils.validate(
      isRecurring: _isRecurring && _workflowType != ReminderWorkflowType.oneTime,
      cycle: _isRecurring ? _recurrenceCycle : RepeatCycle.oneTime,
      renewalDate: _renewalDate,
      endType: _repeatEndEnabled ? _recurrenceEndType : RecurrenceEndType.never,
      endDate: _recurrenceEndDate,
      occurrenceLimit: _recurrenceOccurrenceLimit,
    );
  }

  String get _recurrenceSummary {
    if (_workflowType == ReminderWorkflowType.oneTime) return 'One Time';
    if (!_isRecurring) return 'One Time';
    final cycle = RecurrenceUtils.recurringCycleLabel(_recurrenceCycle);
    if (!_repeatEndEnabled) return cycle;
    final end = switch (_recurrenceEndType) {
      RecurrenceEndType.never => 'Never Ends',
      RecurrenceEndType.endDate when _recurrenceEndDate != null =>
        'Ends ${RenewalDateUtils.formatDisplayDate(_recurrenceEndDate!)}',
      RecurrenceEndType.endDate => 'End On Date',
      RecurrenceEndType.occurrenceCount when _recurrenceOccurrenceLimit != null =>
        'After $_recurrenceOccurrenceLimit occurrence'
            '${_recurrenceOccurrenceLimit == 1 ? '' : 's'}',
      RecurrenceEndType.occurrenceCount => 'After Number of Occurrences',
    };
    return '$cycle · $end';
  }

  Future<void> _pickRecurrenceEndDate() async {
    final now = DateTime.now();
    final today = RenewalDateUtils.dateOnly(now);
    final picked = await showDatePicker(
      context: context,
      initialDate: _recurrenceEndDate ?? today.add(const Duration(days: 30)),
      firstDate: today.add(const Duration(days: 1)),
      lastDate: DateTime(2100),
      helpText: 'When should this reminder stop?',
    );
    if (picked != null) {
      setState(() => _recurrenceEndDate = picked);
    }
  }

  void _pruneInvalidReminders() {
    if (_renewalDate == null) return;
    ReminderScheduleUtils.pruneInvalidSelections(
      expiry: _renewalDate!,
      reminderDays: _reminderDays,
      customReminderDates: _customReminderDates,
    );
  }

  List<int> get _customOffsetReminderDays =>
      _reminderDays.where((d) => !_reminderOptions.contains(d)).toList()
        ..sort((a, b) => b.compareTo(a));

  void _toggleStandardReminderDay(int days, bool selected) {
    setState(() {
      _customReminderDates.clear();
      if (selected) {
        _reminderDays.removeWhere((d) => !_reminderOptions.contains(d));
        _reminderDays.add(days);
      } else {
        _reminderDays.remove(days);
      }
    });
  }

  Future<void> _promptCustomDays() async {
    if (_renewalDate == null) {
      AppFeedback.info(context, 'Choose a date first, then add custom reminder days.');
      return;
    }

    final controller = TextEditingController();
    final days = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          title: const Text('Custom Days'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How many days before would you like to be reminded?',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: 'e.g. 12',
                  labelText: 'Days before',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text.trim());
                if (parsed == null || parsed <= 0) return;
                if (!ReminderScheduleUtils.isValidDaysBefore(
                  _renewalDate!,
                  parsed,
                )) {
                  AppFeedback.info(
                    context,
                    ReminderScheduleUtils.betweenTodayAndExpiryMessage,
                  );
                  return;
                }
                Navigator.of(context).pop(parsed);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (days == null) return;

    setState(() {
      _customReminderDates.clear();
      _reminderDays.removeWhere((d) => _reminderOptions.contains(d));
      _reminderDays.add(days);
    });
  }

  Future<void> _pickCustomReminderTime() async {
    if (_renewalDate == null) return;

    final now = DateTime.now();
    final restrictToFuture = _workflowType != ReminderWorkflowType.recurring &&
        ReminderScheduleUtils.requiresFutureTimeToday(
          expiry: _renewalDate!,
          reminderDays: _reminderDays.toList(),
          customDates: _customReminderDates,
          now: now,
        );

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
      helpText: 'Reminder time',
    );
    if (picked != null) {
      if (restrictToFuture) {
        final scheduled = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
        if (!scheduled.isAfter(now)) {
          if (!mounted) return;
          AppFeedback.info(
            context,
            ReminderScheduleUtils.futureReminderMessage,
          );
          return;
        }
      }
      setState(() {
        _reminderHour = picked.hour;
        _reminderMinute = picked.minute;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressLabels = AddReminderStepFlow.progressLabels(_activeSteps);
    final progressIndex =
        AddReminderStepFlow.progressIndex(_activeSteps, _stepIndex);

    return Scaffold(
      backgroundColor: RenewWisePalette.pageBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AddReminderAmbientBackground(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AddReminderHeader(
                      title: _isEditing ? 'Edit Reminder' : 'Add Reminder',
                      subtitle: _isEditing
                          ? null
                          : FeaturePurposeMessaging.addReminder,
                      onBack: _handleBack,
                    ),
                    if (progressLabels.length > 1)
                      AddReminderProgressIndicator(
                        labels: progressLabels,
                        activeIndex: progressIndex,
                      ),
                    Expanded(
                      child: Form(
                        key: _formKey,
                        child: AnimatedSwitcher(
                          duration: AppMotion.duration,
                          switchInCurve: AppMotion.curve,
                          layoutBuilder: (currentChild, _) => currentChild!,
                          transitionBuilder: (child, animation) {
                            final curved = CurvedAnimation(
                              parent: animation,
                              curve: AppMotion.curve,
                            );
                            final offsetAnimation = Tween<Offset>(
                              begin: Offset(_slideDirection * 0.08, 0),
                              end: Offset.zero,
                            ).animate(curved);
                            return SlideTransition(
                              position: offsetAnimation,
                              child: FadeTransition(
                                opacity: curved,
                                child: child,
                              ),
                            );
                          },
                          child: KeyedSubtree(
                            key: ValueKey('$_stepIndex-${_currentStep.name}'),
                            child: _buildCurrentStep(),
                          ),
                        ),
                      ),
                    ),
                    AddReminderFooter(
                      primaryLabel: _primaryButtonLabel,
                      primaryEnabled: _canProceedCurrentStep,
                      onPrimary: _goNext,
                      onBack: _stepIndex > 0 ? _goBack : null,
                      onSkip: _isOptionalStep ? _goNext : null,
                      showSaveIcon: _currentStep == AddReminderStepId.review,
                      helperText: _currentStep == AddReminderStepId.review
                          ? 'You\'re all set. RenewWise will take care of the reminders.'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    return switch (_currentStep) {
      AddReminderStepId.typeSelection => ReminderTypeSelectionStep(
          onSelected: (type) {
            setState(() {
              _applyWorkflowDefaults(type);
              _slideDirection = 1;
              _stepIndex = 1;
            });
          },
        ),
      AddReminderStepId.title => _buildSingleStepList(_buildTitleStep()),
      AddReminderStepId.category => _buildSingleStepList(_buildCategoryStep()),
      AddReminderStepId.importance =>
        _buildSingleStepList(_buildImportanceStep()),
      AddReminderStepId.alertStyle =>
        _buildSingleStepList(_buildAlertStyleStep()),
      AddReminderStepId.eventDate => _buildSingleStepList(_buildEventDateStep()),
      AddReminderStepId.repeatFrequency =>
        _buildSingleStepList(_buildRepeatFrequencyStep()),
      AddReminderStepId.reminderSchedule =>
        _buildSingleStepList(_buildReminderScheduleStep()),
      AddReminderStepId.reminderTime =>
        _buildSingleStepList(_buildReminderTimeStep()),
      AddReminderStepId.repeatEndToggle =>
        _buildSingleStepList(_buildRepeatEndToggleStep()),
      AddReminderStepId.repeatEndConfig =>
        _buildSingleStepList(_buildRepeatEndConfigStep()),
      AddReminderStepId.paymentToggle =>
        _buildSingleStepList(_buildPaymentToggleStep()),
      AddReminderStepId.paymentDetails =>
        _buildSingleStepList(_buildPaymentDetailsStep()),
      AddReminderStepId.documents => _buildSingleStepList(_buildDocumentsStep()),
      AddReminderStepId.notes => _buildSingleStepList(_buildNotesStep()),
      AddReminderStepId.review => _buildSingleStepList(_buildReviewStep()),
    };
  }

  Widget _buildSingleStepList(Widget card) {
    return ListView(
      padding: _stepPadding,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [card],
    );
  }

  Widget _buildTitleStep() {
    return AddReminderQuestionCard(
      icon: Icons.edit_note_rounded,
      iconColor: AppColors.primary,
      heading: 'What would you like me to remember?',
      child: AddReminderInputShell(
        child: TextFormField(
          controller: _titleController,
          textCapitalization: TextCapitalization.words,
          autofocus: true,
          style: AddReminderStyles.input,
          decoration: AddReminderFieldDecoration.field(
            hint: 'e.g. Passport Renewal',
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Reminder name is required' : null,
        ),
      ),
    );
  }

  Widget _buildCategoryStep() {
    return AddReminderQuestionCard(
      icon: Icons.category_outlined,
      iconColor: AppColors.primary,
      heading: 'Assign a category',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AddReminderInputShell(
            child: DropdownButtonFormField<RenewalCategory>(
              isExpanded: true,
              initialValue: _category,
              decoration: AddReminderFieldDecoration.field(),
              items: _dropdownCategories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          Icon(c.icon, size: AppIconSize.sm, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text(c.label, style: AddReminderStyles.input),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _category = v;
                    if (v != RenewalCategory.other) {
                      _customTypeController.clear();
                    }
                  });
                }
              },
            ),
          ),
          if (_category == RenewalCategory.other) ...[
            const SizedBox(height: 10),
            AddReminderInputShell(
              child: TextFormField(
                controller: _customTypeController,
                textCapitalization: TextCapitalization.words,
                style: AddReminderStyles.input,
                decoration: AddReminderFieldDecoration.field(
                  hint: 'Custom category',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImportanceStep() {
    return AddReminderQuestionCard(
      icon: Icons.star_rounded,
      iconColor: _priority.color,
      heading: 'How important is this?',
      child: AddReminderInputShell(
        child: DropdownButtonFormField<RenewalPriority>(
          isExpanded: true,
          initialValue: _stepOnePriorityOptions.contains(_priority)
              ? _priority
              : RenewalPriority.medium,
          decoration: AddReminderFieldDecoration.field(),
          items: _stepOnePriorityOptions
              .map(
                (p) => DropdownMenuItem(
                  value: p,
                  child: Text(
                    p.label,
                    style: AddReminderStyles.input.copyWith(color: p.color),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _priority = v);
          },
        ),
      ),
    );
  }

  Widget _buildAlertStyleStep() {
    return AddReminderQuestionCard(
      icon: Icons.notifications_active_outlined,
      iconColor: _alertStyle.color,
      heading: 'How should I alert you?',
      child: AddReminderInputShell(
        child: DropdownButtonFormField<AlertStyle>(
          isExpanded: true,
          initialValue: _alertStyle,
          decoration: AddReminderFieldDecoration.field(),
          items: AlertStyle.values
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                    s.dropdownLabel,
                    style: AddReminderStyles.input.copyWith(color: s.color),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _alertStyle = v);
          },
        ),
      ),
    );
  }

  Widget _buildEventDateStep() {
    final heading = switch (_workflowType) {
      ReminderWorkflowType.recurring => 'When should it start?',
      ReminderWorkflowType.renewal => 'When is the renewal due?',
      _ => 'When is it due?',
    };

    return AddReminderQuestionCard(
      icon: Icons.calendar_month_rounded,
      iconColor: AppColors.primary,
      heading: heading,
      child: AddReminderInputShell(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InputDecorator(
              decoration: AddReminderFieldDecoration.field(
                suffixIcon: Icon(
                  Icons.calendar_today_outlined,
                  size: AppIconSize.sm,
                  color: AppColors.primary,
                ),
              ),
              child: Text(
                _renewalDate == null
                    ? 'Select date'
                    : RenewalDateUtils.formatDisplayDate(_renewalDate!),
                style: AddReminderStyles.input.copyWith(
                  color: _renewalDate == null
                      ? RenewWisePalette.textSecondary
                      : RenewWisePalette.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRepeatFrequencyStep() {
    final heading = _workflowType == ReminderWorkflowType.renewal
        ? 'How often does it renew?'
        : 'How often should it repeat?';

    return AddReminderQuestionCard(
      icon: Icons.repeat_rounded,
      iconColor: AppColors.primary,
      heading: heading,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _frequencyOptions.map((cycle) {
          return FilterChip(
            label: Text(RecurrenceUtils.cyclePickerLabel(cycle)),
            selected: _recurrenceCycle == cycle,
            onSelected: (_) => setState(() => _recurrenceCycle = cycle),
            selectedColor: AppColors.primary.withAlpha(24),
            checkmarkColor: AppColors.primary,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReminderScheduleStep() {
    return AddReminderQuestionCard(
      icon: Icons.notifications_active_outlined,
      iconColor: AppColors.primary,
      heading: 'How early should I remind you?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._availableReminderOptions.map(
                (days) => FilterChip(
                  label: Text(_daysBeforeLabel(days)),
                  selected: _reminderDays.contains(days),
                  onSelected: (value) => _toggleStandardReminderDay(days, value),
                  selectedColor: AppColors.primary.withAlpha(24),
                  checkmarkColor: AppColors.primary,
                ),
              ),
              ..._customOffsetReminderDays.map(
                (days) => InputChip(
                  label: Text(_reminderChipLabel(days)),
                  onDeleted: () => setState(() => _reminderDays.remove(days)),
                ),
              ),
              ..._customReminderDates.asMap().entries.map(
                (entry) => InputChip(
                  label: Text(
                    RenewalDateUtils.formatDisplayDate(entry.value),
                  ),
                  onDeleted: () =>
                      setState(() => _customReminderDates.removeAt(entry.key)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _promptCustomDays,
                icon: const Icon(Icons.today_outlined, size: 18),
                label: const Text('Custom Days'),
              ),
              OutlinedButton.icon(
                onPressed: _pickCustomReminderDate,
                icon: const Icon(Icons.event_outlined, size: 18),
                label: const Text('Custom Date'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReminderTimeStep() {
    final time = TimeOfDay(hour: _reminderHour, minute: _reminderMinute);
    return AddReminderQuestionCard(
      icon: Icons.access_time_rounded,
      iconColor: AppColors.primary,
      heading: 'What time should I remind you?',
      child: AddReminderInputShell(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _pickCustomReminderTime,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InputDecorator(
              decoration: AddReminderFieldDecoration.field(
                suffixIcon: Icon(Icons.schedule_rounded, color: AppColors.primary),
              ),
              child: Text(
                time.format(context),
                style: AddReminderStyles.input,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRepeatEndToggleStep() {
    return AddReminderQuestionCard(
      icon: Icons.event_busy_outlined,
      iconColor: AppColors.primary,
      heading: 'Should this reminder ever stop?',
      subtitle: 'Leave off to continue indefinitely.',
      child: SwitchListTile(
        title: const Text('Set an end date or occurrence limit'),
        value: _repeatEndEnabled,
        onChanged: (v) => setState(() {
          _repeatEndEnabled = v;
          if (!v) {
            _recurrenceEndType = RecurrenceEndType.never;
            _recurrenceEndDate = null;
            _occurrenceCountController.clear();
          } else {
            _recurrenceEndType = RecurrenceEndType.endDate;
          }
        }),
        activeThumbColor: AppColors.primary,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildRepeatEndConfigStep() {
    return AddReminderQuestionCard(
      icon: Icons.stop_circle_outlined,
      iconColor: AppColors.primary,
      heading: 'When should this reminder stop?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RadioChoice(
            label: RecurrenceEndType.endDate.label,
            selected: _recurrenceEndType == RecurrenceEndType.endDate,
            onTap: () =>
                setState(() => _recurrenceEndType = RecurrenceEndType.endDate),
          ),
          if (_recurrenceEndType == RecurrenceEndType.endDate) ...[
            const SizedBox(height: 8),
            AddReminderInputShell(
              child: InkWell(
                onTap: _pickRecurrenceEndDate,
                child: InputDecorator(
                  decoration: AddReminderFieldDecoration.field(),
                  child: Text(
                    _recurrenceEndDate == null
                        ? 'Select end date'
                        : RenewalDateUtils.formatDisplayDate(_recurrenceEndDate!),
                    style: AddReminderStyles.input,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          _RadioChoice(
            label: RecurrenceEndType.occurrenceCount.label,
            selected: _recurrenceEndType == RecurrenceEndType.occurrenceCount,
            onTap: () => setState(
              () => _recurrenceEndType = RecurrenceEndType.occurrenceCount,
            ),
          ),
          if (_recurrenceEndType == RecurrenceEndType.occurrenceCount) ...[
            const SizedBox(height: 8),
            AddReminderInputShell(
              child: TextFormField(
                controller: _occurrenceCountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AddReminderStyles.input,
                decoration: AddReminderFieldDecoration.field(
                  hint: 'Number of occurrences',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentToggleStep() {
    return AddReminderQuestionCard(
      icon: Icons.payments_outlined,
      iconColor: AppColors.primary,
      heading: 'Is there a payment due?',
      child: SwitchListTile(
        title: const Text('Payment due on this reminder'),
        value: _paymentRequired,
        onChanged: (v) => setState(() {
          _paymentRequired = v;
          if (!v) _amountController.clear();
        }),
        activeThumbColor: AppColors.primary,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildPaymentDetailsStep() {
    return AddReminderQuestionCard(
      icon: Icons.account_balance_wallet_outlined,
      iconColor: AppColors.primary,
      heading: 'How much is due?',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: AddReminderInputShell(
              child: DropdownButtonFormField<RenewalCurrency>(
                isExpanded: true,
                initialValue: _currency,
                decoration: AddReminderFieldDecoration.field(),
                items: RenewalCurrency.values
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.symbol, style: AddReminderStyles.input),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _currency = v);
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AddReminderInputShell(
              child: TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                style: AddReminderStyles.input,
                decoration: AddReminderFieldDecoration.field(hint: 'Amount'),
                validator: (v) {
                  if (!_paymentRequired) return null;
                  final parsed = double.tryParse(v?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter an amount greater than zero';
                  }
                  return null;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsStep() {
    return AddReminderQuestionCard(
      icon: Icons.folder_open_rounded,
      iconColor: AppColors.primary,
      heading: 'Would you like to attach documents?',
      subtitle: 'Optional — bills, papers, receipts, or warranties.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: _attachDocument,
            icon: const Icon(Icons.attach_file_rounded),
            label: const Text('Attach Document'),
          ),
          const SizedBox(height: 12),
          const AddReminderDocumentProtectionHint(),
          if (_attachedDocuments.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._attachedDocuments.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AttachedDocumentRow(
                  document: entry.value,
                  onView: () => _viewAttachedDocument(entry.value),
                  onReplace: () => _replaceAttachedDocument(entry.key),
                  onRemove: () => _removeAttachedDocument(entry.key),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesStep() {
    return AddReminderQuestionCard(
      icon: Icons.notes_rounded,
      iconColor: AppColors.primary,
      heading: 'Anything else you\'d like me to remember?',
      subtitle: 'Optional notes for future reference.',
      child: AddReminderInputShell(
        child: TextFormField(
          controller: _notesController,
          maxLines: 4,
          minLines: 3,
          textCapitalization: TextCapitalization.sentences,
          style: AddReminderStyles.input.copyWith(height: 1.45),
          decoration: AddReminderFieldDecoration.field(
            hint: 'Add notes (optional)',
          ),
        ),
      ),
    );
  }

  Widget _buildReviewStep() {
    final dateLabel = _renewalDate == null
        ? '—'
        : RenewalDateUtils.formatDisplayDate(_renewalDate!);

    return AddReminderReviewCards(
      sections: [
        AddReminderReviewSection(
          title: 'Reminder',
          editStep: _activeSteps.indexOf(AddReminderStepId.title),
          lines: [
            ('Title', _titleController.text.trim().isEmpty ? '—' : _titleController.text.trim()),
            ('Category', _categoryLabel),
            ('Importance', _priority.label),
            ('Alert Style', _alertStyle.dropdownLabel),
          ],
        ),
        AddReminderReviewSection(
          title: 'Schedule',
          editStep: _activeSteps.indexOf(AddReminderStepId.eventDate),
          lines: [
            ('Date', dateLabel),
            if (_workflowType != ReminderWorkflowType.oneTime)
              ('Repeats', _recurrenceSummary),
            if (_workflowType != ReminderWorkflowType.recurring)
              ('Reminders', _scheduleSummary),
            ('Time', TimeOfDay(hour: _reminderHour, minute: _reminderMinute).format(context)),
          ],
        ),
        AddReminderReviewSection(
          title: 'Payment',
          editStep: _activeSteps.indexOf(AddReminderStepId.paymentToggle),
          lines: [
            ('Amount', _paymentRequired ? _paymentSummary : 'No payment'),
          ],
        ),
        AddReminderReviewSection(
          title: 'Documents',
          editStep: _activeSteps.indexOf(AddReminderStepId.documents),
          lines: [
            ('Attached', _documentsSummary),
          ],
        ),
        AddReminderReviewSection(
          title: 'Notes',
          editStep: _activeSteps.indexOf(AddReminderStepId.notes),
          lines: [
            ('Notes', _notesSummary),
          ],
        ),
      ],
      onEdit: (stepIndex) => setState(() {
        _slideDirection = stepIndex < _stepIndex ? -1 : 1;
        _stepIndex = stepIndex.clamp(0, _activeSteps.length - 1);
      }),
    );
  }
}

class _RadioChoice extends StatelessWidget {
  const _RadioChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : RenewWisePalette.textCaption,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: AddReminderStyles.input)),
          ],
        ),
      ),
    );
  }
}

class _AttachedDocumentRow extends StatelessWidget {
  const _AttachedDocumentRow({
    required this.document,
    required this.onView,
    required this.onReplace,
    required this.onRemove,
  });

  final EventDocument document;
  final VoidCallback onView;
  final VoidCallback onReplace;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: RenewWisePalette.brandSoftStart.withAlpha(90),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withAlpha(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              document.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AddReminderStyles.input.copyWith(fontSize: 13),
            ),
          ),
          TextButton(onPressed: onView, child: const Text('View')),
          TextButton(onPressed: onReplace, child: const Text('Replace')),
          TextButton(onPressed: onRemove, child: const Text('Remove')),
        ],
      ),
    );
  }
}
