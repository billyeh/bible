import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:bible_reading/models/verse.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = new DatabaseHelper.internal();

  factory DatabaseHelper() => _instance;

  final String tableBible = 't_asv';
  final String tableBooks = 'key_english';

  static Database? _db;

  DatabaseHelper.internal();

  Future<Database> get db async {
    return await initDb();
  }

  initDb() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "bible.db");

    if (FileSystemEntity.typeSync(path) == FileSystemEntityType.notFound) {
      ByteData data = await rootBundle.load(join('db', 'bible.db'));
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await new File(path).writeAsBytes(bytes, flush: true);
    }
    _db = await openDatabase(path);
  }

  Future<List<Map>> fetchBooks() async {
    await db;
    List<Map> results = await _db!.rawQuery('SELECT * FROM $tableBooks');
    return results;
  }

  Future<int> countVerses(List<String> bookNames) async {
    await db;
    final bookIds = await _db!.query(
      tableBooks,
      columns: ['b'],
      where: 'n IN (${bookNames.map((e) => '?').join(',')})',
      whereArgs: bookNames,
    );
    final ids = bookIds.map((row) => row['b'] as int).toList();
    final count = await _db!.rawQuery(
      'SELECT COUNT(*) FROM $tableBible WHERE b IN (${ids.map((e) => '?').join(',')})',
      ids,
    );
    return Sqflite.firstIntValue(count) ?? 0;
  }

  Future<Verse?> findFirstVerse(String bookName) async {
    await db;
    final bookId = await _db!.query(
      tableBooks,
      columns: ['b'],
      where: 'n = ?',
      whereArgs: [bookName],
    );
    if (bookId.isEmpty) {
      return null;
    }
    final id = bookId.first['b'] as int;
    final verse = await _db!.query(
      tableBible,
      columns: Verse.columns,
      where: 'b = ?',
      whereArgs: [id],
      orderBy: 'id',
      limit: 1,
    );
    if (verse.isEmpty) {
      return null;
    }
    return Verse.fromMap(verse.first);
  }

  Future<Verse?> findNextVerse(Verse verse) async {
    await db;
    final nextVerse = await _db!.query(
      tableBible,
      columns: Verse.columns,
      where: 'id > ?',
      whereArgs: [verse.id],
      orderBy: 'id',
      limit: 1,
    );
    if (nextVerse.isEmpty) {
      return null;
    }
    return Verse.fromMap(nextVerse.first);
  }

  Future close() async {
    var dbClient = await db;
    return dbClient.close();
  }
}
