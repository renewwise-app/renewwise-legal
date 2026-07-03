import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:renew_wise/models/event_document.dart';
import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/renewal_status.dart';
import 'package:renew_wise/screens/add_renewal_screen.dart';
import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/notification_service.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/services/renewal_completion_flow.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/services/sharing_service.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/utils/document_attach_utils.dart';
import 'package:renew_wise/utils/document_open_utils.dart';
import 'package:renew_wise/utils/document_protection_dialogs.dart';
import 'package:renew_wise/utils/recurrence_utils.dart';
import 'package:renew_wise/widgets/common/app_dialogs.dart';
import 'package:renew_wise/widgets/common/app_feedback.dart';
import 'package:renew_wise/widgets/common/renew_wise_inline_empty_state.dart';
import 'package:renew_wise/widgets/event_list/event_list_reminder_card.dart';

/// Event Details — Packet 03 design lock.
class EventDetailsScreen extends StatefulWidget {
  const EventDetailsScreen({
    super.key,
    required this.renewal,
    required this.renewalService,
    required this.settingsService,
    required this.reminderStateService,
    required this.notificationService,
    required this.eventExtrasService,
    this.sharingService,
  });

  final Renewal renewal;
  final RenewalService renewalService;
  final SettingsService settingsService;
  final ReminderStateService reminderStateService;
  final NotificationService notificationService;
  final EventExtrasService eventExtrasService;
  final SharingService? sharingService;

  static Future<void> push(
    BuildContext context, {
    required Renewal renewal,
    required RenewalService renewalService,
    required SettingsService settingsService,
    required ReminderStateService reminderStateService,
    required NotificationService notificationService,
    required EventExtrasService eventExtrasService,
    SharingService? sharingService,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => EventDetailsScreen(
          renewal: renewal,
          renewalService: renewalService,
          settingsService: settingsService,
          reminderStateService: reminderStateService,
          notificationService: notificationService,
          eventExtrasService: eventExtrasService,
          sharingService: sharingService,
        ),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: RenewWiseHomeMotion.shellFade,
      ),
    );
  }

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _notesExpanded = false;
  final _imagePicker = ImagePicker();

  Renewal _findRenewal() {
    return widget.renewalService.renewals.firstWhere(
      (r) => r.id == widget.renewal.id,
      orElse: () => widget.renewal,
    );
  }

  Future<void> _confirmDelete(Renewal r) async {
    final confirmed = await AppDialogs.delete(
      context,
      title: 'Delete permanently?',
      message:
          'This removes the event, its reminders, and attached documents. This cannot be undone.',
    );
    if (confirmed && mounted) {
      AppHaptics.destructive();
      await widget.eventExtrasService.clearForEvent(r.id);
      await widget.sharingService?.clearForEvent(r.id);
      widget.renewalService.deleteRenewal(r.id);
      if (mounted) {
        AppFeedback.deleted(context);
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _markComplete(Renewal r) async {
    final navigator = Navigator.of(context);

    final movedToHistory = await RenewalCompletionFlow(
      renewalService: widget.renewalService,
      reminderStateService: widget.reminderStateService,
      notificationService: widget.notificationService,
      defaultReminderTimeMinutes:
          widget.settingsService.defaultReminderTimeMinutes,
    ).run(context, r, completionMethod: 'app');

    if (!movedToHistory) return;

    await widget.eventExtrasService.recordActivity(
      r.id,
      EventActivityType.completed,
    );

    if (mounted) {
      AppFeedback.completed(context);
      await navigator.maybePop();
    }
  }

  Future<void> _openEdit(Renewal r) async {
    await AddRenewalScreen.push(
      context,
      renewalService: widget.renewalService,
      renewal: r,
      defaultCurrency: widget.settingsService.defaultCurrency,
      defaultReminderTimeMinutes:
          widget.settingsService.defaultReminderTimeMinutes,
    );
  }

  Future<void> _attachDocument(Renewal r) async {
    final source = await DocumentAttachUtils.pickSource(context);
    if (source == null || !mounted) return;

    final docs = await DocumentAttachUtils.pickAndCopy(
      context: context,
      picker: _imagePicker,
      source: source,
      renewalId: r.id,
    );
    for (final doc in docs) {
      if (!mounted) return;
      final prepared = await DocumentProtectionFlow.applyAfterAttach(
        context,
        doc,
      );
      await widget.eventExtrasService.addDocument(r.id, prepared);
    }
  }

  Future<void> _showDocumentMenu(Renewal r, EventDocument doc) async {
    final action = await DocumentProtectionDialogs.showDocumentMenu(
      context,
      doc: doc,
    );
    if (!mounted || action == null) return;

    switch (action) {
      case DocumentMenuAction.protect:
      case DocumentMenuAction.removeProtection:
        final updated = await DocumentProtectionFlow.updateProtection(
          context,
          doc: doc,
          protect: action == DocumentMenuAction.protect,
          persist: (next) => widget.eventExtrasService.updateDocument(next),
        );
        if (updated && mounted) setState(() {});
      case DocumentMenuAction.remove:
        await _confirmRemoveDocument(r, doc);
    }
  }

  Future<void> _confirmRemoveDocument(Renewal r, EventDocument doc) async {
    final authed = await DocumentProtectionFlow.authenticateForDelete(doc);
    if (!authed || !mounted) return;

    final links = widget.eventExtrasService.linkCount(doc.id);
    final message = links > 1
        ? 'This document is linked to $links reminders. Remove from this event only?'
        : 'Remove this document from the event?';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove document?'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.eventExtrasService.removeDocument(r.id, doc.id);
    }
  }

  Future<void> _previewDocument(EventDocument doc) async {
    await DocumentOpenUtils.open(context, doc);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.renewalService,
        widget.reminderStateService,
        widget.eventExtrasService,
      ]),
      builder: (context, _) {
        final r = _findRenewal();
        final docs = widget.eventExtrasService.documentsFor(r.id);
        final isPaid = r.status == RenewalStatus.paid;
        final accent = EventListReminderCard.categoryAccent(r.category);

        return Scaffold(
          backgroundColor: RenewWisePalette.listBackground,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _EventDetailsHeader(
                      onBack: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.page,
                          12,
                          AppSpacing.page,
                          28,
                        ),
                        children: [
                          _HeroCard(renewal: r, accent: accent),
                          const SizedBox(height: 16),
                          _AmountCard(renewal: r, accent: accent),
                          if (RecurrenceUtils.isRecurring(r)) ...[
                            const SizedBox(height: 16),
                            _InfoCard(
                              icon: Icons.repeat_rounded,
                              accent: accent,
                              label: 'Repeat',
                              child: Text(
                                RecurrenceUtils.recurringCycleLabel(
                                  r.repeatCycle,
                                ),
                                style: _EventDetailsStyles.value,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          _InfoCard(
                            icon: Icons.notifications_outlined,
                            accent: accent,
                            label: 'Reminder Schedule',
                            child: _ReminderScheduleChips(renewal: r),
                          ),
                          const SizedBox(height: 16),
                          _DocumentsSection(
                            docs: docs,
                            accent: accent,
                            onAdd: () => _attachDocument(r),
                            onOpen: _previewDocument,
                            onMenu: (doc) => _showDocumentMenu(r, doc),
                          ),
                          const SizedBox(height: 16),
                          _NotesSection(
                            notes: r.notes,
                            expanded: _notesExpanded,
                            accent: accent,
                            onToggle: () => setState(
                              () => _notesExpanded = !_notesExpanded,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _BottomActions(
                      showComplete: !isPaid,
                      onComplete: () => _markComplete(r),
                      onEdit: () => _openEdit(r),
                      onDelete: () => _confirmDelete(r),
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

abstract final class _EventDetailsStyles {
  static const label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: RenewWisePalette.textSecondary,
    height: 1.25,
  );

  static const value = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: RenewWisePalette.textPrimary,
    letterSpacing: -0.3,
    height: 1.1,
  );

  static const cardRadius = 28.0;
  static const cardPadding = 24.0;
}

abstract final class _EventDetailsFormat {
  static String dueDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String heroStatus(Renewal renewal) {
    final days = renewal.daysRemaining;
    if (days < 0) {
      final n = days.abs();
      return n == 1 ? 'Overdue by 1 Day' : 'Overdue by $n Days';
    }
    if (days == 0) return 'Due Today';
    if (days == 1) return 'Due Tomorrow';
    return 'Due in $days Days';
  }

  static ({Color dot, Color bg, Color text}) heroStatusColors(
    Renewal renewal,
  ) {
    final days = renewal.daysRemaining;
    if (days < 0) {
      return (
        dot: const Color(0xFFF87171),
        bg: const Color(0xFFFEE2E2),
        text: const Color(0xFFB91C1C),
      );
    }
    if (days <= 1) {
      return (
        dot: const Color(0xFFFB923C),
        bg: const Color(0xFFFFEDD5),
        text: const Color(0xFFC2410C),
      );
    }
    if (days <= 9) {
      return (
        dot: const Color(0xFFFACC15),
        bg: const Color(0xFFFEF9C3),
        text: const Color(0xFFA16207),
      );
    }
    return (
      dot: const Color(0xFF4ADE80),
      bg: const Color(0xFFDCFCE7),
      text: const Color(0xFF15803D),
    );
  }

  static String reminderChipLabel(int days) {
    if (days == 0) return 'Same Day';
    if (days == 1) return '1 Day';
    return '$days Days';
  }

  static String scheduledCount(Renewal renewal) {
    final count =
        renewal.reminderSchedule.length + renewal.customReminderDates.length;
    if (count == 0) return 'None';
    if (count == 1) return '1 Scheduled';
    return '$count Scheduled';
  }
}

class _EventDetailsHeader extends StatelessWidget {
  const _EventDetailsHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          _RoundIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: onBack,
          ),
          Expanded(
            child: Text(
              'Event Details',
              textAlign: TextAlign.center,
              style: RenewWiseTypography.cardTitle,
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: RenewWisePalette.cardSurface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: RenewWiseShadows.listCard(),
          ),
          child: Icon(
            icon,
            size: 22,
            color: const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.renewal,
    required this.accent,
  });

  final Renewal renewal;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final status = _EventDetailsFormat.heroStatusColors(renewal);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            RenewWisePalette.brandSoftStart,
            RenewWisePalette.brandSoftEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(_EventDetailsStyles.cardRadius),
        boxShadow: RenewWiseShadows.homeCard(accent),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -12,
            bottom: 32,
            child: Icon(
              Icons.waves_rounded,
              size: 120,
              color: accent.withAlpha(18),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroIconTile(
                      icon: renewal.category.icon,
                      accent: accent,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            renewal.title,
                            style: RenewWiseTypography.cardTitle,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            renewal.categoryLabel,
                            style: RenewWiseTypography.tileEventCount.copyWith(
                              color: RenewWisePalette.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _StatusPill(
                            label: _EventDetailsFormat.heroStatus(renewal),
                            dotColor: status.dot,
                            backgroundColor: status.bg,
                            textColor: status.text,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: RenewWisePalette.cardSurface.withAlpha(230),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _HeroMetaColumn(
                            icon: Icons.calendar_today_outlined,
                            label: 'Due Date',
                            value: _EventDetailsFormat.dueDate(
                              renewal.renewalDate,
                            ),
                            accent: accent,
                          ),
                        ),
                        Container(
                          width: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          color: const Color(0xFFE2E8F0),
                        ),
                        Expanded(
                          child: _HeroMetaColumn(
                            icon: Icons.notifications_outlined,
                            label: 'Reminders',
                            value: _EventDetailsFormat.scheduledCount(renewal),
                            accent: accent,
                            valueColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroIconTile extends StatelessWidget {
  const _HeroIconTile({
    required this.icon,
    required this.accent,
  });

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: RenewWisePalette.cardSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accent.withAlpha(45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: accent, size: 28),
    );
  }
}

class _HeroMetaColumn extends StatelessWidget {
  const _HeroMetaColumn({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: accent.withAlpha(200)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: _EventDetailsStyles.label),
              const SizedBox(height: 4),
              Text(
                value,
                style: _EventDetailsStyles.value.copyWith(
                  color: valueColor ?? RenewWisePalette.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({
    required this.renewal,
    required this.accent,
  });

  final Renewal renewal;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final hasPayment = renewal.paymentRequired && renewal.amount != null;

    return _InfoCard(
      icon: Icons.payments_outlined,
      accent: accent,
      label: 'Amount',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasPayment
                ? renewal.currency.formatAmount(renewal.amount!)
                : 'No Dues',
            style: _EventDetailsStyles.value,
          ),
          const SizedBox(height: 4),
          Text(
            hasPayment ? 'Payment Required' : 'No payment required',
            style: _EventDetailsStyles.label,
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.accent,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final Color accent;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_EventDetailsStyles.cardPadding),
      decoration: BoxDecoration(
        color: RenewWisePalette.cardSurface,
        borderRadius: BorderRadius.circular(_EventDetailsStyles.cardRadius),
        boxShadow: RenewWiseShadows.listCard(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionIconTile(icon: icon, accent: accent),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _EventDetailsStyles.label),
                const SizedBox(height: 8),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionIconTile extends StatelessWidget {
  const _SectionIconTile({
    required this.icon,
    required this.accent,
  });

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: accent.withAlpha(28),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: accent, size: 24),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.dotColor,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color dotColor;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: RenewWiseTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderScheduleChips extends StatelessWidget {
  const _ReminderScheduleChips({required this.renewal});

  final Renewal renewal;

  @override
  Widget build(BuildContext context) {
    final chips = renewal.reminderSchedule
        .map(_EventDetailsFormat.reminderChipLabel)
        .toList();

    if (chips.isEmpty) {
      return const RenewWiseInlineEmptyState(
        icon: Icons.notifications_none_outlined,
        message: 'No reminders set.',
        subtitle: 'Add reminder dates to stay on track.',
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips
          .map(
            (label) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                label,
                style: RenewWiseTypography.tileEventCount.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DocumentsSection extends StatelessWidget {
  const _DocumentsSection({
    required this.docs,
    required this.accent,
    required this.onAdd,
    required this.onOpen,
    required this.onMenu,
  });

  final List<EventDocument> docs;
  final Color accent;
  final VoidCallback onAdd;
  final Future<void> Function(EventDocument doc) onOpen;
  final void Function(EventDocument doc) onMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_EventDetailsStyles.cardPadding),
      decoration: BoxDecoration(
        color: RenewWisePalette.cardSurface,
        borderRadius: BorderRadius.circular(_EventDetailsStyles.cardRadius),
        boxShadow: RenewWiseShadows.listCard(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionIconTile(
            icon: Icons.description_outlined,
            accent: accent,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Documents', style: _EventDetailsStyles.label),
                const SizedBox(height: 8),
                if (docs.isEmpty) ...[
                  const RenewWiseInlineEmptyState(
                    icon: Icons.folder_open_outlined,
                    message: 'No documents attached.',
                    subtitle: 'Keep everything in one secure place.',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.attach_file_outlined, size: 18),
                      label: const Text('Attach Document'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: AppColors.primary.withAlpha(80),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        textStyle: RenewWiseTypography.actionLink.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ] else
                  ...docs.map(
                    (doc) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DocumentRow(
                        doc: doc,
                        onTap: () => onOpen(doc),
                        onLongPress: () => onMenu(doc),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.doc,
    required this.onTap,
    required this.onLongPress,
  });

  final EventDocument doc;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final isPdf = doc.name.toLowerCase().endsWith('.pdf');
    final iconColor = isPdf ? const Color(0xFFEF4444) : AppColors.primary;

    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
                color: iconColor,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        doc.name,
                        style: RenewWiseTypography.tileEventCount.copyWith(
                          fontWeight: FontWeight.w600,
                          color: RenewWisePalette.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DocumentProtectionLockIcon(isProtected: doc.isProtected),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFCBD5E1),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({
    required this.notes,
    required this.expanded,
    required this.accent,
    required this.onToggle,
  });

  final String? notes;
  final bool expanded;
  final Color accent;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final text = notes?.trim();
    final hasNotes = text != null && text.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: RenewWisePalette.cardSurface,
        borderRadius: BorderRadius.circular(_EventDetailsStyles.cardRadius),
        boxShadow: RenewWiseShadows.listCard(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: RenewWisePalette.cardSurface,
        child: InkWell(
          onTap: hasNotes ? onToggle : null,
          child: Padding(
            padding: const EdgeInsets.all(_EventDetailsStyles.cardPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionIconTile(
                  icon: Icons.notes_rounded,
                  accent: accent,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Notes',
                              style: _EventDetailsStyles.label,
                            ),
                          ),
                          if (hasNotes)
                            AnimatedRotation(
                              turns: expanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 220),
                              child: const Icon(
                                Icons.expand_more_rounded,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (hasNotes && expanded)
                        Text(
                          text,
                          style: RenewWiseTypography.tileEventCount.copyWith(
                            color: RenewWisePalette.textSecondary,
                            height: 1.45,
                          ),
                        )
                      else if (!hasNotes)
                        Text(
                          'No notes added.',
                          style: _EventDetailsStyles.label,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.showComplete,
    required this.onComplete,
    required this.onEdit,
    required this.onDelete,
  });

  final bool showComplete;
  final VoidCallback onComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const _height = 48.0;
  static const _radius = 20.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: RenewWisePalette.listBackground,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showComplete) ...[
              _ActionButton(
                label: 'Mark Complete',
                icon: Icons.check_rounded,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                onTap: onComplete,
              ),
              const SizedBox(height: 12),
            ],
            _ActionButton(
              label: 'Edit Reminder',
              icon: Icons.edit_outlined,
              backgroundColor: AppColors.primary.withAlpha(20),
              foregroundColor: AppColors.primary,
              onTap: onEdit,
            ),
            const SizedBox(height: 12),
            _ActionButton(
              label: 'Delete Reminder',
              icon: Icons.delete_outline_rounded,
              backgroundColor: AppColors.critical.withAlpha(20),
              foregroundColor: AppColors.critical,
              onTap: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      elevation: 0,
      shadowColor: Colors.black.withAlpha(30),
      borderRadius: BorderRadius.circular(_BottomActions._radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_BottomActions._radius),
        child: Ink(
          height: _BottomActions._height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_BottomActions._radius),
            boxShadow: [
              BoxShadow(
                color: foregroundColor.withAlpha(28),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: foregroundColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: RenewWiseTypography.actionLink.copyWith(
                  color: foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
