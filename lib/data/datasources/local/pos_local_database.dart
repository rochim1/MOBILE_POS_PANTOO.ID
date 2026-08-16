import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../../core/database/database_platform_initializer.dart';

class PosLocalDatabase {
  static final PosLocalDatabase instance = PosLocalDatabase._init();
  static Database? _database;
  static Future<Database>? _databaseFuture;

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

    return await openDatabase(
      path,
      version: 13,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
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
  role $textType,
  pin $textType
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
