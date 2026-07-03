import 'dart:io';

import 'package:flutter/material.dart';

import 'package:renew_wise/models/event_document.dart';
import 'package:renew_wise/models/vault_document_category.dart';
import 'package:renew_wise/services/document_protection_service.dart';
import 'package:renew_wise/services/smart_lock_service.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';

/// Opens documents with optional device authentication (Package 7C).
abstract final class DocumentOpenUtils {
  static Future<bool> ensureAccess(
    BuildContext context,
    EventDocument doc,
  ) async {
    if (!doc.isProtected || doc.path.startsWith('demo://')) return true;

    final auth = await SmartLockService.authenticate(
      reason: 'Authenticate to open ${doc.name}',
    );

    if (!context.mounted) return false;

    switch (auth) {
      case DocumentAuthResult.success:
        return true;
      case DocumentAuthResult.noDeviceSecurity:
        return false;
      case DocumentAuthResult.cancelled:
      case DocumentAuthResult.failed:
        return false;
    }
  }

  static Future<void> open(
    BuildContext context,
    EventDocument doc,
  ) async {
    final allowed = await ensureAccess(context, doc);
    if (!allowed || !context.mounted) return;
    _showContent(context, doc);
  }

  static void _showContent(BuildContext context, EventDocument doc) {
    final isPreviewableImage = doc.isImage &&
        doc.resolvedFileType == VaultFileType.image &&
        !doc.path.startsWith('demo://') &&
        File(doc.path).existsSync();

    if (isPreviewableImage) {
      Navigator.of(context).push(
        PageRouteBuilder<void>(
          pageBuilder: (_, _, _) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: Text(doc.name),
            ),
            body: Center(
              child: Image.file(File(doc.path), fit: BoxFit.contain),
            ),
          ),
          transitionsBuilder: (_, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(doc.name),
        content: Icon(
          Icons.description_outlined,
          size: 64,
          color: RenewWisePalette.textCaption,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Small lock indicator beside protected document names.
class DocumentProtectionLockIcon extends StatelessWidget {
  const DocumentProtectionLockIcon({
    super.key,
    required this.isProtected,
    this.size = 16,
  });

  final bool isProtected;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (!isProtected) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Icon(
        Icons.lock_outline,
        size: size,
        color: RenewWisePalette.textSecondary,
      ),
    );
  }
}
