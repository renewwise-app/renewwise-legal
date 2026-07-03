import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';

import 'package:renew_wise/models/event_document.dart';

import 'package:renew_wise/models/vault_document_category.dart';

import 'package:renew_wise/screens/vault_document_detail_screen.dart';

import 'package:renew_wise/services/event_extras_service.dart';

import 'package:renew_wise/services/notification_service.dart';

import 'package:renew_wise/services/reminder_state_service.dart';

import 'package:renew_wise/services/renewal_service.dart';

import 'package:renew_wise/services/settings_service.dart';

import 'package:renew_wise/theme/app_theme.dart';

import 'package:renew_wise/theme/design_tokens.dart';

import 'package:renew_wise/theme/renew_wise_design_system.dart';

import 'package:renew_wise/utils/document_attach_utils.dart';

import 'package:renew_wise/utils/document_protection_dialogs.dart';

import 'package:renew_wise/utils/empty_state_guidance.dart';

import 'package:renew_wise/utils/feature_purpose_messaging.dart';

import 'package:renew_wise/utils/vault_list_utils.dart';

import 'package:renew_wise/widgets/common/app_empty_state.dart';

import 'package:renew_wise/widgets/common/app_feedback.dart';

import 'package:renew_wise/widgets/common/feature_purpose_subtitle.dart';

import 'package:renew_wise/widgets/common/renew_wise_back_button.dart';

import 'package:renew_wise/widgets/common/renew_wise_primary_button.dart';

import 'package:renew_wise/widgets/vault_document_card.dart';

class DocumentVaultScreen extends StatefulWidget {
  const DocumentVaultScreen({
    super.key,

    required this.eventExtrasService,

    required this.renewalService,

    required this.settingsService,

    required this.reminderStateService,

    required this.notificationService,
  });

  final EventExtrasService eventExtrasService;

  final RenewalService renewalService;

  final SettingsService settingsService;

  final ReminderStateService reminderStateService;

  final NotificationService notificationService;

  static Future<void> push(
    BuildContext context, {

    required EventExtrasService eventExtrasService,

    required RenewalService renewalService,

    required SettingsService settingsService,

    required ReminderStateService reminderStateService,

    required NotificationService notificationService,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DocumentVaultScreen(
          eventExtrasService: eventExtrasService,

          renewalService: renewalService,

          settingsService: settingsService,

          reminderStateService: reminderStateService,

          notificationService: notificationService,
        ),
      ),
    );
  }

  @override
  State<DocumentVaultScreen> createState() => _DocumentVaultScreenState();
}

class _DocumentVaultScreenState extends State<DocumentVaultScreen> {
  final _searchCtrl = TextEditingController();

  final _picker = ImagePicker();

  String _query = '';

  VaultFilterKind _filter = VaultFilterKind.all;

  VaultSortOption _sort = VaultSortOption.newest;

  VaultDocumentCategory? _category;

  @override
  void initState() {
    super.initState();

    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();

    super.dispose();
  }

  Map<String, String> _renewalTitles() {
    return {for (final r in widget.renewalService.renewals) r.id: r.title};
  }

  String? _primaryLinkLabel(EventDocument doc) {
    if (doc.linkedRenewalIds.isEmpty) return null;

    final titles = _renewalTitles();

    if (doc.linkedRenewalIds.length == 1) {
      return titles[doc.linkedRenewalIds.first];
    }

    return '${doc.linkedRenewalIds.length} linked events';
  }

  bool get _hasActiveFilters =>
      _filter != VaultFilterKind.all || _category != null;

  void _clearFilters() {
    setState(() {
      _filter = VaultFilterKind.all;

      _category = null;

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
  })
  _resolveFilteredEmptyState() {
    if (_query.trim().isNotEmpty) {
      return (
        title: 'No matching documents found.',

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
      title: 'No matching documents found.',

      subtitle: 'Try another keyword or remove some filters.',

      icon: Icons.search_off_rounded,

      actionLabel: null,

      onAction: null,

      actionIcon: null,
    );
  }

  List<EventDocument> _filtered() {
    final renewals = {for (final r in widget.renewalService.renewals) r.id: r};

    return VaultListUtils.apply(
      source: widget.eventExtrasService.allDocuments,

      query: _query,

      filter: _filter,

      sort: _sort,

      category: _category,

      renewalsById: renewals,
    );
  }

  Future<void> _attachDocument() async {
    final source = await DocumentAttachUtils.showAttachDocumentOptions(context);

    if (source == null || !mounted) return;

    final docs = await DocumentAttachUtils.pickAndCopy(
      context: context,

      picker: _picker,

      source: source,

      allowMultiple: source == ImageSource.gallery,
    );

    for (final doc in docs) {
      if (!mounted) return;

      final prepared = await DocumentProtectionFlow.applyAfterAttach(
        context,

        doc,
      );

      await widget.eventExtrasService.upsertDocument(prepared);
    }

    if (mounted && docs.isNotEmpty) {
      AppHaptics.confirm();

      AppFeedback.documentAdded(context, count: docs.length);
    }
  }

  void _openDoc(EventDocument doc) {
    VaultDocumentDetailScreen.push(
      context,

      document: doc,

      eventExtrasService: widget.eventExtrasService,

      renewalService: widget.renewalService,

      settingsService: widget.settingsService,

      reminderStateService: widget.reminderStateService,

      notificationService: widget.notificationService,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPad = MediaQuery.sizeOf(context).width > 600
        ? 32.0
        : AppSpacing.page;

    final canPop = Navigator.canPop(context);

    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.eventExtrasService,

        widget.renewalService,
      ]),

      builder: (context, _) {
        final extras = widget.eventExtrasService;

        final filtered = _filtered();

        final counts = extras.categoryCounts();

        final total = extras.totalDocumentCount;

        final storage = VaultListUtils.formatBytes(extras.totalStorageBytes);

        final isInitialEmpty =
            total == 0 && _query.isEmpty && _filter == VaultFilterKind.all;

        return Scaffold(
          backgroundColor: RenewWisePalette.pageBackground,

          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),

                child: isInitialEmpty
                    ? Padding(
                        padding: EdgeInsets.fromLTRB(hPad, 4, hPad, hPad),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,

                          children: [
                            _VaultPageHeader(showBack: canPop),

                            const SizedBox(height: AppSpacing.section),

                            Expanded(
                              child: AppEmptyState(
                                icon: Icons.attach_file_rounded,

                                title: 'No documents attached.',

                                subtitle: EmptyStateGuidance.documentVault,

                                actionLabel: 'Attach Document',

                                actionIcon: Icons.attach_file_outlined,

                                onAction: _attachDocument,
                              ),
                            ),
                          ],
                        ),
                      )
                    : CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 0),

                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,

                                children: [
                                  _VaultPageHeader(showBack: canPop),

                                  const SizedBox(height: AppSpacing.section),

                                  _VaultSearchField(controller: _searchCtrl),

                                  const SizedBox(height: AppSpacing.lg),

                                  Row(
                                    children: [
                                      _StatTile(
                                        label: 'Total',

                                        value: '$total',

                                        icon: Icons.folder_outlined,
                                      ),

                                      const SizedBox(width: AppSpacing.sm),

                                      _StatTile(
                                        label: 'Storage',

                                        value: storage,

                                        icon: Icons.sd_storage_outlined,
                                      ),
                                    ],
                                  ),

                                  if (extras.favorites.isNotEmpty) ...[
                                    const SizedBox(height: AppSpacing.xl),

                                    Text(
                                      'Favorites',

                                      style: RenewWiseTypography.sectionTitle,
                                    ),

                                    const SizedBox(height: AppSpacing.sm),

                                    SizedBox(
                                      height: 130,

                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,

                                        itemCount: extras.favorites.length,

                                        separatorBuilder: (_, _) =>
                                            const SizedBox(
                                              width: AppSpacing.sm,
                                            ),

                                        itemBuilder: (_, i) {
                                          final doc = extras.favorites[i];

                                          return VaultDocumentCard(
                                            document: doc,

                                            compact: true,

                                            onTap: () => _openDoc(doc),
                                          );
                                        },
                                      ),
                                    ),
                                  ],

                                  if (extras.recentlyViewed.isNotEmpty) ...[
                                    const SizedBox(height: AppSpacing.lg),

                                    Text(
                                      'Recently Viewed',

                                      style: RenewWiseTypography.sectionTitle,
                                    ),

                                    const SizedBox(height: AppSpacing.sm),

                                    SizedBox(
                                      height: 130,

                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,

                                        itemCount: extras.recentlyViewed.length,

                                        separatorBuilder: (_, _) =>
                                            const SizedBox(
                                              width: AppSpacing.sm,
                                            ),

                                        itemBuilder: (_, i) {
                                          final doc = extras.recentlyViewed[i];

                                          return VaultDocumentCard(
                                            document: doc,

                                            compact: true,

                                            onTap: () => _openDoc(doc),
                                          );
                                        },
                                      ),
                                    ),
                                  ],

                                  if (extras.recentlyAdded.isNotEmpty) ...[
                                    const SizedBox(height: AppSpacing.lg),

                                    Text(
                                      'Recently Added',

                                      style: RenewWiseTypography.sectionTitle,
                                    ),

                                    const SizedBox(height: AppSpacing.sm),

                                    SizedBox(
                                      height: 130,

                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,

                                        itemCount: extras.recentlyAdded.length,

                                        separatorBuilder: (_, _) =>
                                            const SizedBox(
                                              width: AppSpacing.sm,
                                            ),

                                        itemBuilder: (_, i) {
                                          final doc = extras.recentlyAdded[i];

                                          return VaultDocumentCard(
                                            document: doc,

                                            compact: true,

                                            onTap: () => _openDoc(doc),
                                          );
                                        },
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: AppSpacing.lg),

                                  Text(
                                    'Categories',

                                    style: RenewWiseTypography.sectionTitle,
                                  ),

                                  const SizedBox(height: AppSpacing.sm),

                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,

                                    child: Row(
                                      children: [
                                        FilterChip(
                                          label: const Text('All'),

                                          selected: _category == null,

                                          selectedColor: AppColors.primary
                                              .withAlpha(28),

                                          checkmarkColor: AppColors.primary,

                                          onSelected: (_) =>
                                              setState(() => _category = null),
                                        ),

                                        const SizedBox(width: AppSpacing.sm),

                                        ...VaultDocumentCategory.values.map((
                                          c,
                                        ) {
                                          final n = counts[c] ?? 0;

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              right: AppSpacing.sm,
                                            ),

                                            child: FilterChip(
                                              avatar: Icon(c.icon, size: 16),

                                              label: Text(
                                                '${c.label}${n > 0 ? ' ($n)' : ''}',
                                              ),

                                              selected: _category == c,

                                              selectedColor: AppColors.primary
                                                  .withAlpha(28),

                                              checkmarkColor: AppColors.primary,

                                              onSelected: (_) => setState(
                                                () => _category = _category == c
                                                    ? null
                                                    : c,
                                              ),
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: AppSpacing.md),

                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,

                                    child: Row(
                                      children: VaultFilterKind.values.map((f) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            right: AppSpacing.sm,
                                          ),

                                          child: FilterChip(
                                            label: Text(f.label),

                                            selected: _filter == f,

                                            selectedColor: AppColors.primary
                                                .withAlpha(28),

                                            checkmarkColor: AppColors.primary,

                                            onSelected: (_) =>
                                                setState(() => _filter = f),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),

                                  const SizedBox(height: AppSpacing.sm),

                                  DropdownButtonFormField<VaultSortOption>(
                                    key: ValueKey(_sort),

                                    initialValue: _sort,

                                    decoration: InputDecoration(
                                      labelText: 'Sort',

                                      filled: true,

                                      fillColor: RenewWisePalette.cardSurface,

                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.md,
                                        ),

                                        borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                        ),
                                      ),

                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.md,
                                        ),

                                        borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                        ),
                                      ),

                                      isDense: true,
                                    ),

                                    items: VaultSortOption.values
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s,

                                            child: Text(s.label),
                                          ),
                                        )
                                        .toList(),

                                    onChanged: (v) {
                                      if (v != null) setState(() => _sort = v);
                                    },
                                  ),

                                  const SizedBox(height: AppSpacing.lg),

                                  RenewWisePrimaryButton(
                                    label: 'Attach Document',

                                    icon: Icons.attach_file_outlined,

                                    onPressed: _attachDocument,
                                  ),

                                  const SizedBox(height: AppSpacing.lg),
                                ],
                              ),
                            ),
                          ),

                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 96),

                            sliver: filtered.isEmpty
                                ? SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: AppSpacing.section,
                                      ),

                                      child: Builder(
                                        builder: (context) {
                                          final empty =
                                              _resolveFilteredEmptyState();

                                          return AppEmptyState(
                                            icon: empty.icon,

                                            title: empty.title,

                                            subtitle: empty.subtitle,

                                            actionLabel: empty.actionLabel,

                                            onAction: empty.onAction,

                                            actionIcon: empty.actionIcon,
                                          );
                                        },
                                      ),
                                    ),
                                  )
                                : SliverList.separated(
                                    itemCount: filtered.length,

                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: AppSpacing.md),

                                    itemBuilder: (_, i) {
                                      final doc = filtered[i];

                                      return VaultDocumentCard(
                                        document: doc,

                                        linkedEventLabel: _primaryLinkLabel(
                                          doc,
                                        ),

                                        onTap: () => _openDoc(doc),
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

class _VaultPageHeader extends StatelessWidget {
  const _VaultPageHeader({required this.showBack});

  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        if (showBack) ...[
          RenewWiseBackButton(onPressed: () => Navigator.pop(context)),

          const SizedBox(width: AppSpacing.sm),
        ],

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                'Document Vault',

                style: RenewWiseTypography.screenTitle.copyWith(fontSize: 26),
              ),

              const SizedBox(height: AppSpacing.sm),

              const FeaturePurposeSubtitle(FeaturePurposeMessaging.documents),
            ],
          ),
        ),
      ],
    );
  }
}

class _VaultSearchField extends StatelessWidget {
  const _VaultSearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,

      decoration: InputDecoration(
        hintText: 'Search documents…',

        prefixIcon: const Icon(Icons.search_rounded),

        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded),

                onPressed: controller.clear,
              )
            : null,

        filled: true,

        fillColor: RenewWisePalette.cardSurface,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),

          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),

          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),

          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),

        isDense: true,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,

          vertical: 14,
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,

    required this.value,

    required this.icon,
  });

  final String label;

  final String value;

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),

        decoration: BoxDecoration(
          color: RenewWisePalette.cardSurface,

          borderRadius: BorderRadius.circular(AppRadius.homeCard),

          border: Border.all(color: const Color(0xFFE2E8F0)),

          boxShadow: RenewWiseShadows.listCard(),
        ),

        child: Row(
          children: [
            Container(
              width: 40,

              height: 40,

              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(24),

                borderRadius: BorderRadius.circular(12),
              ),

              child: Icon(icon, color: AppColors.primary, size: 20),
            ),

            const SizedBox(width: AppSpacing.sm),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    label,

                    style: RenewWiseTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  Text(
                    value,

                    style: RenewWiseTypography.tileEventCount.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
