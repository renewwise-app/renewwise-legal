import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:renew_wise/models/expense_record.dart';
import 'package:renew_wise/models/renewal_category.dart';
import 'package:renew_wise/models/renewal_currency.dart';
import 'package:renew_wise/services/expense_service.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/utils/empty_state_guidance.dart';
import 'package:renew_wise/utils/date_utils.dart';
import 'package:renew_wise/widgets/common/app_feedback.dart';

class ExpenseTrackingSection extends StatefulWidget {
  const ExpenseTrackingSection({
    super.key,
    required this.expenseService,
    required this.currency,
    this.hideChartPlaceholder = false,
  });

  final ExpenseService expenseService;
  final RenewalCurrency currency;
  final bool hideChartPlaceholder;

  @override
  State<ExpenseTrackingSection> createState() => _ExpenseTrackingSectionState();
}

class _ExpenseTrackingSectionState extends State<ExpenseTrackingSection> {
  ExpenseFilterState _filter = const ExpenseFilterState();

  String _fmt(double value) => widget.currency.formatAmount(value);

  Future<void> _openAddExpense({ExpenseRecord? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: _ExpenseFormSheet(
          currency: widget.currency,
          existing: existing,
        ),
      ),
    );
    if (saved == true && mounted) {
      AppFeedback.saved(context);
    }
  }

  Future<void> _confirmDelete(ExpenseRecord expense) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.dialogBorder),
        title: const Text('Delete expense?'),
        content: Text(
          'Remove ${expense.category.label} · ${_fmt(expense.amount)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.critical),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.expenseService.deleteExpense(expense.id);
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final start = await showDatePicker(
      context: context,
      initialDate: _filter.customStart ?? now.subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'Start date',
    );
    if (start == null || !mounted) return;
    final end = await showDatePicker(
      context: context,
      initialDate: _filter.customEnd ?? now,
      firstDate: start,
      lastDate: now,
      helpText: 'End date',
    );
    if (end == null || !mounted) return;
    setState(() {
      _filter = _filter.copyWith(
        dateFilter: ExpenseDateFilter.customRange,
        customStart: start,
        customEnd: end,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.expenseService,
      builder: (context, _) {
        final filtered = widget.expenseService.filtered(_filter);
        final summary = widget.expenseService.summarize(filtered);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.hideChartPlaceholder) ...[
              const _ExpenseChartPlaceholder(
                label: 'Pie Chart',
                height: 160,
                icon: Icons.donut_large_outlined,
              ),
              const SizedBox(height: 16),
            ],
            Text('Summary', style: RenewWiseTypography.sectionTitle),
            const SizedBox(height: 10),
            _SummaryRow(label: 'Total Expenses', value: _fmt(summary.total)),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Number of Expenses',
              value: '${summary.count}',
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Largest Expense',
              value: summary.count == 0 ? '—' : _fmt(summary.largest),
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Average Expense',
              value: summary.count == 0 ? '—' : _fmt(summary.average),
            ),
            const SizedBox(height: 16),
            Text('Filters', style: RenewWiseTypography.sectionTitle),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ExpenseDateFilter.values.map((f) {
                return FilterChip(
                  label: Text(f.label),
                  selected: _filter.dateFilter == f,
                  onSelected: (_) async {
                    if (f == ExpenseDateFilter.customRange) {
                      await _pickCustomRange();
                    } else {
                      setState(() => _filter = _filter.copyWith(dateFilter: f));
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('All Categories'),
                  selected: _filter.category == null,
                  onSelected: (_) =>
                      setState(() => _filter = _filter.copyWith(clearCategory: true)),
                ),
                ...RenewalCategory.values.map(
                  (c) => FilterChip(
                    label: Text(c.label),
                    selected: _filter.category == c,
                    onSelected: (_) => setState(
                      () => _filter = _filter.copyWith(category: c),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('All Sources'),
                  selected: _filter.source == null,
                  onSelected: (_) =>
                      setState(() => _filter = _filter.copyWith(clearSource: true)),
                ),
                ...ExpenseSource.values.map(
                  (s) => FilterChip(
                    label: Text(s.label),
                    selected: _filter.source == s,
                    onSelected: (_) =>
                        setState(() => _filter = _filter.copyWith(source: s)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Expenses',
                    style: RenewWiseTypography.sectionTitle,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _openAddExpense(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Expense'),
                ),
              ],
            ),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: widget.expenseService.expenses.isEmpty
                    ? Text(
                        EmptyStateGuidance.spendingAnalysis,
                        style: RenewWiseTypography.secondary.copyWith(
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      )
                    : Text(
                        'No expenses match these filters.',
                        style: RenewWiseTypography.secondary,
                      ),
              )
            else
              ...filtered.map(
                (expense) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ExpenseListTile(
                    expense: expense,
                    amountLabel: _fmt(expense.amount),
                    onEdit: () => _openAddExpense(existing: expense),
                    onDelete: () => _confirmDelete(expense),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openAddExpense(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Expense'),
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
          ],
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: RenewWiseTypography.secondary)),
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

class _ExpenseListTile extends StatelessWidget {
  const _ExpenseListTile({
    required this.expense,
    required this.amountLabel,
    required this.onEdit,
    required this.onDelete,
  });

  final ExpenseRecord expense;
  final String amountLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RenewWisePalette.cardSurface.withAlpha(200),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(expense.category.icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.category.label,
                  style: RenewWiseTypography.tileEventCount.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${RenewalDateUtils.formatDisplayDate(expense.date)} · ${expense.source.label}',
                  style: RenewWiseTypography.caption,
                ),
                if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(expense.notes!, style: RenewWiseTypography.caption),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amountLabel,
                style: RenewWiseTypography.tileEventCount.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline, color: AppColors.critical),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpenseFormSheet extends StatefulWidget {
  const _ExpenseFormSheet({
    required this.currency,
    this.existing,
  });

  final RenewalCurrency currency;
  final ExpenseRecord? existing;

  @override
  State<_ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<_ExpenseFormSheet> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  RenewalCategory? _category;
  DateTime? _date;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _category = existing.category;
      _date = existing.date;
      _amountController.text = existing.amount.toStringAsFixed(
        existing.amount == existing.amount.roundToDouble() ? 0 : 2,
      );
      _notesController.text = existing.notes ?? '';
    } else {
      _date = RenewalDateUtils.dateOnly(DateTime.now());
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'Expense date',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final validation = ExpenseValidationUtils.validate(
      category: _category,
      amountText: _amountController.text,
      date: _date,
    );
    if (!validation.isValid) {
      setState(() => _error = validation.error);
      return;
    }

    final amount = double.parse(_amountController.text.trim());
    final notes = _notesController.text.trim();
    final now = DateTime.now();

    if (_isEditing) {
      await expenseService.updateExpense(
        widget.existing!.copyWith(
          category: _category!,
          amount: amount,
          date: RenewalDateUtils.dateOnly(_date!),
          notes: notes.isEmpty ? null : notes,
          clearNotes: notes.isEmpty,
        ),
      );
    } else {
      await expenseService.addExpense(
        ExpenseRecord(
          id: now.microsecondsSinceEpoch.toString(),
          category: _category!,
          amount: amount,
          date: RenewalDateUtils.dateOnly(_date!),
          source: ExpenseSource.manual,
          notes: notes.isEmpty ? null : notes,
          createdAt: now,
        ),
      );
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Edit Expense' : 'Add Expense',
              style: RenewWiseTypography.cardTitle,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<RenewalCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Expense Category'),
              items: RenewalCategory.values
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.label),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Amount (${widget.currency.symbol})',
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(
                _date == null
                    ? 'Select date'
                    : RenewalDateUtils.formatDisplayDate(_date!),
              ),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: RenewWiseTypography.caption.copyWith(
                  color: AppColors.critical,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              child: Text(_isEditing ? 'Save Changes' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseChartPlaceholder extends StatelessWidget {
  const _ExpenseChartPlaceholder({
    required this.label,
    required this.height,
    required this.icon,
  });

  final String label;
  final double height;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: RenewWisePalette.textCaption),
          const SizedBox(height: 10),
          Text(
            label,
            style: RenewWiseTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Chart Placeholder',
            style: RenewWiseTypography.caption.copyWith(
              color: RenewWisePalette.textCaption,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
