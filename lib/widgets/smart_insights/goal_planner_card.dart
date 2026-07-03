import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:renew_wise/models/goal_planner_models.dart';
import 'package:renew_wise/models/renewal_currency.dart';
import 'package:renew_wise/services/goal_planner_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/utils/goal_planner_engine.dart';
import 'package:renew_wise/utils/empty_state_guidance.dart';
import 'package:renew_wise/widgets/common/app_feedback.dart';
import 'package:renew_wise/widgets/common/renew_wise_primary_button.dart';

class GoalPlannerSection extends StatefulWidget {
  const GoalPlannerSection({
    super.key,
    required this.renewalService,
    required this.goalPlannerService,
    required this.currency,
  });

  final RenewalService renewalService;
  final GoalPlannerService goalPlannerService;
  final RenewalCurrency currency;

  @override
  State<GoalPlannerSection> createState() => _GoalPlannerSectionState();
}

class _GoalPlannerSectionState extends State<GoalPlannerSection> {
  final _goalNameController = TextEditingController();
  final _goalAmountController = TextEditingController();
  final _incomeController = TextEditingController();

  int? _targetYear;
  int? _targetMonth;
  GoalIncomeType _incomeType = GoalIncomeType.sameEveryMonth;
  GoalPlanResult? _plan;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _hydrateFromService();
  }

  bool get _isIncomeConfigured {
    if (_incomeType == GoalIncomeType.sameEveryMonth) {
      final income = double.tryParse(_incomeController.text.trim());
      if (income != null && income > 0) return true;
      final stored = widget.goalPlannerService.settings.defaultMonthlyIncome;
      return stored != null && stored > 0;
    }
    final now = DateTime.now();
    return !widget.goalPlannerService.needsIncomeForMonth(now.year, now.month);
  }

  Future<void> _onSetMonthlyIncomePressed() async {
    if (_incomeType == GoalIncomeType.enterEachMonth) {
      final now = DateTime.now();
      await _promptMonthlyIncome(now.year, now.month);
      return;
    }
    await _promptDefaultMonthlyIncome();
  }

  Future<void> _promptDefaultMonthlyIncome() async {
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => _MonthlyIncomeDialog(
        title: 'Monthly Income',
        initialText: _incomeController.text.trim(),
        currency: widget.currency,
        hintText: 'Monthly income (${widget.currency.symbol})',
      ),
    );
    if (amount != null && mounted) {
      _incomeController.text = amount.toStringAsFixed(0);
      await _persist();
      setState(() {});
    }
  }

  void _hydrateFromService() {
    final s = widget.goalPlannerService.settings;
    _goalNameController.text = s.goalName ?? '';
    if (s.goalAmount != null) {
      _goalAmountController.text = s.goalAmount!.toStringAsFixed(0);
    }
    if (s.defaultMonthlyIncome != null) {
      _incomeController.text = s.defaultMonthlyIncome!.toStringAsFixed(0);
    }
    _targetYear = s.targetYear;
    _targetMonth = s.targetMonth;
    _incomeType = s.incomeType;
    if (s.planGenerated && s.goalAmount != null && s.targetYear != null) {
      _regeneratePlan(showErrors: false);
    }
  }

  @override
  void dispose() {
    _goalNameController.dispose();
    _goalAmountController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  GoalPlannerSettings _buildSettings({bool planGenerated = false}) {
    final goalAmount = double.tryParse(_goalAmountController.text.trim());
    final income = double.tryParse(_incomeController.text.trim());
    return GoalPlannerSettings(
      goalName: _goalNameController.text.trim().isEmpty
          ? null
          : _goalNameController.text.trim(),
      goalAmount: goalAmount,
      targetYear: _targetYear,
      targetMonth: _targetMonth,
      defaultMonthlyIncome: income,
      incomeType: _incomeType,
      monthlyIncomes: widget.goalPlannerService.settings.monthlyIncomes,
      planGenerated: planGenerated,
    );
  }

  Future<void> _persist({bool planGenerated = false}) async {
    await widget.goalPlannerService.saveSettings(
      _buildSettings(planGenerated: planGenerated),
    );
  }

  Future<void> _pickTargetMonth() async {
    final now = DateTime.now();
    final initial = _targetYear != null && _targetMonth != null
        ? DateTime(_targetYear!, _targetMonth!, 1)
        : DateTime(now.year, now.month + 1, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, 1),
      lastDate: DateTime(now.year + 15, 12, 31),
      helpText: 'Select target month',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          datePickerTheme: DatePickerThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _targetYear = picked.year;
        _targetMonth = picked.month;
        _validationError = null;
      });
      await _persist();
    }
  }

  Future<bool> _promptMonthlyIncome(int year, int month) async {
    final label = GoalPlannerValidationUtils.formatTargetMonth(year, month);

    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => _MonthlyIncomeDialog(
        title: 'Income for $label',
        initialText: _incomeController.text.trim(),
        currency: widget.currency,
        hintText: 'Monthly income (${widget.currency.symbol})',
      ),
    );
    if (amount != null) {
      await widget.goalPlannerService.setMonthlyIncome(year, month, amount);
      if (mounted) setState(() {});
      return true;
    }
    return false;
  }

  Future<bool> _ensureMonthlyIncomes(GoalPlannerSettings settings) async {
    if (settings.incomeType != GoalIncomeType.enterEachMonth) return true;
    if (settings.targetYear == null || settings.targetMonth == null) {
      return false;
    }

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(settings.targetYear!, settings.targetMonth!, 1);
    var y = start.year;
    var m = start.month;

    while (y < end.year || (y == end.year && m <= end.month)) {
      if (widget.goalPlannerService.needsIncomeForMonth(y, m)) {
        final ok = await _promptMonthlyIncome(y, m);
        if (!ok) return false;
      }
      m++;
      if (m > 12) {
        m = 1;
        y++;
      }
    }
    return true;
  }

  Future<void> _generatePlan() async {
    final settings = _buildSettings();
    final validation = GoalPlannerValidationUtils.validateInputs(
      settings: settings,
      now: DateTime.now(),
    );
    if (!validation.isValid) {
      setState(() {
        _validationError = validation.error;
        _plan = null;
      });
      return;
    }

    if (!await _ensureMonthlyIncomes(settings)) return;

    final refreshed = widget.goalPlannerService.settings;
    final plan = GoalPlannerEngine.compute(
      settings: refreshed.copyWith(
        goalName: settings.goalName,
        goalAmount: settings.goalAmount,
        targetYear: settings.targetYear,
        targetMonth: settings.targetMonth,
        defaultMonthlyIncome: settings.defaultMonthlyIncome,
        incomeType: settings.incomeType,
      ),
      renewals: widget.renewalService.renewals,
      now: DateTime.now(),
    );

    await _persist(planGenerated: true);
    if (!mounted) return;
    setState(() {
      _validationError = null;
      _plan = plan;
    });
  }

  void _regeneratePlan({required bool showErrors}) {
    final settings = _buildSettings(planGenerated: true);
    final validation = GoalPlannerValidationUtils.validateInputs(
      settings: settings,
      now: DateTime.now(),
    );
    if (!validation.isValid) {
      if (showErrors) {
        setState(() => _validationError = validation.error);
      }
      return;
    }
    setState(() {
      _plan = GoalPlannerEngine.compute(
        settings: settings.copyWith(
          monthlyIncomes: widget.goalPlannerService.settings.monthlyIncomes,
        ),
        renewals: widget.renewalService.renewals,
        now: DateTime.now(),
      );
    });
  }

  GoalPlanResult? _displayPlan() {
    if (_plan == null || !widget.goalPlannerService.settings.planGenerated) {
      return _plan;
    }
    final settings = _buildSettings(planGenerated: true);
    final validation = GoalPlannerValidationUtils.validateInputs(
      settings: settings,
      now: DateTime.now(),
    );
    if (!validation.isValid) return _plan;
    return GoalPlannerEngine.compute(
      settings: settings.copyWith(
        monthlyIncomes: widget.goalPlannerService.settings.monthlyIncomes,
      ),
      renewals: widget.renewalService.renewals,
      now: DateTime.now(),
    );
  }

  String get _targetMonthLabel {
    if (_targetYear == null || _targetMonth == null) return 'Select month & year';
    return GoalPlannerValidationUtils.formatTargetMonth(
      _targetYear!,
      _targetMonth!,
    );
  }

  String _fmt(double value) =>
      GoalPlannerValidationUtils.formatMoney(widget.currency, value);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.renewalService,
        widget.goalPlannerService,
      ]),
      builder: (context, _) {
        final displayPlan = _displayPlan();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_isIncomeConfigured) ...[
              _IncomeNotConfiguredCard(onSetIncome: _onSetMonthlyIncomePressed),
              const SizedBox(height: 16),
            ],
            _GoalPlannerField(
              label: 'Goal Name',
              optional: true,
              child: TextField(
                controller: _goalNameController,
                textCapitalization: TextCapitalization.words,
                style: _fieldTextStyle,
                decoration: _fieldDecoration(
                  hint: 'Car, Vacation, Emergency Fund…',
                ),
                onChanged: (_) => _persist(),
              ),
            ),
            const SizedBox(height: 10),
            _GoalPlannerField(
              label: 'Goal Amount',
              child: TextField(
                controller: _goalAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                style: _fieldTextStyle,
                decoration: _fieldDecoration(
                  hint: '${widget.currency.symbol} amount',
                ),
                onChanged: (_) => _persist(),
              ),
            ),
            const SizedBox(height: 10),
            _GoalPlannerField(
              label: 'Target Month',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _pickTargetMonth,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: InputDecorator(
                    decoration: _fieldDecoration(
                      suffixIcon: Icon(
                        Icons.calendar_today_outlined,
                        size: AppIconSize.sm,
                        color: AppColors.primary,
                      ),
                    ),
                    child: Text(
                      _targetMonthLabel,
                      style: _fieldTextStyle.copyWith(
                        color: _targetYear == null
                            ? RenewWisePalette.textCaption
                            : RenewWisePalette.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_isIncomeConfigured &&
                _incomeType == GoalIncomeType.sameEveryMonth) ...[
              _GoalPlannerField(
                label: 'Monthly Income',
                child: TextField(
                  controller: _incomeController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  style: _fieldTextStyle,
                  decoration: _fieldDecoration(
                    hint: '${widget.currency.symbol} amount',
                  ),
                  onChanged: (_) => _persist(),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              'Income Type',
              style: RenewWiseTypography.caption.copyWith(
                color: RenewWisePalette.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            _GoalRadioTile(
              label: GoalIncomeType.sameEveryMonth.label,
              selected: _incomeType == GoalIncomeType.sameEveryMonth,
              onTap: () async {
                setState(() => _incomeType = GoalIncomeType.sameEveryMonth);
                await _persist();
              },
            ),
            const SizedBox(height: 8),
            _GoalRadioTile(
              label: GoalIncomeType.enterEachMonth.label,
              selected: _incomeType == GoalIncomeType.enterEachMonth,
              onTap: () async {
                setState(() => _incomeType = GoalIncomeType.enterEachMonth);
                await _persist();
              },
            ),
            if (_validationError != null) ...[
              const SizedBox(height: 12),
              Text(
                _validationError!,
                style: RenewWiseTypography.caption.copyWith(
                  color: AppColors.critical,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _generatePlan,
                icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                label: const Text('Generate Plan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: AppColors.primary.withAlpha(80)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  textStyle: RenewWiseTypography.actionLink.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            if (displayPlan != null) ...[
              const SizedBox(height: 20),
              _GoalProgressSection(plan: displayPlan, format: _fmt),
              const SizedBox(height: 16),
              _GoalFeasibilityBanner(plan: displayPlan),
              const SizedBox(height: 16),
              Text('Goal Roadmap', style: RenewWiseTypography.sectionTitle),
              const SizedBox(height: 10),
              ...displayPlan.months.map(
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _GoalRoadmapRow(row: row, format: _fmt),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  InputDecoration _fieldDecoration({
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: _fieldTextStyle.copyWith(color: RenewWisePalette.textCaption),
      border: InputBorder.none,
      isDense: true,
      contentPadding: EdgeInsets.zero,
      suffixIcon: suffixIcon,
    );
  }

  TextStyle get _fieldTextStyle => RenewWiseTypography.tileEventCount.copyWith(
        fontWeight: FontWeight.w600,
        color: RenewWisePalette.textPrimary,
      );
}

class _IncomeNotConfiguredCard extends StatelessWidget {
  const _IncomeNotConfiguredCard({required this.onSetIncome});

  final VoidCallback onSetIncome;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            RenewWisePalette.greenSoftStart,
            RenewWisePalette.greenSoftEnd.withAlpha(180),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: RenewWisePalette.green.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: RenewWisePalette.green,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly income not configured',
                      style: RenewWiseTypography.tileEventCount.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      EmptyStateGuidance.goalPlannerIncome,
                      style: RenewWiseTypography.caption.copyWith(
                        color: RenewWisePalette.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: RenewWisePrimaryButton(
              label: 'Set Monthly Income',
              onPressed: onSetIncome,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyIncomeDialog extends StatefulWidget {
  const _MonthlyIncomeDialog({
    required this.title,
    required this.initialText,
    required this.currency,
    required this.hintText,
  });

  final String title;
  final String initialText;
  final RenewalCurrency currency;
  final String hintText;

  @override
  State<_MonthlyIncomeDialog> createState() => _MonthlyIncomeDialogState();
}

class _MonthlyIncomeDialogState extends State<_MonthlyIncomeDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final parsed = double.tryParse(_controller.text.trim());
    if (parsed == null || parsed <= 0) {
      AppFeedback.info(context, 'Enter an income greater than zero');
      return;
    }
    Navigator.pop(context, parsed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.dialogBorder),
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        ],
        decoration: InputDecoration(hintText: widget.hintText),
        autofocus: true,
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _GoalPlannerField extends StatelessWidget {
  const _GoalPlannerField({
    required this.label,
    required this.child,
    this.optional = false,
  });

  final String label;
  final Widget child;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: RenewWiseTypography.caption.copyWith(
                color: RenewWisePalette.textSecondary,
              ),
            ),
            if (optional) ...[
              const SizedBox(width: 6),
              Text(
                'Optional',
                style: RenewWiseTypography.caption.copyWith(
                  color: RenewWisePalette.textCaption,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: RenewWisePalette.cardSurface.withAlpha(180),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _GoalRadioTile extends StatelessWidget {
  const _GoalRadioTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.primary : const Color(0xFFCBD5E1),
                    width: 2,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: RenewWiseTypography.tileEventCount.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? RenewWisePalette.textPrimary
                        : RenewWisePalette.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalProgressSection extends StatelessWidget {
  const _GoalProgressSection({required this.plan, required this.format});

  final GoalPlanResult plan;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RenewWisePalette.cardSurface.withAlpha(200),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GoalProgressRow(label: 'Goal Amount', value: format(plan.goalAmount)),
          const SizedBox(height: 8),
          _GoalProgressRow(
            label: 'Estimated Savings',
            value: format(plan.estimatedSavings),
          ),
          const SizedBox(height: 8),
          _GoalProgressRow(
            label: 'Remaining to Goal',
            value: format(plan.remainingToGoal),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: plan.completionPercent / 100,
              minHeight: 10,
              backgroundColor: const Color(0xFFE2E8F0),
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${plan.completionPercent.toStringAsFixed(0)}% complete',
            style: RenewWiseTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalProgressRow extends StatelessWidget {
  const _GoalProgressRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: RenewWiseTypography.secondary),
        ),
        Text(
          value,
          style: RenewWiseTypography.tileEventCount.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _GoalFeasibilityBanner extends StatelessWidget {
  const _GoalFeasibilityBanner({required this.plan});

  final GoalPlanResult plan;

  @override
  Widget build(BuildContext context) {
    if (plan.isAchievable) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: RenewWisePalette.greenSoftStart,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: RenewWisePalette.green.withAlpha(60)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_rounded, color: RenewWisePalette.green),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'You are on track to achieve your goal.',
                style: RenewWiseTypography.tileEventCount.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF15803D),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final suggestions = <String>[
      if (plan.optionalExpenseReminders.isNotEmpty)
        'Review optional expenses (${plan.optionalExpenseReminders.map((r) => r.title).take(3).join(', ')})',
      'Extend the target month',
      'Increase monthly income',
      'Review reminder priorities',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RenewWisePalette.orangeSoftStart,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: RenewWisePalette.orange.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: RenewWisePalette.orange),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your goal cannot be achieved based on your current income and planned expenses.',
                  style: RenewWiseTypography.tileEventCount.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFC2410C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...suggestions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $s', style: RenewWiseTypography.caption),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalRoadmapRow extends StatelessWidget {
  const _GoalRoadmapRow({required this.row, required this.format});

  final GoalPlanMonthRow row;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (row.status) {
      GoalMonthStatus.onTrack => RenewWisePalette.green,
      GoalMonthStatus.heavyExpense => RenewWisePalette.orange,
      GoalMonthStatus.insufficient => AppColors.critical,
      GoalMonthStatus.missingIncome => RenewWisePalette.textCaption,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RenewWisePalette.cardSurface.withAlpha(200),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                row.label,
                style: RenewWiseTypography.tileEventCount.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                row.status.label,
                style: RenewWiseTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _GoalRoadmapMetric(label: 'Income', value: format(row.income)),
          _GoalRoadmapMetric(
            label: 'Planned Expenses',
            value: format(row.plannedExpenses),
          ),
          _GoalRoadmapMetric(
            label: 'Suggested Savings',
            value: format(row.suggestedSavings),
          ),
          _GoalRoadmapMetric(
            label: 'Remaining',
            value: format(row.remainingAmount),
          ),
        ],
      ),
    );
  }
}

class _GoalRoadmapMetric extends StatelessWidget {
  const _GoalRoadmapMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: RenewWiseTypography.caption),
          ),
          Text(
            value,
            style: RenewWiseTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: RenewWisePalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
