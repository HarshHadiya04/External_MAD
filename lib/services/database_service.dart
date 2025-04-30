import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:loyalty_card_wallet/models/loyalty_card.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'loyalty_cards.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE loyalty_cards(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        issuer TEXT NOT NULL,
        cardNumber TEXT NOT NULL,
        barcode TEXT NOT NULL,
        barcodeType TEXT NOT NULL,
        cardColor TEXT NOT NULL,
        logoPath TEXT,
        expiryDate INTEGER,
        notes TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');
  }

  // CRUD Operations

  // Create
  Future<int> insertCard(LoyaltyCard card) async {
    final db = await database;
    return await db.insert(
      'loyalty_cards',
      card.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Read
  Future<List<LoyaltyCard>> getCards() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('loyalty_cards');
    return List.generate(maps.length, (i) {
      return LoyaltyCard.fromMap(maps[i]);
    });
  }

  Future<LoyaltyCard?> getCard(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'loyalty_cards',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return LoyaltyCard.fromMap(maps.first);
    }
    return null;
  }

  // Update
  Future<int> updateCard(LoyaltyCard card) async {
    final db = await database;
    return await db.update(
      'loyalty_cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  // Delete
  Future<int> deleteCard(String id) async {
    final db = await database;
    return await db.delete(
      'loyalty_cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Close the database
  Future close() async {
    final db = await database;
    db.close();
  }
} 