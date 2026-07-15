import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../core/constants/app_constants.dart';
import '../models/flashcard.dart';
import '../models/homework_item.dart';

/// Handles all local, offline storage of homework history and flashcards
/// using SQLite.
///
/// SQLite normally only runs on mobile. To make history work EVERYWHERE
/// (Windows/macOS/Linux/Web too), we pick the right database "factory" for the
/// current platform in [init]. The rest of the code doesn't need to care.
class DatabaseService {
  Database? _db;

  /// Must be called once at startup (see main.dart) before any other method.
  Future<void> init() async {
    if (_db != null) return;

    if (kIsWeb) {
      // Web uses an IndexedDB-backed SQLite implementation.
      databaseFactory = databaseFactoryFfiWeb;
      _db = await databaseFactory.openDatabase(
        AppConstants.dbName,
        options: OpenDatabaseOptions(
          version: AppConstants.dbVersion,
          onCreate: _onCreate,
        ),
      );
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      // Desktop uses the FFI implementation.
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // Mobile (and desktop via the factory above) store a real file.
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, AppConstants.dbName);

    _db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: AppConstants.dbVersion,
        onCreate: _onCreate,
      ),
    );
  }

  /// Creates the tables the first time the database is opened.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableHomework} (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        question TEXT NOT NULL,
        subject TEXT NOT NULL,
        messages TEXT NOT NULL,
        image_path TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableFlashcards} (
        id TEXT PRIMARY KEY,
        front TEXT NOT NULL,
        back TEXT NOT NULL,
        subject TEXT NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Database get _database {
    final db = _db;
    if (db == null) {
      throw StateError('DatabaseService.init() must be called before use.');
    }
    return db;
  }

  // --- Homework CRUD -----------------------------------------------------

  Future<List<HomeworkItem>> getAllHomework() async {
    final rows = await _database.query(
      AppConstants.tableHomework,
      orderBy: 'updated_at DESC',
    );
    return rows.map(HomeworkItem.fromDbMap).toList();
  }

  Future<void> upsertHomework(HomeworkItem item) async {
    await _database.insert(
      AppConstants.tableHomework,
      item.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteHomework(String id) async {
    await _database.delete(
      AppConstants.tableHomework,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllHomework() async {
    await _database.delete(AppConstants.tableHomework);
  }

  // --- Flashcard CRUD ----------------------------------------------------

  Future<List<Flashcard>> getAllFlashcards() async {
    final rows = await _database.query(
      AppConstants.tableFlashcards,
      orderBy: 'created_at DESC',
    );
    return rows.map(Flashcard.fromDbMap).toList();
  }

  Future<void> upsertFlashcard(Flashcard card) async {
    await _database.insert(
      AppConstants.tableFlashcards,
      card.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteFlashcard(String id) async {
    await _database.delete(
      AppConstants.tableFlashcards,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
