import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bible/bible_data/bible_data.dart';

void main() {
  // Initialize FFI before using openDatabase
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  TestWidgetsFlutterBinding.ensureInitialized();

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

  test('getVerses returns all verses in order for the given books', () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        // Create tables
        await db.execute('CREATE TABLE key_english (b INTEGER, n TEXT)');
        await db.execute(
          'CREATE TABLE t_asv (id INTEGER, b INTEGER, c INTEGER, v INTEGER, t TEXT)',
        );

        // Insert books
        await db.insert('key_english', {'b': 1, 'n': 'Genesis'});
        await db.insert('key_english', {'b': 2, 'n': 'Exodus'});

        // Insert verses for Genesis (b=1)
        await db.insert('t_asv', {
          'id': 1,
          'b': 1,
          'c': 1,
          'v': 1,
          't': 'In the beginning...',
        });
        await db.insert('t_asv', {
          'id': 2,
          'b': 1,
          'c': 1,
          'v': 2,
          't': 'And the earth was...',
        });
        await db.insert('t_asv', {
          'id': 3,
          'b': 1,
          'c': 2,
          'v': 1,
          't': 'Thus the heavens...',
        });

        // Insert verses for Exodus (b=2)
        await db.insert('t_asv', {
          'id': 4,
          'b': 2,
          'c': 1,
          'v': 1,
          't': 'Now these are the names...',
        });
        await db.insert('t_asv', {
          'id': 5,
          'b': 2,
          'c': 1,
          'v': 2,
          't': 'And Moses said...',
        });
      },
    );

    final bibleData = BibleData(db: db);

    // Query both books
    final verses = await bibleData.getVerses(['Genesis', 'Exodus']);

    expect(verses.length, 5);

    // Check the order and content
    expect(verses[0]['book'], 'Genesis');
    expect(verses[0]['chapter'], 1);
    expect(verses[0]['verse'], 1);
    expect(verses[0]['text'], 'In the beginning...');

    expect(verses[2]['book'], 'Genesis');
    expect(verses[2]['chapter'], 2);
    expect(verses[2]['verse'], 1);
    expect(verses[2]['text'], 'Thus the heavens...');

    expect(verses[3]['book'], 'Exodus');
    expect(verses[3]['chapter'], 1);
    expect(verses[3]['verse'], 1);
    expect(verses[3]['text'], 'Now these are the names...');

    expect(verses[4]['book'], 'Exodus');
    expect(verses[4]['chapter'], 1);
    expect(verses[4]['verse'], 2);
    expect(verses[4]['text'], 'And Moses said...');

    await db.close();
  });

  group('formatBookSelection', () {
    late BibleData bibleData;
    final allBooks = [
      'Genesis',
      'Exodus',
      'Leviticus',
      'Numbers',
      'Deuteronomy',
      'Joshua',
      'Judges',
      'Ruth',
      '1 Samuel',
      '2 Samuel',
      '1 Kings',
      '2 Kings',
      '1 Chronicles',
      '2 Chronicles',
      'Ezra',
      'Nehemiah',
      'Esther',
      'Job',
      'Psalms',
      'Proverbs',
      'Ecclesiastes',
      'Song of Solomon',
      'Isaiah',
      'Jeremiah',
      'Lamentations',
      'Ezekiel',
      'Daniel',
      'Hosea',
      'Joel',
      'Amos',
      'Obadiah',
      'Jonah',
      'Micah',
      'Nahum',
      'Habakkuk',
      'Zephaniah',
      'Haggai',
      'Zechariah',
      'Malachi',
      'Matthew',
      'Mark',
      'Luke',
      'John',
      'Acts',
      'Romans',
      '1 Corinthians',
      '2 Corinthians',
      'Galatians',
      'Ephesians',
      'Philippians',
      'Colossians',
      '1 Thessalonians',
      '2 Thessalonians',
      '1 Timothy',
      '2 Timothy',
      'Titus',
      'Philemon',
      'Hebrews',
      'James',
      '1 Peter',
      '2 Peter',
      '1 John',
      '2 John',
      '3 John',
      'Jude',
      'Revelation',
    ];

    setUp(() async {
      final db = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('CREATE TABLE key_english (b INTEGER, n TEXT)');
            for (var i = 0; i < allBooks.length; i++) {
              await db.insert('key_english', {'b': i + 1, 'n': allBooks[i]});
            }
          },
        ),
      );

      bibleData = BibleData(db: db);
    });

    test('returns Whole Bible when all books are selected', () async {
      final allBooks = await bibleData.getBooks();
      final result = await bibleData.formatBookSelection(allBooks);
      expect(result, 'Whole Bible');
    });

    test('returns Old Testament when all OT books are selected', () async {
      final otBooks = await bibleData.getOldTestamentBooks();
      final result = await bibleData.formatBookSelection(otBooks);
      expect(result, 'Old Testament');
    });

    test('returns New Testament when all NT books are selected', () async {
      final ntBooks = await bibleData.getNewTestamentBooks();
      final result = await bibleData.formatBookSelection(ntBooks);
      expect(result, 'New Testament');
    });

    test('compresses consecutive run of books', () async {
      final selected = ['Genesis', 'Exodus', 'Leviticus'];
      final result = await bibleData.formatBookSelection(selected);
      expect(result, 'Genesis - Leviticus');
    });

    test('handles mixed runs and singletons', () async {
      final selected = [
        'Genesis',
        'Exodus',
        'Leviticus',
        'Psalms',
        'Matthew',
        'Mark',
        'Luke',
      ];
      final result = await bibleData.formatBookSelection(selected);
      expect(result, 'Genesis - Leviticus, Psalms, Matthew - Luke');
    });

    test('single book returns the book name', () async {
      final selected = ['Genesis'];
      final result = await bibleData.formatBookSelection(selected);
      expect(result, 'Genesis');
    });

    test(
      'partial OT run that matches start to end returns Old Testament',
      () async {
        final otBooks = await bibleData.getOldTestamentBooks();
        final result = await bibleData.formatBookSelection(otBooks);
        expect(result, 'Old Testament');
      },
    );

    test('empty selection returns "No books"', () async {
      final result = await bibleData.formatBookSelection([]);
      expect(result, 'No books');
    });

    test('Mixed full OT run + single NT books', () async {
      final otBooks = await bibleData.getOldTestamentBooks();
      final selected = [...otBooks, 'Matthew', 'Mark'];
      final result = await bibleData.formatBookSelection(selected);
      // OT collapses, NT runs compress normally
      expect(result, 'Old Testament, Matthew - Mark');
    });

    test('Multiple consecutive runs across OT and NT', () async {
      final selected = [
        'Genesis',
        'Exodus',
        'Leviticus',
        'Matthew',
        'Mark',
        'Luke',
        'Revelation',
      ];
      final result = await bibleData.formatBookSelection(selected);
      expect(result, 'Genesis - Leviticus, Matthew - Luke, Revelation');
    });
  });
}
