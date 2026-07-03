import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Singleton that owns the SQLite connection.
/// All schema migrations are applied here by bumping [_dbVersion].
class DatabaseHelper {
  static const _dbName = 'renewwise.db';
  static const _dbVersion = 4;

  /// Current schema version (included in backup manifest).
  static int get version => _dbVersion;

  static final DatabaseHelper _instance = DatabaseHelper._();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE renewals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        renewal_date INTEGER NOT NULL,
        payment_required INTEGER NOT NULL DEFAULT 0,
        amount REAL,
        currency TEXT NOT NULL DEFAULT 'inr',
        importance TEXT NOT NULL DEFAULT 'important',
        priority TEXT NOT NULL DEFAULT 'medium',
        alert_style TEXT NOT NULL DEFAULT 'standard',
        status TEXT NOT NULL DEFAULT 'upcoming',
        repeat_cycle TEXT NOT NULL DEFAULT 'yearly',
        recurrence_end_type TEXT NOT NULL DEFAULT 'never',
        recurrence_end_date INTEGER,
        recurrence_occurrence_limit INTEGER,
        recurrence_completed_count INTEGER NOT NULL DEFAULT 0,
        reminder_schedule TEXT NOT NULL DEFAULT '30,7,1',
        notes TEXT,
        fund_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        custom_event_type TEXT,
        custom_reminder_dates TEXT,
        reminder_time_minutes INTEGER
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v1 → v2: add custom event type, custom reminder dates, reminder time
      await db.execute(
        'ALTER TABLE renewals ADD COLUMN custom_event_type TEXT',
      );
      await db.execute(
        'ALTER TABLE renewals ADD COLUMN custom_reminder_dates TEXT',
      );
      await db.execute(
        'ALTER TABLE renewals ADD COLUMN reminder_time_minutes INTEGER',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        "ALTER TABLE renewals ADD COLUMN alert_style TEXT DEFAULT 'standard'",
      );
    }
    if (oldVersion < 4) {
      await db.execute(
        "ALTER TABLE renewals ADD COLUMN recurrence_end_type TEXT DEFAULT 'never'",
      );
      await db.execute(
        'ALTER TABLE renewals ADD COLUMN recurrence_end_date INTEGER',
      );
      await db.execute(
        'ALTER TABLE renewals ADD COLUMN recurrence_occurrence_limit INTEGER',
      );
      await db.execute(
        'ALTER TABLE renewals ADD COLUMN recurrence_completed_count INTEGER DEFAULT 0',
      );
    }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
