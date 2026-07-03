import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:renew_wise/models/event_document.dart';
import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/screens/event_details_screen.dart';
import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/notification_service.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/widgets/common/app_empty_state.dart';
import 'package:renew_wise/widgets/common/app_feedback.dart';
import 'package:renew_wise/utils/date_utils.dart';
import 'package:renew_wise/utils/event_quality_score.dart';
import 'package:renew_wise/utils/renewwise_health.dart';
import 'package:renew_wise/widgets/quality_score_sheet.dart';
import 'package:renew_wise/widgets/renewal_list_item.dart';

/// Quick-fix list for a specific health issue.
class HealthFixScreen extends StatefulWidget {
  const HealthFixScreen({
    super.key,
    required this.issue,
    required this.renewalService,
    required this.settingsService,
    required this.reminderStateService,
    required this.notificationService,
    required this.eventExtrasService,
  });

  final HealthIssueKind issue;
  final RenewalService renewalService;
  final SettingsService settingsService;
  final ReminderStateService reminderStateService;
  final NotificationService notificationService;
  final EventExtrasService eventExtrasService;

  static Future<void> push(
    BuildContext context, {
    required HealthIssueKind issue,
    required RenewalService renewalService,
    required SettingsService settingsService,
    required ReminderStateService reminderStateService,
    required NotificationService notificationService,
    required EventExtrasService eventExtrasService,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => HealthFixScreen(
          issue: issue,
          renewalService: renewalService,
          settingsService: settingsService,
          reminderStateService: reminderStateService,
          notificationService: notificationService,
          eventExtrasService: eventExtrasService,
        ),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  @override
  State<HealthFixScreen> createState() => _HealthFixScreenState();
}

class _HealthFixScreenState extends State<HealthFixScreen> {
  final _imagePicker = ImagePicker();

  List<Renewal> _items() => RenewWiseHealth.filter(
        widget.renewalService.renewals,
        widget.issue,
        widget.eventExtrasService,
      );

  Future<void> _attachDocument(Renewal r) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked =
        await _imagePicker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final name = p.basename(picked.path);
      final dest = File(
        p.join(
          dir.path,
          'event_${r.id}_${DateTime.now().millisecondsSinceEpoch}_$name',
        ),
      );
      await File(picked.path).copy(dest.path);
      await widget.eventExtrasService.addDocument(
        r.id,
        EventDocument(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          path: dest.path,
          name: name,
          isImage: true,
          addedAt: DateTime.now(),
        ),
      );
      if (mounted) {
        AppHaptics.confirm();
        AppFeedback.documentAttached(context);
      }
    } catch (_) {
      if (mounted) {
        AppFeedback.error(
          context,
          'Could not attach the document. Please try again.',
        );
      }
    }
  }

  Future<void> _quickAddAmount(Renewal r) async {
    final controller = TextEditingController(
      text: r.amount?.toStringAsFixed(0) ?? '',
    );
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add amount — ${r.title}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: '${r.currency.symbol} ',
            hintText: 'Amount',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim());
              if (v != null && v > 0) Navigator.pop(ctx, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount == null) return;
    widget.renewalService.updateRenewal(
      r.copyWith(
        paymentRequired: true,
        amount: amount,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _quickAddNotes(Renewal r) async {
    final controller = TextEditingController(text: r.notes ?? '');
    final notes = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add notes — ${r.title}'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Notes'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (notes == null || notes.isEmpty) return;
    widget.renewalService.updateRenewal(
      r.copyWith(notes: notes, updatedAt: DateTime.now()),
    );
  }

  Future<void> _reschedule(Renewal r) async {
    final picked = await RenewalDateUtils.pickDate(
      context,
      helpText: 'Reschedule event',
      initialDate: r.renewalDate,
    );
    if (picked == null) return;
    widget.renewalService.updateRenewal(
      r.copyWith(renewalDate: picked, updatedAt: DateTime.now()),
    );
  }

  Widget? _quickAction(Renewal r) {
    return switch (widget.issue) {
      HealthIssueKind.missingDocuments => FilledButton.tonalIcon(
          onPressed: () => _attachDocument(r),
          icon: const Icon(Icons.attach_file_outlined, size: 18),
          label: const Text('Attach'),
        ),
      HealthIssueKind.missingAmounts => FilledButton.tonalIcon(
          onPressed: () => _quickAddAmount(r),
          icon: const Icon(Icons.payments_outlined, size: 18),
          label: const Text('Add Amount'),
        ),
      HealthIssueKind.missingNotes => FilledButton.tonalIcon(
          onPressed: () => _quickAddNotes(r),
          icon: const Icon(Icons.notes_outlined, size: 18),
          label: const Text('Add Notes'),
        ),
      HealthIssueKind.overdue => FilledButton.tonalIcon(
          onPressed: () => _reschedule(r),
          icon: const Icon(Icons.calendar_month_outlined, size: 18),
          label: const Text('Reschedule'),
        ),
      HealthIssueKind.duplicates => OutlinedButton(
          onPressed: () => EventDetailsScreen.push(
            context,
            renewal: r,
            renewalService: widget.renewalService,
            settingsService: widget.settingsService,
            reminderStateService: widget.reminderStateService,
            notificationService: widget.notificationService,
            eventExtrasService: widget.eventExtrasService,
          ),
          child: const Text('Review'),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.renewalService,
        widget.eventExtrasService,
      ]),
      builder: (context, _) {
        final items = _items();
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.issue.label),
          ),
          body: items.isEmpty
              ? AppEmptyState(
                  icon: widget.issue.icon,
                  title: 'All clear',
                  subtitle: 'Everything looks good here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final r = items[index];
                    final docCount =
                        widget.eventExtrasService.documentsFor(r.id).length;
                    final quality = EventQualityScore.compute(
                      r,
                      documentCount: docCount,
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RenewalListItem(
                          renewal: r,
                          documentCount: docCount,
                          qualityResult: quality,
                          onQualityTap: () => showQualityScoreSheet(
                            context,
                            quality,
                          ),
                          onTap: () => EventDetailsScreen.push(
                            context,
                            renewal: r,
                            renewalService: widget.renewalService,
                            settingsService: widget.settingsService,
                            reminderStateService:
                                widget.reminderStateService,
                            notificationService: widget.notificationService,
                            eventExtrasService: widget.eventExtrasService,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _quickAction(r),
                        ),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }
}
