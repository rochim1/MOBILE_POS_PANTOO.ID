import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' as sqlcipher;
import 'package:path/path.dart';
import '../../../core/database/database_platform_initializer.dart';

class PosLocalDatabase {
  static final PosLocalDatabase instance = PosLocalDatabase._init();
  static Database? _database;
  static Future<Database>? _databaseFuture;
  static const _databaseKeyName = 'pos_database_key_v1';
  static const _schemaVersion = 16;
  static const _secureStorage = FlutterSecureStorage();

  PosLocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _databaseFuture ??= _initDB('pos_pantoo.db');
    try {
      _database = await _databaseFuture!;
    } catch (_) {
      _databaseFuture = null;
      rethrow;
    }
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Jangan hanya bergantung pada bootstrap. Database juga dapat dipanggil
    // lebih awal oleh sinkronisasi, test, atau setelah hot reload desktop.
    initializePlatformDatabase();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    if (!Platform.isAndroid && !Platform.isIOS) {
      return openDatabase(
        path,
        version: _schemaVersion,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      );
    }

    final password = await _databasePassword();
    if (await _isPlaintextDatabase(path)) {
      await _migratePlaintextDatabase(path, password);
    }
    return _openEncryptedDatabase(path, password);
  }

  Future<String> _databasePassword() async {
    final existing = await _secureStorage.read(key: _databaseKeyName);
    if (existing != null && existing.length >= 32) return existing;
    final random = Random.secure();
    final key = base64UrlEncode(
      List<int>.generate(48, (_) => random.nextInt(256)),
    );
    await _secureStorage.write(key: _databaseKeyName, value: key);
    return key;
  }

  Future<bool> _isPlaintextDatabase(String path) async {
    final file = File(path);
    if (!await file.exists()) return false;
    final handle = await file.open();
    try {
      final header = await handle.read(16);
      return utf8.decode(header, allowMalformed: true) ==
          'SQLite format 3\u0000';
    } finally {
      await handle.close();
    }
  }

  Future<Database> _openEncryptedDatabase(String path, String password) {
    return sqlcipher.openDatabase(
      path,
      password: password,
      version: _schemaVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _migratePlaintextDatabase(String path, String password) async {
    final backupPath = '$path.plaintext-backup';
    final backup = File(backupPath);
    if (await backup.exists()) {
      throw StateError(
        'Backup database plaintext masih tersedia. Pemulihan manual diperlukan.',
      );
    }

    final legacy = await openDatabase(
      path,
      version: _schemaVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
    const tables = <String>[
      'products',
      'customers',
      'stores',
      'employees',
      'offline_transactions',
      'held_orders',
    ];
    final rows = <String, List<Map<String, Object?>>>{};
    try {
      await legacy.execute('PRAGMA wal_checkpoint(FULL)');
      for (final table in tables) {
        rows[table] = await legacy.query(table);
      }
    } finally {
      await legacy.close();
    }

    await File(path).rename(backupPath);
    const sidecarSuffixes = ['-wal', '-shm', '-journal'];
    final movedSidecars = <({String original, String backup})>[];
    try {
      for (final suffix in sidecarSuffixes) {
        final originalSidecar = File('$path$suffix');
        if (!await originalSidecar.exists()) continue;
        final backupSidecarPath = '$backupPath$suffix';
        await originalSidecar.rename(backupSidecarPath);
        movedSidecars.add((
          original: '$path$suffix',
          backup: backupSidecarPath,
        ));
      }
    } catch (_) {
      for (final sidecar in movedSidecars.reversed) {
        final file = File(sidecar.backup);
        if (await file.exists()) await file.rename(sidecar.original);
      }
      if (await backup.exists()) await backup.rename(path);
      rethrow;
    }
    Database? encrypted;
    try {
      encrypted = await _openEncryptedDatabase(path, password);
      await encrypted.transaction((txn) async {
        for (final table in tables) {
          for (final row in rows[table] ?? const []) {
            await txn.insert(
              table,
              row,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      });
      for (final table in tables) {
        final count = Sqflite.firstIntValue(
          await encrypted.rawQuery('SELECT COUNT(*) FROM $table'),
        );
        if (count != (rows[table]?.length ?? 0)) {
          throw StateError('Verifikasi migrasi database gagal pada $table');
        }
      }
      await encrypted.close();
      encrypted = null;
      await backup.delete();
      for (final sidecar in movedSidecars) {
        final file = File(sidecar.backup);
        if (await file.exists()) await file.delete();
      }
    } catch (_) {
      await encrypted?.close();
      final failedEncrypted = File(path);
      if (await failedEncrypted.exists()) await failedEncrypted.delete();
      if (await backup.exists()) await backup.rename(path);
      for (final sidecar in movedSidecars) {
        final file = File(sidecar.backup);
        if (await file.exists()) await file.rename(sidecar.original);
      }
      rethrow;
    }
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';

    if (oldVersion < 2) {
      await db.execute('''
CREATE TABLE IF NOT EXISTS employees (
  id $idType,
  name $textType,
  role $textType,
  pin $textType
)
''');
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE stores ADD COLUMN branchId TEXT NOT NULL DEFAULT ""',
      );
      await db.execute(
        'ALTER TABLE offline_transactions ADD COLUMN error TEXT',
      );
      await db.execute(
        'ALTER TABLE offline_transactions ADD COLUMN attempts INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        "UPDATE offline_transactions SET status = 'pending' WHERE status = 'syncing'",
      );
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE offline_transactions ADD COLUMN instansi_id TEXT NOT NULL DEFAULT ""',
      );
      await db.execute(
        'ALTER TABLE offline_transactions ADD COLUMN toko_id TEXT NOT NULL DEFAULT ""',
      );
      await db.execute(
        'ALTER TABLE offline_transactions ADD COLUMN shift_id TEXT NOT NULL DEFAULT ""',
      );
    }
    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN sku TEXT NOT NULL DEFAULT ""',
      );
      await db.execute(
        'ALTER TABLE products ADD COLUMN barcode TEXT NOT NULL DEFAULT ""',
      );
    }
    if (oldVersion < 6) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN image_url TEXT NOT NULL DEFAULT ""',
      );
    }
    if (oldVersion < 7) {
      await _createHeldOrdersTable(db);
    }
    if (oldVersion < 8) {
      await db.execute(
        'ALTER TABLE offline_transactions ADD COLUMN client_transaction_id TEXT NOT NULL DEFAULT ""',
      );
      await db.execute('''
UPDATE offline_transactions
SET client_transaction_id = CAST(id AS TEXT)
WHERE client_transaction_id = ''
''');
      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_offline_transactions_client_id ON offline_transactions(instansi_id, client_transaction_id)',
      );
    }
    if (oldVersion < 9) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN product_type TEXT NOT NULL DEFAULT "product"',
      );
      await db.execute(
        'ALTER TABLE products ADD COLUMN promo_eligible INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 10) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN tracks_stock INTEGER NOT NULL DEFAULT 1',
      );
    }
    if (oldVersion < 11) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN base_unit TEXT NOT NULL DEFAULT "unit"',
      );
      await db.execute(
        'ALTER TABLE products ADD COLUMN unit_conversions TEXT NOT NULL DEFAULT "[]"',
      );
      // Cache versi lama tidak menyimpan satuan asli. Menghapusnya lebih aman
      // daripada mengirim "unit" dan menghasilkan harga/stok yang keliru.
      await db.delete('products');
    }
    if (oldVersion < 12) {
      await db.execute(
        'ALTER TABLE customers ADD COLUMN email TEXT NOT NULL DEFAULT ""',
      );
    }
    if (oldVersion < 13) {
      await db.execute(
        'ALTER TABLE customers ADD COLUMN price_level TEXT NOT NULL DEFAULT "retail"',
      );
      await db.execute(
        'ALTER TABLE customers ADD COLUMN customer_segment TEXT NOT NULL DEFAULT "regular"',
      );
    }
    if (oldVersion < 14) {
      await db.execute(
        'ALTER TABLE offline_transactions ADD COLUMN server_response TEXT',
      );
      await db.execute(
        'ALTER TABLE offline_transactions ADD COLUMN resolution TEXT',
      );
      await db.execute(
        'ALTER TABLE offline_transactions ADD COLUMN resolved_at TEXT',
      );
      await db.execute('''
UPDATE offline_transactions
SET status = 'rejected'
WHERE status = 'failed_permanent'
''');
    }
    if (oldVersion < 15) {
      await db.execute(
        'ALTER TABLE offline_transactions ADD COLUMN client_snapshot TEXT',
      );
    }
    if (oldVersion < 16) {
      await db.execute('''
CREATE TABLE employees_secure (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  role TEXT NOT NULL
)
''');
      await db.execute('''
INSERT INTO employees_secure (id, name, role)
SELECT id, name, role FROM employees
''');
      await db.execute('DROP TABLE employees');
      await db.execute('ALTER TABLE employees_secure RENAME TO employees');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE products (
  id $idType,
  code $textType,
  name $textType,
  category $textType,
  price $realType,
  stock $intType
  ,sku TEXT NOT NULL DEFAULT ''
  ,barcode TEXT NOT NULL DEFAULT ''
  ,image_url TEXT NOT NULL DEFAULT ''
  ,product_type TEXT NOT NULL DEFAULT 'product'
  ,promo_eligible INTEGER NOT NULL DEFAULT 0
  ,tracks_stock INTEGER NOT NULL DEFAULT 1
  ,base_unit TEXT NOT NULL DEFAULT 'unit'
  ,unit_conversions TEXT NOT NULL DEFAULT '[]'
)
''');

    await db.execute('''
CREATE TABLE customers (
  id $idType,
  name $textType,
  phone $textType,
  email TEXT NOT NULL DEFAULT '',
  price_level TEXT NOT NULL DEFAULT 'retail',
  customer_segment TEXT NOT NULL DEFAULT 'regular'
)
''');

    await db.execute('''
CREATE TABLE stores (
  id $idType,
  name $textType,
  status $textType,
  address $textType,
  phone $textType,
  branchName $textType
  ,branchId $textType
)
''');

    await db.execute('''
CREATE TABLE employees (
  id $idType,
  name $textType,
  role $textType
)
''');

    await db.execute('''
CREATE TABLE offline_transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  payload $textType,
  status $textType,
  timestamp $textType
  ,error TEXT
  ,attempts INTEGER NOT NULL DEFAULT 0
  ,instansi_id TEXT NOT NULL DEFAULT ''
  ,toko_id TEXT NOT NULL DEFAULT ''
  ,shift_id TEXT NOT NULL DEFAULT ''
  ,client_transaction_id TEXT NOT NULL DEFAULT ''
  ,server_response TEXT
  ,resolution TEXT
  ,resolved_at TEXT
  ,client_snapshot TEXT
)
''');
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_offline_transactions_client_id ON offline_transactions(instansi_id, client_transaction_id)',
    );
    await _createHeldOrdersTable(db);
  }

  Future<void> _createHeldOrdersTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS held_orders (
  id TEXT PRIMARY KEY,
  payload TEXT NOT NULL,
  user_key TEXT NOT NULL,
  store_id TEXT NOT NULL,
  shift_id TEXT NOT NULL,
  created_at TEXT NOT NULL
)
''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_held_orders_scope ON held_orders(user_key, store_id, shift_id)',
    );
  }

  Future close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
    _databaseFuture = null;
  }
}
