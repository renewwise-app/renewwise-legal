enum BackupFrequency {
  disabled('Disabled'),
  manual('Manual only'),
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly');

  const BackupFrequency(this.label);
  final String label;
}

enum BackupStatus {
  notConnected('Not Connected'),
  protected('Protected'),
  pending('Backup Pending'),
  failed('Backup Failed');

  const BackupStatus(this.label);
  final String label;
}

enum RestoreConflictMode {
  merge('Merge', 'Keep local data and add anything missing from the backup.'),
  replace('Replace Local', 'Replace all local data with the backup.'),
  cancel('Cancel', 'Do nothing.');

  const RestoreConflictMode(this.label, this.description);
  final String label;
  final String description;
}

class BackupManifest {
  const BackupManifest({
    required this.formatVersion,
    required this.appVersion,
    required this.backupDate,
    required this.deviceName,
    required this.databaseVersion,
    required this.encrypted,
    this.renewalCount = 0,
    this.documentCount = 0,
    this.historyCount = 0,
  });

  static const currentFormatVersion = 1;

  final int formatVersion;
  final String appVersion;
  final DateTime backupDate;
  final String deviceName;
  final int databaseVersion;
  final bool encrypted;
  final int renewalCount;
  final int documentCount;
  final int historyCount;

  Map<String, dynamic> toJson() => {
        'formatVersion': formatVersion,
        'appVersion': appVersion,
        'backupDate': backupDate.toIso8601String(),
        'deviceName': deviceName,
        'databaseVersion': databaseVersion,
        'encrypted': encrypted,
        'renewalCount': renewalCount,
        'documentCount': documentCount,
        'historyCount': historyCount,
      };

  factory BackupManifest.fromJson(Map<String, dynamic> json) => BackupManifest(
        formatVersion: json['formatVersion'] as int? ?? 1,
        appVersion: json['appVersion'] as String? ?? 'unknown',
        backupDate: DateTime.parse(json['backupDate'] as String),
        deviceName: json['deviceName'] as String? ?? 'Unknown',
        databaseVersion: json['databaseVersion'] as int? ?? 1,
        encrypted: json['encrypted'] as bool? ?? true,
        renewalCount: json['renewalCount'] as int? ?? 0,
        documentCount: json['documentCount'] as int? ?? 0,
        historyCount: json['historyCount'] as int? ?? 0,
      );
}

class DriveBackupEntry {
  const DriveBackupEntry({
    required this.id,
    required this.name,
    required this.createdTime,
    required this.sizeBytes,
    this.deviceName,
    this.appVersion,
  });

  final String id;
  final String name;
  final DateTime createdTime;
  final int sizeBytes;
  final String? deviceName;
  final String? appVersion;
}

class BackupProgress {
  const BackupProgress({
    required this.stage,
    required this.fraction,
    this.message,
  });

  final String stage;
  final double fraction;
  final String? message;
}

enum BackupErrorKind {
  noInternet,
  authExpired,
  driveUnavailable,
  storageFull,
  permissionDenied,
  encryptionFailed,
  unknown,
}

class BackupException implements Exception {
  BackupException(this.kind, this.message);
  final BackupErrorKind kind;
  final String message;

  @override
  String toString() => message;
}
