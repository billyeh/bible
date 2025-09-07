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

  test('getVersesInBooks returns the correct verse count per book', () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        // Create both key_english and t_asv tables for the join
        await db.execute('CREATE TABLE key_english (b INTEGER, n TEXT)');
        await db.execute(
          'CREATE TABLE t_asv (id INTEGER, b INTEGER, c INTEGER, v INTEGER, t TEXT)',
        );

        // Insert sample book data
        await db.insert('key_english', {'b': 1, 'n': 'Genesis'});
        await db.insert('key_english', {'b': 2, 'n': 'Exodus'});
        await db.insert('key_english', {'b': 3, 'n': 'Leviticus'});

        // Insert sample verse data for Genesis (b=1, 3 verses)
        await db.insert('t_asv', {'id': 1, 'b': 1, 'c': 1, 'v': 1, 't': '...'});
        await db.insert('t_asv', {'id': 2, 'b': 1, 'c': 1, 'v': 2, 't': '...'});
        await db.insert('t_asv', {'id': 3, 'b': 1, 'c': 1, 'v': 3, 't': '...'});

        // Insert sample verse data for Exodus (b=2, 2 verses)
        await db.insert('t_asv', {'id': 4, 'b': 2, 'c': 1, 'v': 1, 't': '...'});
        await db.insert('t_asv', {'id': 5, 'b': 2, 'c': 1, 'v': 2, 't': '...'});

        // Insert verse data for a book not being queried (b=3, 1 verse)
        await db.insert('t_asv', {'id': 6, 'b': 3, 'c': 1, 'v': 1, 't': '...'});
      },
    );

    final bibleData = BibleData(db: db);
    final verseCounts = await bibleData.getVersesInBooks(['Genesis', 'Exodus']);

    expect(verseCounts, {'Genesis': 3, 'Exodus': 2});

    await db.close();
  });

  test('countTotalVerses correctly sums the verse counts', () {
    final bibleData = BibleData();

    // Test with a populated map
    final populatedMap = <String, int>{
      'Genesis': 3,
      'Exodus': 2,
      'Leviticus': 1,
    };
    final totalPopulated = bibleData.countTotalVerses(populatedMap);
    expect(totalPopulated, 6);

    // Test with an empty map
    final emptyMap = <String, int>{};
    final totalEmpty = bibleData.countTotalVerses(emptyMap);
    expect(totalEmpty, 0);

    // Test with a single entry
    final singleEntryMap = <String, int>{'Numbers': 5};
    final totalSingle = bibleData.countTotalVerses(singleEntryMap);
    expect(totalSingle, 5);
  });
}
