import 'dart:io';

import 'package:flutter/material.dart';

import 'package:renew_wise/models/event_document.dart';
import 'package:renew_wise/models/vault_document_category.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/utils/document_open_utils.dart';
import 'package:renew_wise/utils/vault_list_utils.dart';

class VaultDocumentCard extends StatelessWidget {
  const VaultDocumentCard({
    super.key,
    required this.document,
    this.linkedEventLabel,
    this.onTap,
    this.compact = false,
    this.isShared = false,
  });

  final EventDocument document;
  final String? linkedEventLabel;
  final VoidCallback? onTap;
  final bool compact;
  final bool isShared;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RenewWisePalette.cardSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: compact ? _buildCompact() : _buildFull(),
      ),
    );
  }

  Widget _buildFull() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Thumbnail(document: document, size: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        document.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: RenewWiseTypography.cardTitle.copyWith(
                          fontSize: 15,
                        ),
                      ),
                    ),
                    DocumentProtectionLockIcon(isProtected: document.isProtected),
                    if (document.isFavorite)
                      const Icon(Icons.star_rounded,
                          size: 16, color: AppColors.gold),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  document.categoryLabel,
                  style: RenewWiseTypography.secondary.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _MiniBadge(
                      label: VaultListUtils.formatBytes(document.sizeBytes),
                    ),
                    if (document.isLinked)
                      _MiniBadge(label: 'Linked', color: AppColors.primary)
                    else
                      const _MiniBadge(label: 'Unlinked'),
                    _MiniBadge(label: document.storageBackend.label),
                  ],
                ),
                if (linkedEventLabel != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    linkedEventLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RenewWiseTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompact() {
    return SizedBox(
      width: 120,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumbnail(document: document, size: 48),
            const SizedBox(height: 8),
            Text(
              document.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: RenewWiseTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (document.isProtected)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: DocumentProtectionLockIcon(isProtected: true, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.document, required this.size});

  final EventDocument document;
  final double size;

  static final _cache = <String, FileImage>{};

  @override
  Widget build(BuildContext context) {
    final isDemo = document.path.startsWith('demo://');
    final canPreview = !document.isProtected &&
        document.resolvedFileType == VaultFileType.image &&
        !isDemo &&
        File(document.path).existsSync();

    Widget child;
    if (canPreview) {
      final image = _cache.putIfAbsent(
        document.path,
        () => FileImage(File(document.path)),
      );
      child = Image(
        image: image,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _icon(),
      );
    } else {
      child = _icon();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(width: size, height: size, child: child),
    );
  }

  Widget _icon() {
    final icon = switch (document.resolvedFileType) {
      VaultFileType.image => Icons.image_outlined,
      VaultFileType.pdf => Icons.picture_as_pdf_outlined,
      VaultFileType.document => Icons.description_outlined,
    };
    return Container(
      color: AppColors.primary.withAlpha(16),
      child: Icon(icon, color: AppColors.primary, size: size * 0.45),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withAlpha(18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: c,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
      ),
    );
  }
}
