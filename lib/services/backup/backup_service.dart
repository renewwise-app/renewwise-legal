import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import 'package:renew_wise/models/backup_models.dart';
import 'package:renew_wise/services/assistant_draft_service.dart';
import 'package:renew_wise/services/backup/backup_bundle_service.dart';
import 'package:renew_wise/services/backup/backup_encryption_service.dart';
import 'package:renew_wise/services/backup/google_drive_backup_client.dart';
import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';

/// Orchestrates encrypted backup to the user's own Google Drive.
class BackupService extends ChangeNotifier {
  BackupService({
    required this.settingsService,
    required this.renewalService,
    required this.reminderStateService,
    required this.eventExtrasService,
    required this.assistantDraftService,
    GoogleDriveBackupClient? googleDrive,
    LocalDriveBackupClient? localDrive,
    BackupEncryptionService? encryption,
    BackupBundleService? bundle,
    bool forceLocalDrive = false,
  })  : _googleDrive = googleDrive ?? GoogleDriveBackupClient(),
        _localDrive = localDrive ?? LocalDriveBackupClient(),
        _encryption = encryption ?? BackupEncryptionService(),
        _bundle = bundle ??
            BackupBundleService(
              renewalService: renewalService,
              reminderStateService: reminderStateService,
              eventExtrasService: eventExtrasService,
              assistantDraftService: assistantDraftService,
              settingsService: settingsService,
            ),
        _useLocalDrive = forceLocalDrive ||
            kIsWeb ||
            Platform.environment.containsKey('FLUTTER_TEST');

  final SettingsService settingsService;
  final RenewalService renewalService;
  final ReminderStateService reminderStateService;
  final EventExtrasService eventExtrasService;
  final AssistantDraftService assistantDraftService;

  final GoogleDriveBackupClient _googleDrive;
  final LocalDriveBackupClient _localDrive;
  final BackupEncryptionService _encryption;
  final BackupBundleService _bundle;
  final bool _useLocalDrive;

  bool _busy = false;
  BackupProgress? _progress;
  String? _lastError;

  bool get isBusy => _busy;
  BackupProgress? get progress => _progress;
  String? get lastError => _lastError;

  bool get isConnected =>
      _useLocalDrive
          ? _localDrive.isConnected
          : _googleDrive.currentUser != null ||
              settingsService.backupConnectedEmail.isNotEmpty;

  BackupStatus get displayStatus {
    if (!isConnected) return BackupStatus.notConnected;
    if (_busy) return BackupStatus.pending;
    if (settingsService.backupStatus == BackupStatus.failed) {
      return BackupStatus.failed;
    }
    if (settingsService.backupLastAt != null) {
      return BackupStatus.protected;
    }
    return BackupStatus.pending;
  }

  Future<void> initialize() async {
    await settingsService.loadBackupPreferences();
    if (!_useLocalDrive) {
      try {
        final account =
            _googleDrive.currentUser ?? await _googleDrive.signInSilently();
        if (account != null) {
          await settingsService.setBackupConnectedEmail(account.email);
        }
      } catch (_) {}
    }
    notifyListeners();
  }

  void setSimulateFailure(bool value) {
    _googleDrive.setSimulateFailure(value);
    _localDrive.setSimulateFailure(value);
  }

  void setSimulateOffline(bool value) {
    _googleDrive.setSimulateOffline(value);
    _localDrive.setSimulateOffline(value);
  }

  Future<bool> connectGoogle() async {
    _lastError = null;
    try {
      if (_useLocalDrive) {
        await _localDrive.signIn(email: 'local@renewwise.dev');
        await settingsService.setBackupConnectedEmail('local@renewwise.dev');
      } else {
        await assertNetworkReachable();
        final account = await _googleDrive.signIn();
        if (account == null) return false;
        await settingsService.setBackupConnectedEmail(account.email);
      }
      await settingsService.setBackupStatus(BackupStatus.protected);
      await _refreshStorageUsed();
      notifyListeners();
      return true;
    } on BackupException catch (e) {
      _lastError = e.message;
      await settingsService.setBackupStatus(BackupStatus.failed);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (_useLocalDrive) {
      await _localDrive.signOut();
    } else {
      await _googleDrive.signOut();
    }
    await settingsService.setBackupConnectedEmail('');
    await settingsService.setBackupStatus(BackupStatus.notConnected);
    notifyListeners();
  }

  Future<void> _refreshStorageUsed() async {
    try {
      final bytes = _useLocalDrive
          ? await _localDrive.totalBackupStorageBytes()
          : await _googleDrive.totalBackupStorageBytes();
      await settingsService.setBackupStorageBytes(bytes);
    } catch (_) {}
  }

  Future<DriveBackupEntry?> runBackup({bool manual = true}) async {
    if (_busy) return null;
    if (!isConnected) {
      throw BackupException(
        BackupErrorKind.authExpired,
        'Connect your Google account before backing up.',
      );
    }
    if (!manual &&
        settingsService.backupFrequency == BackupFrequency.disabled) {
      return null;
    }

    _busy = true;
    _progress = const BackupProgress(stage: 'Starting', fraction: 0);
    _lastError = null;
    await settingsService.setBackupStatus(BackupStatus.pending);
    notifyListeners();

    try {
      if (!_useLocalDrive) await assertNetworkReachable();

      final built = await _bundle.buildBundle(
        onProgress: (p) {
          _progress = p;
          notifyListeners();
        },
      );

      final hash = sha256.convert(built.zipBytes).toString();
      if (!manual &&
          hash == settingsService.backupContentHash &&
          settingsService.backupLastAt != null) {
        _busy = false;
        _progress = null;
        await settingsService.setBackupStatus(BackupStatus.protected);
        notifyListeners();
        return null;
      }

      _progress = const BackupProgress(stage: 'Encrypting', fraction: 0.9);
      notifyListeners();
      final encrypted = await _encryption.encrypt(built.zipBytes);

      _progress = const BackupProgress(stage: 'Uploading', fraction: 0.95);
      notifyListeners();

      final entry = _useLocalDrive
          ? await _localDrive.uploadBackup(
              encryptedBytes: encrypted,
              manifest: built.manifest,
            )
          : await _googleDrive.uploadBackup(
              encryptedBytes: encrypted,
              manifest: built.manifest,
            );

      await settingsService.setBackupLastAt(DateTime.now());
      await settingsService.setBackupContentHash(hash);
      await settingsService.setBackupStatus(BackupStatus.protected);
      await _refreshStorageUsed();
      return entry;
    } on BackupException catch (e) {
      _lastError = e.message;
      await settingsService.setBackupStatus(BackupStatus.failed);
      rethrow;
    } catch (e) {
      _lastError = e.toString();
      await settingsService.setBackupStatus(BackupStatus.failed);
      throw BackupException(
        BackupErrorKind.unknown,
        'Backup failed: $e',
      );
    } finally {
      _busy = false;
      _progress = null;
      notifyListeners();
    }
  }

  Future<List<DriveBackupEntry>> listBackups() async {
    if (!isConnected) return [];
    if (_useLocalDrive) return _localDrive.listBackups();
    return _googleDrive.listBackups();
  }

  Future<void> restoreBackup(
    String fileId, {
    required RestoreConflictMode mode,
    void Function(BackupProgress)? onProgress,
  }) async {
    if (_busy) {
      throw BackupException(
        BackupErrorKind.unknown,
        'Another backup operation is in progress.',
      );
    }
    _busy = true;
    notifyListeners();
    try {
      final encrypted = _useLocalDrive
          ? await _localDrive.downloadBackup(fileId)
          : await _googleDrive.downloadBackup(fileId);
      final zipBytes = await _encryption.decrypt(Uint8List.fromList(encrypted));
      await _bundle.applyBundle(
        zipBytes,
        mode: mode,
        onProgress: (p) {
          _progress = p;
          onProgress?.call(p);
          notifyListeners();
        },
      );
      await renewalService.resyncAllReminders();
    } finally {
      _busy = false;
      _progress = null;
      notifyListeners();
    }
  }

  Future<void> deleteCloudBackups() async {
    if (_useLocalDrive) {
      await _localDrive.deleteAllBackups();
    } else {
      await _googleDrive.deleteAllBackups();
    }
    await settingsService.setBackupStorageBytes(0);
    notifyListeners();
  }

  Future<void> deleteBackup(String fileId) async {
    if (_useLocalDrive) {
      await _localDrive.deleteBackup(fileId);
    } else {
      await _googleDrive.deleteBackup(fileId);
    }
    await _refreshStorageUsed();
    notifyListeners();
  }

  Future<Uint8List> generateLocalTestBackup() async {
    final built = await _bundle.buildBundle();
    return _encryption.encrypt(built.zipBytes);
  }

  Future<void> restoreLocalTestBackup(Uint8List encrypted) async {
    final zip = await _encryption.decrypt(encrypted);
    await _bundle.applyBundle(zip, mode: RestoreConflictMode.replace);
    await renewalService.resyncAllReminders();
  }

  Future<void> maybeRunScheduledBackup() async {
    if (!isConnected) return;
    final freq = settingsService.backupFrequency;
    if (freq == BackupFrequency.disabled || freq == BackupFrequency.manual) {
      return;
    }
    final last = settingsService.backupLastAt;
    final now = DateTime.now();
    if (last != null) {
      final due = switch (freq) {
        BackupFrequency.daily => now.difference(last).inHours >= 24,
        BackupFrequency.weekly => now.difference(last).inDays >= 7,
        BackupFrequency.monthly => now.difference(last).inDays >= 28,
        _ => false,
      };
      if (!due) return;
    }
    await runBackup(manual: false);
  }

  String formatStorage(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
