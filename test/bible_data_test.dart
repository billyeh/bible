import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bible/bible_data/bible_data.dart';

void main() {
  // Initialize FFI before using openDatabase
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('getBooks returns data from in-memory database', () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE key_english (b INTEGER, n TEXT)');
        await db.insert('key_english', {'b': 1, 'n': 'Genesis'});
        await db.insert('key_english', {'b': 2, 'n': 'Exodus'});
      },
    );

    final bibleData = BibleData(db: db);
    final books = await bibleData.getBooks();

    expect(books, ['Genesis', 'Exodus']);

    await db.close();
  });
}
