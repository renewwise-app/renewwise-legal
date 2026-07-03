import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:renew_wise/database/database_helper.dart';
import 'package:renew_wise/models/backup_models.dart';
import 'package:renew_wise/models/event_document.dart';
import 'package:renew_wise/services/assistant_draft_service.dart';
import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';

/// Builds and parses ZIP backup bundles (before encryption).
class BackupBundleService {
  BackupBundleService({
    required this.renewalService,
    required this.reminderStateService,
    required this.eventExtrasService,
    required this.assistantDraftService,
    required this.settingsService,
  });

  final RenewalService renewalService;
  final ReminderStateService reminderStateService;
  final EventExtrasService eventExtrasService;
  final AssistantDraftService assistantDraftService;
  final SettingsService settingsService;

  static const _manifestPath = 'manifest.json';
  static const _dataPrefix = 'data/';
  static const _filesPrefix = 'files/';

  Future<({Uint8List zipBytes, BackupManifest manifest})> buildBundle({
    void Function(BackupProgress progress)? onProgress,
  }) async {
    onProgress?.call(
      const BackupProgress(stage: 'Collecting data', fraction: 0.1),
    );

    final packageInfo = await PackageInfo.fromPlatform();
    final deviceName = await _deviceName();
    final renewals = await renewalService.exportRenewalRows();
    final reminder = reminderStateService.exportSnapshot();
    final vault = eventExtrasService.exportSnapshot();
    final draft = assistantDraftService.exportSnapshot();
    final settings = settingsService.exportBackupSettings();
    final stats = renewalService.exportStatisticsSnapshot();

    final manifest = BackupManifest(
      formatVersion: BackupManifest.currentFormatVersion,
      appVersion: packageInfo.version,
      backupDate: DateTime.now(),
      deviceName: deviceName,
      databaseVersion: DatabaseHelper.version,
      encrypted: true,
      renewalCount: renewals.length,
      documentCount: eventExtrasService.totalDocumentCount,
      historyCount: reminderStateService.history.length,
    );

    onProgress?.call(
      const BackupProgress(stage: 'Packing files', fraction: 0.35),
    );

    final archive = Archive();
    archive.addFile(
      ArchiveFile(
        _manifestPath,
        utf8.encode(jsonEncode(manifest.toJson())).length,
        utf8.encode(jsonEncode(manifest.toJson())),
      ),
    );
    _addJson(archive, '${_dataPrefix}renewals.json', renewals);
    _addJson(archive, '${_dataPrefix}reminder_states.json', reminder);
    _addJson(archive, '${_dataPrefix}vault.json', vault);
    _addJson(archive, '${_dataPrefix}assistant_draft.json', draft ?? <String, dynamic>{});
    _addJson(archive, '${_dataPrefix}settings.json', settings);
    _addJson(archive, '${_dataPrefix}statistics.json', stats);

    final docs = eventExtrasService.allDocuments;
    var fileIndex = 0;
    for (final doc in docs) {
      if (doc.path.startsWith('demo://')) continue;
      final file = File(doc.path);
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      final safeName = _fileEntryName(doc);
      archive.addFile(
        ArchiveFile('$_filesPrefix$safeName', bytes.length, bytes),
      );
      fileIndex++;
      onProgress?.call(
        BackupProgress(
          stage: 'Packing documents',
          fraction: 0.35 + (0.45 * fileIndex / (docs.length.clamp(1, 999))),
        ),
      );
    }

    onProgress?.call(
      const BackupProgress(stage: 'Compressing', fraction: 0.85),
    );
    final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive));
    onProgress?.call(
      const BackupProgress(stage: 'Done', fraction: 1.0),
    );
    return (zipBytes: zipBytes, manifest: manifest);
  }

  Future<BackupManifest> parseManifest(Uint8List zipBytes) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    final manifestFile = archive.files.firstWhere(
      (f) => f.name == _manifestPath,
      orElse: () => throw StateError('Backup missing manifest'),
    );
    return BackupManifest.fromJson(
      jsonDecode(utf8.decode(manifestFile.content)) as Map<String, dynamic>,
    );
  }

  Future<void> applyBundle(
    Uint8List zipBytes, {
    required RestoreConflictMode mode,
    void Function(BackupProgress progress)? onProgress,
  }) async {
    onProgress?.call(
      const BackupProgress(stage: 'Reading backup', fraction: 0.05),
    );
    final archive = ZipDecoder().decodeBytes(zipBytes);

    Map<String, dynamic> readJson(String name) {
      final file = archive.files.firstWhere(
        (f) => f.name == name,
        orElse: () => throw StateError('Missing $name'),
      );
      return jsonDecode(utf8.decode(file.content)) as Map<String, dynamic>;
    }

    List<Map<String, dynamic>> readRows(String name) {
      final file = archive.files.where((f) => f.name == name).firstOrNull;
      if (file == null) return [];
      final decoded = jsonDecode(utf8.decode(file.content));
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    }

    onProgress?.call(
      const BackupProgress(stage: 'Restoring events', fraction: 0.2),
    );
    await renewalService.importRenewalRows(
      readRows('${_dataPrefix}renewals.json'),
      mode: mode,
    );

    onProgress?.call(
      const BackupProgress(stage: 'Restoring reminders & history', fraction: 0.4),
    );
    final reminderRaw = readJson('${_dataPrefix}reminder_states.json');
    await reminderStateService.importSnapshot(reminderRaw, mode: mode);

    onProgress?.call(
      const BackupProgress(stage: 'Restoring vault', fraction: 0.55),
    );
    final vaultRaw = readJson('${_dataPrefix}vault.json');
    await eventExtrasService.importSnapshot(vaultRaw, mode: mode);

    onProgress?.call(
      const BackupProgress(stage: 'Restoring documents', fraction: 0.7),
    );
    await _restoreDocumentFiles(archive);

    onProgress?.call(
      const BackupProgress(stage: 'Restoring settings & drafts', fraction: 0.85),
    );
    final settingsRaw = archive.files
        .where((f) => f.name == '${_dataPrefix}settings.json')
        .firstOrNull;
    if (settingsRaw != null && mode == RestoreConflictMode.replace) {
      await settingsService.importBackupSettings(
        jsonDecode(utf8.decode(settingsRaw.content)) as Map<String, dynamic>,
      );
    }

    final draftRaw = archive.files
        .where((f) => f.name == '${_dataPrefix}assistant_draft.json')
        .firstOrNull;
    if (draftRaw != null) {
      final decoded = jsonDecode(utf8.decode(draftRaw.content));
      if (decoded is Map<String, dynamic> && decoded.isNotEmpty) {
        await assistantDraftService.importSnapshot(decoded, mode: mode);
      } else if (mode == RestoreConflictMode.replace) {
        await assistantDraftService.clearForBackupReplace();
      }
    }

    onProgress?.call(
      const BackupProgress(stage: 'Complete', fraction: 1.0),
    );
  }

  Future<void> _restoreDocumentFiles(Archive archive) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory(p.join(docsDir.path, 'vault_restored'));
    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }

    for (final file in archive.files) {
      if (!file.name.startsWith(_filesPrefix) || file.isFile == false) continue;
      final entryName = file.name.substring(_filesPrefix.length);
      final docId = entryName.split('__').first;
      final doc = eventExtrasService.documentById(docId);
      if (doc == null) continue;

      final outPath = p.join(vaultDir.path, '${doc.id}_${doc.name}');
      await File(outPath).writeAsBytes(file.content as List<int>);
      await eventExtrasService.remapDocumentPath(doc.id, outPath);
    }
  }

  void _addJson(Archive archive, String path, Object data) {
    final bytes = utf8.encode(jsonEncode(data));
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  String _fileEntryName(EventDocument doc) =>
      '${doc.id}__${doc.name.replaceAll('/', '_')}';

  Future<String> _deviceName() async {
    final plugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await plugin.androidInfo;
      return '${info.brand} ${info.model}';
    }
    if (Platform.isIOS) {
      final info = await plugin.iosInfo;
      return info.name;
    }
    return 'RenewWise Device';
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
