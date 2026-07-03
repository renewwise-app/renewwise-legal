import 'dart:convert';
import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:renew_wise/models/backup_models.dart';

/// Uploads encrypted backups to the user's Google Drive folder:
/// RenewWise → Backups (visible, user-owned storage).
class GoogleDriveBackupClient {
  GoogleDriveBackupClient({
    GoogleSignIn? googleSignIn,
  }) : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: [drive.DriveApi.driveFileScope],
            );

  final GoogleSignIn _googleSignIn;

  static const _rootFolderName = 'RenewWise';
  static const _backupFolderName = 'Backups';
  static const _backupPrefix = 'renewwise_backup_';
  static const _backupExt = '.rwbackup';

  bool _simulateOffline = false;
  bool _simulateFailure = false;

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  void setSimulateOffline(bool value) => _simulateOffline = value;
  void setSimulateFailure(bool value) => _simulateFailure = value;

  Future<GoogleSignInAccount?> signIn() async {
    if (_simulateOffline) {
      throw BackupException(
        BackupErrorKind.driveUnavailable,
        'Google Drive appears offline. Check your connection and try again.',
      );
    }
    try {
      return await _googleSignIn.signIn();
    } on Exception catch (e) {
      throw BackupException(
        BackupErrorKind.permissionDenied,
        'Could not connect Google account: $e',
      );
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<GoogleSignInAccount?> signInSilently() =>
      _googleSignIn.signInSilently();

  Future<bool> ensureSignedIn() async {
    if (_googleSignIn.currentUser != null) return true;
    final account = await signIn();
    return account != null;
  }

  Future<drive.DriveApi> _driveApi() async {
    if (_simulateOffline) {
      throw BackupException(
        BackupErrorKind.driveUnavailable,
        'Google Drive is unavailable right now.',
      );
    }
    if (_simulateFailure) {
      throw BackupException(
        BackupErrorKind.unknown,
        'Simulated backup failure (developer mode).',
      );
    }

    var account = _googleSignIn.currentUser;
    account ??= await _googleSignIn.signInSilently();
    if (account == null) {
      throw BackupException(
        BackupErrorKind.authExpired,
        'Google sign-in expired. Please connect your account again.',
      );
    }

    final client = await _googleSignIn.authenticatedClient();
    if (client == null) {
      throw BackupException(
        BackupErrorKind.authExpired,
        'Google sign-in expired. Please connect your account again.',
      );
    }
    return drive.DriveApi(client);
  }

  Future<String> _ensureBackupFolder(drive.DriveApi api) async {
    final renewWiseId = await _findOrCreateFolder(
      api,
      name: _rootFolderName,
      parentId: null,
    );
    return _findOrCreateFolder(
      api,
      name: _backupFolderName,
      parentId: renewWiseId,
    );
  }

  Future<String> _findOrCreateFolder(
    drive.DriveApi api, {
    required String name,
    required String? parentId,
  }) async {
    final parentClause =
        parentId == null ? "'root' in parents" : "'$parentId' in parents";
    final q =
        "name = '$name' and mimeType = 'application/vnd.google-apps.folder' "
        "and trashed = false and $parentClause";
    final found = await api.files.list(
      q: q,
      spaces: 'drive',
      $fields: 'files(id,name)',
    );
    if (found.files != null && found.files!.isNotEmpty) {
      return found.files!.first.id!;
    }

    final folder = drive.File()
      ..name = name
      ..mimeType = 'application/vnd.google-apps.folder';
    if (parentId != null) {
      folder.parents = [parentId];
    }
    final created = await api.files.create(
      folder,
      $fields: 'id',
    );
    return created.id!;
  }

  Future<DriveBackupEntry> uploadBackup({
    required List<int> encryptedBytes,
    required BackupManifest manifest,
  }) async {
    final api = await _driveApi();
    final folderId = await _ensureBackupFolder(api);
    final stamp = manifest.backupDate.toUtc().toIso8601String().replaceAll(':', '-');
    final fileName = '$_backupPrefix$stamp$_backupExt';

    final description = jsonEncode({
      'deviceName': manifest.deviceName,
      'appVersion': manifest.appVersion,
      'databaseVersion': manifest.databaseVersion,
    });

    final media = drive.Media(
      Stream.value(encryptedBytes),
      encryptedBytes.length,
    );
    final file = drive.File()
      ..name = fileName
      ..description = description
      ..parents = [folderId];

    try {
      final uploaded = await api.files.create(
        file,
        uploadMedia: media,
        $fields: 'id,name,size,createdTime,description',
      );
      return DriveBackupEntry(
        id: uploaded.id!,
        name: uploaded.name ?? fileName,
        createdTime: uploaded.createdTime ?? manifest.backupDate,
        sizeBytes: int.tryParse(uploaded.size ?? '${encryptedBytes.length}') ??
            encryptedBytes.length,
        deviceName: manifest.deviceName,
        appVersion: manifest.appVersion,
      );
    } on SocketException {
      throw BackupException(
        BackupErrorKind.noInternet,
        'No internet connection. Connect to Wi‑Fi or mobile data and try again.',
      );
    } catch (e) {
      throw BackupException(
        BackupErrorKind.driveUnavailable,
        'Google Drive upload failed: $e',
      );
    }
  }

  Future<List<DriveBackupEntry>> listBackups() async {
    final api = await _driveApi();
    final folderId = await _ensureBackupFolder(api);
    final response = await api.files.list(
      q: "'$folderId' in parents and trashed = false and name contains '$_backupPrefix'",
      orderBy: 'createdTime desc',
      spaces: 'drive',
      $fields: 'files(id,name,size,createdTime,description)',
    );
    final files = response.files ?? [];
    return files.map((f) {
      Map<String, dynamic>? meta;
      if (f.description != null && f.description!.isNotEmpty) {
        try {
          meta = jsonDecode(f.description!) as Map<String, dynamic>;
        } catch (_) {}
      }
      return DriveBackupEntry(
        id: f.id!,
        name: f.name ?? '',
        createdTime: f.createdTime ?? DateTime.now(),
        sizeBytes: int.tryParse(f.size ?? '0') ?? 0,
        deviceName: meta?['deviceName'] as String?,
        appVersion: meta?['appVersion'] as String?,
      );
    }).toList();
  }

  Future<List<int>> downloadBackup(String fileId) async {
    final api = await _driveApi();
    try {
      final media = await api.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;
      return media.stream.toList().then((chunks) {
        final out = <int>[];
        for (final c in chunks) {
          out.addAll(c);
        }
        return out;
      });
    } on SocketException {
      throw BackupException(
        BackupErrorKind.noInternet,
        'No internet connection. Connect to Wi‑Fi or mobile data and try again.',
      );
    } catch (e) {
      throw BackupException(
        BackupErrorKind.driveUnavailable,
        'Google Drive download failed: $e',
      );
    }
  }

  Future<int> totalBackupStorageBytes() async {
    final entries = await listBackups();
    return entries.fold<int>(0, (sum, e) => sum + e.sizeBytes);
  }

  Future<void> deleteBackup(String fileId) async {
    final api = await _driveApi();
    await api.files.delete(fileId);
  }

  Future<void> deleteAllBackups() async {
    final entries = await listBackups();
    for (final entry in entries) {
      await deleteBackup(entry.id);
    }
  }
}

/// Local mirror for tests and when Google Sign-In is unavailable.
class LocalDriveBackupClient {
  LocalDriveBackupClient();

  static const _backupExt = '.rwbackup';
  String? _connectedEmail;

  bool _simulateOffline = false;
  bool _simulateFailure = false;

  void setSimulateOffline(bool value) => _simulateOffline = value;
  void setSimulateFailure(bool value) => _simulateFailure = value;

  String? get connectedEmail => _connectedEmail;

  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(
      p.join(base.path, 'RenewWise', 'Backups'),
    );
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> signIn({String email = 'local@renewwise.dev'}) async {
    if (_simulateOffline) {
      throw BackupException(
        BackupErrorKind.driveUnavailable,
        'Drive offline (simulated).',
      );
    }
    _connectedEmail = email;
  }

  Future<void> signOut() async {
    _connectedEmail = null;
  }

  bool get isConnected => _connectedEmail != null;

  Future<DriveBackupEntry> uploadBackup({
    required List<int> encryptedBytes,
    required BackupManifest manifest,
  }) async {
    if (_simulateFailure) {
      throw BackupException(
        BackupErrorKind.unknown,
        'Simulated backup failure.',
      );
    }
    if (!isConnected) {
      throw BackupException(
        BackupErrorKind.authExpired,
        'Not connected to backup storage.',
      );
    }
    final dir = await _dir();
    final stamp =
        manifest.backupDate.toUtc().toIso8601String().replaceAll(':', '-');
    final name = 'renewwise_backup_$stamp$_backupExt';
    final file = File(p.join(dir.path, name));
    await file.writeAsBytes(encryptedBytes);
    final metaFile = File('${file.path}.meta.json');
    await metaFile.writeAsString(jsonEncode(manifest.toJson()));
    return DriveBackupEntry(
      id: name,
      name: name,
      createdTime: manifest.backupDate,
      sizeBytes: encryptedBytes.length,
      deviceName: manifest.deviceName,
      appVersion: manifest.appVersion,
    );
  }

  Future<List<DriveBackupEntry>> listBackups() async {
    final dir = await _dir();
    if (!await dir.exists()) return [];
    final files = <File>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith(_backupExt)) {
        files.add(entity);
      }
    }
    files.sort((a, b) => b.path.compareTo(a.path));
    final entries = <DriveBackupEntry>[];
    for (final file in files) {
      BackupManifest? manifest;
      final meta = File('${file.path}.meta.json');
      if (await meta.exists()) {
        try {
          manifest = BackupManifest.fromJson(
            jsonDecode(await meta.readAsString()) as Map<String, dynamic>,
          );
        } catch (_) {}
      }
      entries.add(
        DriveBackupEntry(
          id: p.basename(file.path),
          name: p.basename(file.path),
          createdTime: manifest?.backupDate ??
              (await file.lastModified()),
          sizeBytes: await file.length(),
          deviceName: manifest?.deviceName,
          appVersion: manifest?.appVersion,
        ),
      );
    }
    return entries;
  }

  Future<List<int>> downloadBackup(String fileId) async {
    final dir = await _dir();
    final file = File(p.join(dir.path, fileId));
    if (!await file.exists()) {
      throw BackupException(
        BackupErrorKind.driveUnavailable,
        'Backup file not found.',
      );
    }
    return file.readAsBytes();
  }

  Future<int> totalBackupStorageBytes() async {
    final entries = await listBackups();
    return entries.fold<int>(0, (s, e) => s + e.sizeBytes);
  }

  Future<void> deleteBackup(String fileId) async {
    final dir = await _dir();
    final file = File(p.join(dir.path, fileId));
    if (await file.exists()) await file.delete();
    final meta = File('${file.path}.meta.json');
    if (await meta.exists()) await meta.delete();
  }

  Future<void> deleteAllBackups() async {
    for (final entry in await listBackups()) {
      await deleteBackup(entry.id);
    }
  }
}

/// Lightweight connectivity probe before Drive calls.
Future<void> assertNetworkReachable() async {
  try {
    final response = await http
        .head(Uri.parse('https://www.google.com'))
        .timeout(const Duration(seconds: 5));
    if (response.statusCode >= 500) {
      throw BackupException(
        BackupErrorKind.noInternet,
        'No internet connection. Connect to Wi‑Fi or mobile data and try again.',
      );
    }
  } on SocketException {
    throw BackupException(
      BackupErrorKind.noInternet,
      'No internet connection. Connect to Wi‑Fi or mobile data and try again.',
    );
  } on Exception {
    // Captive portals may block HEAD; allow Drive client to fail later.
  }
}
