import 'package:flutter/material.dart';

import 'package:renew_wise/models/event_document.dart';
import 'package:renew_wise/services/document_protection_service.dart';
import 'package:renew_wise/services/smart_lock_service.dart';
import 'package:renew_wise/theme/design_tokens.dart';

/// Protection dialogs for attached documents (Package 7C).
abstract final class DocumentProtectionDialogs {
  /// Returns `true` to protect, `false` to skip.
  static Future<bool> askProtectAfterAttach(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.dialogBorder),
        title: const Text('Protect this document?'),
        content: const Text(
          'Would you like to protect this document using your phone\'s '
          'fingerprint, face unlock or screen lock?\n\n'
          'This document will require authentication each time it is opened.',
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Skip'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.lock_outline, size: 18),
            label: const Text('Protect (Recommended)'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<void> showNoScreenLock(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.dialogBorder),
        title: const Text('Screen lock required'),
        content: const Text(
          'To protect documents, please enable a screen lock on your device.\n\n'
          'You can continue without protection for now.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static Future<DocumentMenuAction?> showDocumentMenu(
    BuildContext context, {
    required EventDocument doc,
  }) {
    return showModalBottomSheet<DocumentMenuAction>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                doc.isProtected ? Icons.lock_open_outlined : Icons.lock_outline,
              ),
              title: Text(
                doc.isProtected ? 'Remove Protection' : 'Protect Document',
              ),
              onTap: () => Navigator.pop(
                ctx,
                doc.isProtected
                    ? DocumentMenuAction.removeProtection
                    : DocumentMenuAction.protect,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Remove from event'),
              onTap: () => Navigator.pop(ctx, DocumentMenuAction.remove),
            ),
          ],
        ),
      ),
    );
  }
}

enum DocumentMenuAction {
  protect,
  removeProtection,
  remove,
}

/// Attach-time and settings protection helpers.
abstract final class DocumentProtectionFlow {
  static Future<EventDocument> applyAfterAttach(
    BuildContext context,
    EventDocument doc,
  ) async {
    final shouldProtect =
        await DocumentProtectionDialogs.askProtectAfterAttach(context);
    if (!shouldProtect) return doc;

    final available = await DocumentProtectionService.isDeviceAuthAvailable();
    if (!available) {
      if (context.mounted) {
        await DocumentProtectionDialogs.showNoScreenLock(context);
      }
      return doc;
    }
    return doc.copyWith(isProtected: true);
  }

  static Future<bool> updateProtection(
    BuildContext context, {
    required EventDocument doc,
    required bool protect,
    required Future<void> Function(EventDocument updated) persist,
  }) async {
    if (protect == doc.isProtected) return false;

    if (protect) {
      final available = await DocumentProtectionService.isDeviceAuthAvailable();
      if (!available) {
        if (context.mounted) {
          await DocumentProtectionDialogs.showNoScreenLock(context);
        }
        return false;
      }
    }

    final auth = await SmartLockService.authenticate(
      reason: protect
          ? 'Authenticate to protect this document'
          : 'Authenticate to remove document protection',
    );
    if (auth != DocumentAuthResult.success) return false;

    await persist(doc.copyWith(isProtected: protect));
    return true;
  }

  static Future<bool> authenticateForDelete(EventDocument doc) async {
    if (!doc.isProtected) return true;
    final auth = await SmartLockService.authenticate(
      reason: 'Authenticate to delete ${doc.name}',
    );
    return auth == DocumentAuthResult.success;
  }
}
