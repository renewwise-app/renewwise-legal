import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:renew_wise/models/assistant_draft.dart';
import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/renewal_priority.dart';
import 'package:renew_wise/models/renewal_status.dart';
import 'package:renew_wise/models/repeat_cycle.dart';
import 'package:renew_wise/services/assistant_draft_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/widgets/common/app_feedback.dart';
import 'package:renew_wise/utils/assistant_reminder_suggestions.dart';
import 'package:renew_wise/utils/date_utils.dart';
import 'package:renew_wise/widgets/assistant_progress.dart';
import 'package:renew_wise/widgets/assistant_success_sequence.dart';
import 'package:renew_wise/widgets/renew_wise_logo.dart';

/// Conversational event creation — one calm question at a time.
class RenewWiseAssistantScreen extends StatefulWidget {
  const RenewWiseAssistantScreen({
    super.key,
    required this.renewalService,
    required this.settingsService,
    required this.draftService,
    this.resumeDraft = false,
  });

  final RenewalService renewalService;
  final SettingsService settingsService;
  final AssistantDraftService draftService;
  final bool resumeDraft;

  static Future<void> push(
    BuildContext context, {
    required RenewalService renewalService,
    required SettingsService settingsService,
    required AssistantDraftService draftService,
    bool resumeDraft = false,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => RenewWiseAssistantScreen(
          renewalService: renewalService,
          settingsService: settingsService,
          draftService: draftService,
          resumeDraft: resumeDraft,
        ),
        transitionsBuilder: (_, anim, _, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  State<RenewWiseAssistantScreen> createState() =>
      _RenewWiseAssistantScreenState();
}

class _RenewWiseAssistantScreenState extends State<RenewWiseAssistantScreen> {
  late AssistantDraft _draft;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _customCategoryCtrl;
  late final TextEditingController _tagCtrl;

  bool _showCustomizeReminders = false;
  final Set<int> _selectedReminderDays = {};
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final existing = widget.resumeDraft ? widget.draftService.draft : null;
    _draft = existing ??
        const AssistantDraft(step: AssistantStep.welcome);
    _titleCtrl = TextEditingController(text: _draft.title);
    _amountCtrl = TextEditingController(
      text: _draft.amount?.toStringAsFixed(0) ?? '',
    );
    _notesCtrl = TextEditingController(text: _draft.notes);
    _customCategoryCtrl = TextEditingController(
      text: _draft.customCategoryName ?? '',
    );
    _tagCtrl = TextEditingController();
    _selectedReminderDays.addAll(_draft.reminderSchedule);
    _titleCtrl.addListener(() => setState(() {}));
    _amountCtrl.addListener(() => setState(() {}));
    _customCategoryCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    _customCategoryCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  int get _questionIndex {
    return switch (_draft.step) {
      AssistantStep.question1 => 0,
      AssistantStep.question2 => 1,
      AssistantStep.question3 => 2,
      AssistantStep.question4 => 3,
      AssistantStep.question5 => 4,
      AssistantStep.review => 4,
      _ => 0,
    };
  }

  Future<void> _persistDraft() async {
    await widget.draftService.saveDraft(_draft);
  }

  void _setStep(AssistantStep step) {
    setState(() => _draft = _draft.copyWith(step: step));
    unawaited(_persistDraft());
  }

  Future<bool> _confirmExit() async {
    if (!_draft.hasContent || _draft.step == AssistantStep.welcome) {
      return true;
    }
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save as Draft?'),
        content: const Text(
          'You can resume later from Continue Draft.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: const Text('Save Draft'),
          ),
        ],
      ),
    );
    if (result == 'save') {
      await _syncDraftFromControllers();
      await _persistDraft();
      return true;
    }
    if (result == 'discard') {
      await widget.draftService.clearDraft();
      return true;
    }
    return false;
  }

  Future<void> _syncDraftFromControllers() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    _draft = _draft.copyWith(
      title: _titleCtrl.text,
      amount: amount,
      clearAmount: amount == null,
      notes: _notesCtrl.text,
      reminderSchedule: _selectedReminderDays.toList()..sort((a, b) => b.compareTo(a)),
    );
  }

  void _goBack() {
    HapticFeedback.selectionClick();
    final prev = switch (_draft.step) {
      AssistantStep.question1 => AssistantStep.welcome,
      AssistantStep.question2 => AssistantStep.question1,
      AssistantStep.question3 => AssistantStep.question2,
      AssistantStep.question4 => AssistantStep.question3,
      AssistantStep.question5 => AssistantStep.question4,
      AssistantStep.review => AssistantStep.question5,
      _ => AssistantStep.welcome,
    };
    _setStep(prev);
  }

  Future<void> _goNextFromQ1() async {
    await _syncDraftFromControllers();
    if (!_draft.canContinueQuestion1) return;
    HapticFeedback.lightImpact();
    _setStep(AssistantStep.question2);
  }

  Future<void> _goNextFromQ2() async {
    await _syncDraftFromControllers();
    if (!_draft.canContinueQuestion2) return;
    HapticFeedback.lightImpact();
    final suggested = AssistantReminderSuggestions.forCategory(
      _draft.categoryOption,
    );
    _selectedReminderDays
      ..clear()
      ..addAll(suggested);
    _draft = _draft.copyWith(reminderSchedule: suggested);
    _setStep(AssistantStep.question3);
  }

  Future<void> _goNextFromQ3() async {
    _draft = _draft.copyWith(
      reminderSchedule: _selectedReminderDays.toList()
        ..sort((a, b) => b.compareTo(a)),
      customizeReminders: _showCustomizeReminders,
    );
    await _persistDraft();
    HapticFeedback.lightImpact();
    _setStep(AssistantStep.question4);
  }

  Future<void> _goNextFromQ4() async {
    HapticFeedback.lightImpact();
    _setStep(AssistantStep.question5);
  }

  Future<void> _goNextFromQ5() async {
    await _syncDraftFromControllers();
    HapticFeedback.lightImpact();
    _setStep(AssistantStep.review);
  }

  Future<void> _saveEvent() async {
    await _syncDraftFromControllers();
    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    final cat = _draft.categoryOption!;
    final notes = _buildFinalNotes();

    final renewal = Renewal(
      id: now.microsecondsSinceEpoch.toString(),
      title: _draft.title.trim(),
      category: cat.category,
      customEventType: cat.customEventType,
      renewalDate: _draft.renewalDate!,
      paymentRequired: _draft.amount != null && _draft.amount! > 0,
      amount: _draft.amount,
      currency: widget.settingsService.defaultCurrency,
      priority: _draft.priority,
      status: RenewalStatus.upcoming,
      repeatCycle: RepeatCycle.oneTime,
      reminderSchedule: List<int>.from(_draft.reminderSchedule)
        ..sort((a, b) => b.compareTo(a)),
      customReminderDates: _draft.customReminderDates,
      reminderTimeMinutes: _draft.reminderTimeMinutes,
      notes: notes.isEmpty ? null : notes,
      createdAt: now,
      updatedAt: now,
    );

    widget.renewalService.addRenewal(renewal);
    await widget.draftService.clearDraft();
    if (mounted) _setStep(AssistantStep.success);
  }

  String _buildFinalNotes() {
    final parts = <String>[];
    if (_draft.notes.trim().isNotEmpty) parts.add(_draft.notes.trim());
    if (_draft.tags.isNotEmpty) {
      parts.add('Tags: ${_draft.tags.join(', ')}');
    }
    if (_draft.attachments.isNotEmpty) {
      parts.add(
        'Attachments:\n${_draft.attachments.map((a) => '• ${a.name}').join('\n')}',
      );
    }
    return parts.join('\n\n');
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    await _addAttachment(picked.path, p.basename(picked.path), true);
  }

  Future<void> _pickFile() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    await _addAttachment(picked.path, p.basename(picked.path), true);
  }

  Future<void> _pickMultipleFromGallery() async {
    final picked = await _imagePicker.pickMultiImage(imageQuality: 85);
    for (final file in picked) {
      await _addAttachment(file.path, p.basename(file.path), true);
    }
  }

  Future<void> _addAttachment(String path, String name, bool isImage) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dest = File(p.join(dir.path, 'assistant_${DateTime.now().millisecondsSinceEpoch}_$name'));
      await File(path).copy(dest.path);
      HapticFeedback.lightImpact();
      setState(() {
        _draft = _draft.copyWith(
          attachments: [
            ..._draft.attachments,
            AssistantAttachment(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              path: dest.path,
              name: name,
              isImage: isImage,
            ),
          ],
        );
      });
      await _persistDraft();
    } catch (_) {
      if (mounted) {
        AppFeedback.error(context, 'Could not attach that file. Please try again.');
      }
    }
  }

  void _removeAttachment(String id) {
    setState(() {
      _draft = _draft.copyWith(
        attachments: _draft.attachments.where((a) => a.id != id).toList(),
      );
    });
    unawaited(_persistDraft());
  }

  @override
  Widget build(BuildContext context) {
    if (_draft.step == AssistantStep.success) {
      return AssistantSuccessSequence(
        onComplete: () {
          if (mounted) Navigator.of(context).pop();
        },
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_draft.step == AssistantStep.welcome) {
          if (context.mounted) Navigator.of(context).pop();
          return;
        }
        if (_draft.step.index <= AssistantStep.question1.index) {
          final leave = await _confirmExit();
          if (leave && context.mounted) Navigator.of(context).pop();
          return;
        }
        _goBack();
      },
      child: Scaffold(
        appBar: _draft.step == AssistantStep.welcome
            ? null
            : AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () async {
                    if (_draft.step == AssistantStep.question1) {
                      final leave = await _confirmExit();
                      if (leave && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    } else {
                      _goBack();
                    }
                  },
                ),
                title: const Text('RenewWise Assistant'),
              ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                children: [
                  if (_draft.step != AssistantStep.welcome &&
                      _draft.step != AssistantStep.review)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      child: AssistantProgressBar(
                        activeIndex: _questionIndex,
                        messageIndex: _questionIndex,
                      ),
                    ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 380),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: KeyedSubtree(
                        key: ValueKey(_draft.step),
                        child: _buildStep(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    return switch (_draft.step) {
      AssistantStep.welcome => _buildWelcome(),
      AssistantStep.question1 => _buildQuestion1(),
      AssistantStep.question2 => _buildQuestion2(),
      AssistantStep.question3 => _buildQuestion3(),
      AssistantStep.question4 => _buildQuestion4(),
      AssistantStep.question5 => _buildQuestion5(),
      AssistantStep.review => _buildReview(),
      AssistantStep.success => const SizedBox.shrink(),
    };
  }

  Widget _buildWelcome() {
    final name = widget.settingsService.userName.trim();
    final greeting = name.isEmpty ? 'Hi there 👋' : 'Hi, $name 👋';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const RenewWiseLogo(size: 72),
          const SizedBox(height: 28),
          Text(
            greeting,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "Let's make sure you never have to worry about this again.",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          Icon(
            Icons.self_improvement_outlined,
            size: 100,
            color: AppColors.primary.withAlpha(100),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _setStep(AssistantStep.question1),
              child: const Text("Let's Begin"),
            ),
          ),
          if (widget.draftService.hasDraft) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  final d = widget.draftService.draft!;
                  _draft = d;
                  _titleCtrl.text = d.title;
                  _amountCtrl.text = d.amount?.toStringAsFixed(0) ?? '';
                  _notesCtrl.text = d.notes;
                  _selectedReminderDays
                    ..clear()
                    ..addAll(d.reminderSchedule);
                  _showCustomizeReminders = d.customizeReminders;
                  final step = d.step == AssistantStep.welcome
                      ? AssistantStep.question1
                      : d.step;
                  _setStep(step);
                },
                child: const Text('Continue Draft'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestion1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What would you like me to remember?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleCtrl,
            style: Theme.of(context).textTheme.titleLarge,
            decoration: InputDecoration(
              hintText: 'e.g. Passport renewal',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _draft.categoryId,
            decoration: InputDecoration(
              labelText: 'Category',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            items: AssistantCategories.all
                .map(
                  (c) => DropdownMenuItem(
                    value: c.id,
                    child: Row(
                      children: [
                        Icon(c.icon, size: 18),
                        const SizedBox(width: 8),
                        Text(c.label),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (id) {
              if (id == null) return;
              HapticFeedback.selectionClick();
              setState(() {
                _draft = _draft.copyWith(
                  categoryId: id,
                  clearCustomCategory: id != 'other',
                );
                if (id != 'other') _customCategoryCtrl.clear();
              });
            },
          ),
          if (_draft.categoryId == 'other') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customCategoryCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Custom category name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              onChanged: (v) {
                setState(() {
                  _draft = _draft.copyWith(
                    customCategoryName: v.trim().isEmpty ? null : v.trim(),
                    categoryId: 'other',
                    clearCustomCategory: false,
                  );
                });
              },
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _titleCtrl.text.trim().isNotEmpty &&
                      _draft.categoryOption != null &&
                      (_draft.categoryId != 'other' ||
                          _customCategoryCtrl.text.trim().isNotEmpty)
                  ? _goNextFromQ1
                  : null,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion2() {
    final date = _draft.renewalDate ?? DateTime.now();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'When does it happen?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 16),
          CalendarDatePicker(
            initialDate: date,
            firstDate: DateTime.now().subtract(const Duration(days: 1)),
            lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
            onDateChanged: (d) {
              HapticFeedback.selectionClick();
              setState(() => _draft = _draft.copyWith(renewalDate: d));
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Optional',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Amount',
              prefixText: '${widget.settingsService.defaultCurrency.symbol} ',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Priority',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: RenewalPriority.values.map((p) {
              final selected = _draft.priority == p;
              return ChoiceChip(
                label: Text(p.label.toUpperCase()),
                selected: selected,
                selectedColor: p.color.withAlpha(40),
                onSelected: (_) {
                  setState(() => _draft = _draft.copyWith(priority: p));
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _draft.renewalDate != null ? _goNextFromQ2 : null,
              child: const Text('Looks Good'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion3() {
    const options = [90, 60, 30, 15, 7, 3, 1];
    final label = AssistantReminderSuggestions.labelFor(_draft.categoryOption);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'When should I remind you?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          if (!_showCustomizeReminders) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedReminderDays.map((d) {
                return Chip(
                  label: Text('$d days before'),
                  backgroundColor: AppColors.primary.withAlpha(24),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _goNextFromQ3,
                    child: const Text('Accept Suggestions'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () =>
                    setState(() => _showCustomizeReminders = true),
                child: const Text('Customize'),
              ),
            ),
          ] else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((d) {
                final selected = _selectedReminderDays.contains(d);
                return FilterChip(
                  label: Text('$d days'),
                  selected: selected,
                  onSelected: (v) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (v) {
                        _selectedReminderDays.add(d);
                      } else {
                        _selectedReminderDays.remove(d);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await RenewalDateUtils.pickDate(
                  context,
                  helpText: 'Custom reminder date',
                );
                if (picked == null) return;
                setState(() {
                  _draft = _draft.copyWith(
                    customReminderDates: [..._draft.customReminderDates, picked],
                  );
                });
              },
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('Add custom date'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: _draft.reminderTimeMinutes ~/ 60,
                    minute: _draft.reminderTimeMinutes % 60,
                  ),
                );
                if (picked == null) return;
                setState(() {
                  _draft = _draft.copyWith(
                    reminderTimeMinutes: picked.hour * 60 + picked.minute,
                  );
                });
              },
              icon: const Icon(Icons.access_time_rounded),
              label: const Text('Reminder time'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    _selectedReminderDays.isNotEmpty ? _goNextFromQ3 : null,
                child: const Text('Continue'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestion4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Would you like to attach anything?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _AttachButton(
                icon: Icons.photo_camera_outlined,
                label: 'Take Photo',
                onTap: () => _pickImage(ImageSource.camera),
              ),
              _AttachButton(
                icon: Icons.insert_drive_file_outlined,
                label: 'Choose File',
                onTap: _pickFile,
              ),
              _AttachButton(
                icon: Icons.photo_library_outlined,
                label: 'Gallery',
                onTap: _pickMultipleFromGallery,
              ),
            ],
          ),
          if (_draft.attachments.isNotEmpty) ...[
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _draft.attachments.map((a) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                      child: a.isImage && !a.path.startsWith('demo://')
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(a.path),
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.image_outlined,
                                ),
                              ),
                            )
                          : Icon(
                              a.isImage
                                  ? Icons.image_outlined
                                  : Icons.description_outlined,
                            ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.critical,
                          minimumSize: const Size(24, 24),
                          padding: EdgeInsets.zero,
                        ),
                        iconSize: 14,
                        onPressed: () => _removeAttachment(a.id),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _goNextFromQ4,
              child: const Text('Skip'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _goNextFromQ4,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion5() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Anything else you'd like me to know?",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesCtrl,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Policy number…\nRenew through XYZ…',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tagCtrl,
            decoration: InputDecoration(
              hintText: 'Add a tag',
              suffixIcon: IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  final tag = _tagCtrl.text.trim();
                  if (tag.isEmpty) return;
                  setState(() {
                    _draft = _draft.copyWith(tags: [..._draft.tags, tag]);
                    _tagCtrl.clear();
                  });
                },
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_draft.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _draft.tags.map((t) {
                return InputChip(
                  label: Text(t),
                  onDeleted: () {
                    setState(() {
                      _draft = _draft.copyWith(
                        tags: _draft.tags.where((x) => x != t).toList(),
                      );
                    });
                  },
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _goNextFromQ5,
              child: const Text('Almost Done'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReview() {
    final cat = _draft.categoryOption;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Final Review',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReviewRow('Event', _draft.title),
                  _ReviewRow('Category', cat?.displayLabel ?? '—'),
                  if (_draft.renewalDate != null)
                    _ReviewRow(
                      'Date',
                      RenewalDateUtils.formatDisplayDate(_draft.renewalDate!),
                    ),
                  if (_draft.amount != null && _draft.amount! > 0)
                    _ReviewRow(
                      'Amount',
                      widget.settingsService.defaultCurrency
                          .formatAmount(_draft.amount!),
                    ),
                  _ReviewRow(
                    'Reminders',
                    _draft.reminderSchedule.map((d) => '$d days').join(', '),
                  ),
                  if (_draft.attachments.isNotEmpty)
                    _ReviewRow(
                      'Documents',
                      '${_draft.attachments.length} attached',
                    ),
                  if (_draft.notes.trim().isNotEmpty)
                    _ReviewRow('Notes', _draft.notes.trim()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Everything looks ready.\nRenewWise will remember it…\nso you don\'t have to.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.55,
                ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saveEvent,
              child: const Text('Protect My Peace of Mind'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachButton extends StatelessWidget {
  const _AttachButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
