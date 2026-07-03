import 'dart:io';

import 'package:flutter/material.dart';
import 'package:renew_wise/utils/privacy_permission_dialogs.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:renew_wise/models/event_document.dart';
import 'package:renew_wise/models/vault_document_category.dart';

abstract final class DocumentAttachUtils {
  /// Vault / attach flows — Upload from Device or Quick Scan.
  static Future<ImageSource?> showAttachDocumentOptions(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: const Text('Upload from Device'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.document_scanner_outlined),
              title: const Text('Quick Scan'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  static Future<ImageSource?> pickSource(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  static Future<List<EventDocument>> pickAndCopy({
    required BuildContext context,
    required ImagePicker picker,
    required ImageSource source,
    String? renewalId,
    VaultDocumentCategory category = VaultDocumentCategory.other,
    bool allowMultiple = false,
  }) async {
    if (Platform.isAndroid) {
      final proceed =
          await PrivacyPermissionDialogs.explainDocumentAccess(context);
      if (!proceed) return [];
    }

    final docs = <EventDocument>[];
    if (allowMultiple && source == ImageSource.gallery) {
      final picked = await picker.pickMultiImage(imageQuality: 85);
      for (final x in picked) {
        final doc = await _copyFile(
          x.path,
          p.basename(x.path),
          isImage: true,
          renewalId: renewalId,
          category: category,
        );
        if (doc != null) docs.add(doc);
      }
    } else if (source == ImageSource.camera || source == ImageSource.gallery) {
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        final doc = await _copyFile(
          picked.path,
          p.basename(picked.path),
          isImage: true,
          renewalId: renewalId,
          category: category,
        );
        if (doc != null) docs.add(doc);
      }
    }
    return docs;
  }

  static Future<EventDocument?> copyFromPath({
    required String sourcePath,
    required String name,
    bool isImage = false,
    String? renewalId,
    VaultDocumentCategory category = VaultDocumentCategory.other,
  }) {
    return _copyFile(
      sourcePath,
      name,
      isImage: isImage,
      renewalId: renewalId,
      category: category,
    );
  }

  static Future<EventDocument?> _copyFile(
    String sourcePath,
    String name, {
    required bool isImage,
    String? renewalId,
    VaultDocumentCategory category = VaultDocumentCategory.other,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final prefix = renewalId != null ? 'event_$renewalId' : 'vault';
      final destPath = p.join(
        dir.path,
        '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$name',
      );
      await File(sourcePath).copy(destPath);
      final size = await File(destPath).length();
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      return EventDocument(
        id: id,
        path: destPath,
        name: name,
        isImage: isImage,
        addedAt: DateTime.now(),
        category: category,
        sizeBytes: size,
        fileType: VaultFileType.fromPath(destPath, isImage: isImage),
        linkedRenewalIds: renewalId != null ? [renewalId] : const [],
      );
    } catch (_) {
      return null;
    }
  }
}
