import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class BibleData {
  static Database? _database;

  // Optional injected database, useful for testing.
  final Database? db;

  // Factory constructor for production or test.
  BibleData({this.db});

  /// Returns the database instance, creating it if necessary.
  Future<Database> get database async {
    if (db != null) return db!;
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initializes the database by copying it from assets (production only).
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

  // Gets the number of verses for a list of books.
  //
  // The returned map contains the book name as the key and the verse count as the value.
  Future<Map<String, int>> getVersesInBooks(List<String> books) async {
    if (books.isEmpty) {
      return {};
    }

    final db = await database;

    // Use a parameterized query to prevent SQL injection.
    final String bookNames = books.map((_) => '?').join(',');

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT key_english.n, COUNT(t.v) as verse_count
      FROM key_english
      JOIN t_asv t ON key_english.b = t.b
      WHERE key_english.n IN ($bookNames)
      GROUP BY key_english.n
      ORDER BY key_english.b ASC
      ''', books);

    return Map.fromEntries(
      maps.map(
        (map) => MapEntry(map['n'] as String, map['verse_count'] as int),
      ),
    );
  }

  // Counts the total number of verses from a map of book verse counts.
  int countTotalVerses(Map<String, int> bookVerseCounts) {
    if (bookVerseCounts.isEmpty) {
      return 0;
    }
    return bookVerseCounts.values.reduce((sum, count) => sum + count);
  }

  Future<List<Map<String, dynamic>>> getVerses(List<String> books) async {
    if (books.isEmpty) return [];

    final db = await database;
    final placeholders = books.map((_) => '?').join(',');

    return await db.rawQuery('''
    SELECT key_english.n as book,
           t.c as chapter,
           t.v as verse,
           t.t as text
    FROM key_english
    JOIN t_asv t ON key_english.b = t.b
    WHERE key_english.n IN ($placeholders)
    ORDER BY key_english.b, t.c, t.v
  ''', books);
  }
}

extension TestamentBooks on BibleData {
  /// Returns all Old Testament books, based on getBooks().
  Future<List<String>> getOldTestamentBooks() async {
    final allBooks = await getBooks();

    final malachiIndex = allBooks.indexOf("Malachi");
    if (malachiIndex == -1) {
      return []; // fallback if DB doesn’t have Malachi
    }
    return allBooks.sublist(0, malachiIndex + 1); // inclusive of Malachi
  }

  /// Returns all New Testament books, based on getBooks().
  Future<List<String>> getNewTestamentBooks() async {
    final allBooks = await getBooks();

    final matthewIndex = allBooks.indexOf("Matthew");
    if (matthewIndex == -1) {
      return []; // fallback if DB doesn’t have Matthew
    }
    return allBooks.sublist(matthewIndex); // Matthew through the end
  }

  /// Convenience helper to return both in one map.
  Future<Map<String, List<String>>> getBooksByTestament() async {
    final ot = await getOldTestamentBooks();
    final nt = await getNewTestamentBooks();
    return {"Old Testament": ot, "New Testament": nt};
  }
}
