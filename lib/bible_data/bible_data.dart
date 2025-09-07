import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class BibleData {
  static Database? _database;

  /// Optional injected database, useful for testing.
  final Database? db;

  /// Factory constructor for production or test.
  BibleData({this.db});

  /// Returns the database instance, creating it if necessary.
  Future<Database> get database async {
    if (db != null) return db!;
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initializes the database by copying it from assets (production only).
  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = '${documentsDirectory.path}/lib/bible_data/bible.db';

    var exists = await databaseExists(path);
    if (!exists) {
      await Directory(p.dirname(path)).create(recursive: true);

      ByteData data = await rootBundle.load("lib/bible_data/bible.db");
      List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await File(path).writeAsBytes(bytes, flush: true);
    }

    return await openDatabase(path, version: 1);
  }

  /// Retrieves the list of books in the Bible.
  Future<List<String>> getBooks() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT n FROM key_english ORDER BY b ASC',
    );

    return List.generate(maps.length, (i) => maps[i]['n'] as String);
  }
}
