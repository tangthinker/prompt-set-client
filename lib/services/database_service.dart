import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:prompt_set_client/models/prompt.dart';
import 'package:prompt_set_client/models/snapshot.dart';
import 'package:flutter/foundation.dart';
import 'package:prompt_set_client/models/app_config.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;
  static const _dbName = 'prompt_set.db';
  static const _secureStorageKey = 'db_encryption_key';
  final _storage = const FlutterSecureStorage(
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<String> _getEncryptionKey() async {
    try {
      String? key = await _storage.read(key: _secureStorageKey);
      if (key == null) {
        key = DateTime.now().millisecondsSinceEpoch.toString();
        await _storage.write(key: _secureStorageKey, value: key);
      }
      return key;
    } catch (e) {
      // Fallback for environment where keychain is totally unavailable
      return 'fallback_key_for_dev_only';
    }
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    debugPrint('Database path: $path');
    final password = await _getEncryptionKey();

    return await openDatabase(
      path,
      password: password,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE config ADD COLUMN locale TEXT DEFAULT "zh"');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE prompts ADD COLUMN content TEXT');
      await db.execute('ALTER TABLE prompts ADD COLUMN params TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE config ADD COLUMN models TEXT');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE prompts ADD COLUMN last_result TEXT');
      await db.execute('ALTER TABLE prompts ADD COLUMN last_reasoning TEXT');
      await db.execute('ALTER TABLE snapshots ADD COLUMN last_result TEXT');
      await db.execute('ALTER TABLE snapshots ADD COLUMN last_reasoning TEXT');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // ... existing prompts/snapshots tables ...
    // Create Prompts table
    await db.execute('''
      CREATE TABLE prompts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT,
        content TEXT,
        params TEXT,
        last_result TEXT,
        last_reasoning TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create Snapshots table
    await db.execute('''
      CREATE TABLE snapshots (
        id TEXT PRIMARY KEY,
        prompt_id TEXT NOT NULL,
        name TEXT NOT NULL,
        content TEXT NOT NULL,
        params TEXT NOT NULL,
        last_result TEXT,
        last_reasoning TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (prompt_id) REFERENCES prompts (id) ON DELETE CASCADE
      )
    ''');

    // Create Config table
    await db.execute('''
      CREATE TABLE config (
        id INTEGER PRIMARY KEY DEFAULT 0,
        api_key TEXT,
        base_url TEXT,
        default_model TEXT,
        models TEXT,
        locale TEXT DEFAULT 'zh'
      )
    ''');

    // Insert initial config
    await db.insert('config', {
      'id': 0,
      'api_key': '',
      'base_url': 'https://api.openai.com/v1',
      'default_model': 'gpt-3.5-turbo',
      'models': '[{"name": "gpt-3.5-turbo", "base_url": "https://api.openai.com/v1"}, {"name": "gpt-4", "base_url": "https://api.openai.com/v1"}, {"name": "deepseek-chat", "base_url": "https://api.deepseek.com"}, {"name": "deepseek-reasoner", "base_url": "https://api.deepseek.com"}]',
      'locale': 'zh'
    });
  }

  // --- CRUD Operations for Prompts ---

  Future<void> insertPrompt(Prompt prompt) async {
    final db = await database;
    await db.insert('prompts', prompt.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Prompt>> getAllPrompts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('prompts', orderBy: 'updated_at DESC');
    return List.generate(maps.length, (i) => Prompt.fromMap(maps[i]));
  }

  Future<void> updatePrompt(Prompt prompt) async {
    final db = await database;
    await db.update('prompts', prompt.toMap(),
        where: 'id = ?', whereArgs: [prompt.id]);
  }

  Future<void> deletePrompt(String id) async {
    final db = await database;
    await db.delete('prompts', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD Operations for Snapshots ---

  Future<void> insertSnapshot(PromptSnapshot snapshot) async {
    final db = await database;
    await db.insert('snapshots', snapshot.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<PromptSnapshot>> getSnapshotsForPrompt(String promptId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'snapshots',
      where: 'prompt_id = ?',
      whereArgs: [promptId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => PromptSnapshot.fromMap(maps[i]));
  }

  Future<void> updateSnapshot(PromptSnapshot snapshot) async {
    final db = await database;
    await db.update('snapshots', snapshot.toMap(),
        where: 'id = ?', whereArgs: [snapshot.id]);
  }

  Future<void> deleteSnapshot(String id) async {
    final db = await database;
    await db.delete('snapshots', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD Operations for Config ---

  Future<AppConfig> getConfig() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('config', where: 'id = 0');
    if (maps.isNotEmpty) {
      return AppConfig.fromMap(maps.first);
    }
    return AppConfig();
  }

  Future<void> updateConfig(AppConfig config) async {
    final db = await database;
    await db.update('config', config.toMap(), where: 'id = 0');
  }
}

