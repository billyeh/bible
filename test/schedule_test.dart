import 'package:bible/models/schedule.dart';
import 'package:bible/models/verse.dart';
import 'package:bible/bible_data/bible_data.dart';

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

class MockBibleData extends BibleData {
  final Map<String, int> bookVerseCounts;
  final Map<String, List<Map<String, dynamic>>> bookVerses;

  MockBibleData({required this.bookVerseCounts, required this.bookVerses});

  @override
  Future<Map<String, int>> getVersesInBooks(List<String> books) async {
    // Return only requested books.
    return Map.fromEntries(
      books.map((b) => MapEntry(b, bookVerseCounts[b] ?? 0)),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getVerses(List<String> books) async {
    // Flatten all requested books in order.
    final List<Map<String, dynamic>> verses = [];
    for (final book in books) {
      verses.addAll(bookVerses[book] ?? []);
    }
    return verses;
  }
}

void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  late Isar isar;

  setUp(() async {
    // We must manually create the directory before Isar can use it.
    final String testDir = 'test/isar_temp';
    final dir = Directory(testDir);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
    dir.createSync(recursive: true);
    // Create a new instance for each test.
    isar = await Isar.open([ScheduleSchema, VerseSchema], directory: testDir);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  group('Schedule Model Tests', () {
    test('Can create, save, and retrieve a Schedule', () async {
      final newSchedule = Schedule()
        ..name = 'Read the Pentateuch'
        ..startDate = DateTime(2024, 1, 1)
        ..endDate = DateTime(2024, 3, 31)
        ..booksToRead = [
          'Genesis',
          'Exodus',
          'Leviticus',
          'Numbers',
          'Deuteronomy',
        ];

      await isar.writeTxn(() async {
        await isar.schedules.put(newSchedule);
      });

      final retrievedSchedule = await isar.schedules.get(newSchedule.id);

      expect(retrievedSchedule, isNotNull);
      expect(retrievedSchedule!.name, newSchedule.name);
      expect(retrievedSchedule.startDate, newSchedule.startDate);
      expect(retrievedSchedule.endDate, newSchedule.endDate);
      expect(retrievedSchedule.booksToRead, newSchedule.booksToRead);
    });

    test(
      'getVersesPerDay calculates correct number of verses per day',
      () async {
        final schedule = Schedule()
          ..name = 'Test Schedule'
          ..startDate = DateTime(2024, 1, 1)
          ..endDate =
              DateTime(2024, 1, 3) // 3 days
          ..booksToRead = ['Book1', 'Book2'];

        // Mock BibleData with 10 verses in Book1, 5 in Book2
        final mockBible = MockBibleData(
          bookVerseCounts: {'Book1': 10, 'Book2': 5},
          bookVerses: {},
        );

        final versesPerDay = await schedule.getVersesPerDay(mockBible);

        expect(versesPerDay, 5);
      },
    );

    test(
      'getVersesForScheduleDate returns correct verses for a given day',
      () async {
        final schedule = Schedule()
          ..name = 'Test Schedule'
          ..startDate = DateTime(2024, 1, 1)
          ..endDate = DateTime(2024, 1, 3)
          ..booksToRead = ['Book1'];

        // Mock 6 verses in Book1
        final mockBible = MockBibleData(
          bookVerseCounts: {'Book1': 6},
          bookVerses: {
            'Book1': List.generate(
              6,
              (i) => {
                'book': 'Book1',
                'chapter': 1,
                'verse': i + 1,
                'text': 'Verse ${i + 1}',
              },
            ),
          },
        );

        // Day 0 (2024-01-01)
        final day0 = await schedule.getVersesForScheduleDate(
          mockBible,
          DateTime(2024, 1, 1),
        );
        expect(day0.length, 2);
        expect(day0.first['verse'], 1);
        expect(day0.last['verse'], 2);

        // Day 1 (2024-01-02)
        final day1 = await schedule.getVersesForScheduleDate(
          mockBible,
          DateTime(2024, 1, 2),
        );
        expect(day1.length, 2);
        expect(day1.first['verse'], 3);
        expect(day1.last['verse'], 4);

        // Day 2 (2024-01-03)
        final day2 = await schedule.getVersesForScheduleDate(
          mockBible,
          DateTime(2024, 1, 3),
        );
        expect(day2.length, 2);
        expect(day2.first['verse'], 5);
        expect(day2.last['verse'], 6);

        // Out-of-range date
        final outOfRange = await schedule.getVersesForScheduleDate(
          mockBible,
          DateTime(2023, 12, 31),
        );
        expect(outOfRange, isEmpty);
      },
    );

    test('getAllVerses returns all verses for the schedule', () async {
      final schedule = Schedule()
        ..name = 'Test Schedule'
        ..booksToRead = ['Book1', 'Book2'];

      final mockBible = MockBibleData(
        bookVerseCounts: {}, // Not used in this test
        bookVerses: {
          'Book1': [
            {'book': 'Book1', 'chapter': 1, 'verse': 1, 'text': '...'},
            {'book': 'Book1', 'chapter': 1, 'verse': 2, 'text': '...'},
          ],
          'Book2': [
            {'book': 'Book2', 'chapter': 1, 'verse': 1, 'text': '...'},
          ],
        },
      );

      final allVerses = await schedule.getAllVerses(mockBible);

      expect(allVerses.length, 3);
      expect(allVerses[0].book, 'Book1');
      expect(allVerses[0].chapter, 1);
      expect(allVerses[0].verse, 1);
      expect(allVerses[2].book, 'Book2');
    });

    test(
      'isScheduleFinished returns true when all verses have been read',
      () async {
        final schedule = Schedule()
          ..name = 'Test Schedule'
          ..startDate = DateTime(2024, 1, 1)
          ..endDate = DateTime(2024, 1, 3)
          ..booksToRead = ['Book1'];

        final mockBible = MockBibleData(
          bookVerseCounts: {}, // Not used
          bookVerses: {
            'Book1': [
              {'book': 'Book1', 'chapter': 1, 'verse': 1, 'text': '...'},
              {'book': 'Book1', 'chapter': 1, 'verse': 2, 'text': '...'},
            ],
          },
        );

        // Create Verse objects and add them to versesRead
        final verse1 = Verse()
          ..book = 'Book1'
          ..chapter = 1
          ..verse = 1;
        final verse2 = Verse()
          ..book = 'Book1'
          ..chapter = 1
          ..verse = 2;

        await isar.writeTxn(() async {
          await isar.verses.putAll([verse1, verse2]);
          await isar.schedules.put(schedule);
          schedule.versesRead.add(verse1);
          schedule.versesRead.add(verse2);
          await schedule.versesRead.save();
        });

        final isFinished = await schedule.isScheduleFinished(mockBible);
        expect(isFinished, isTrue);
      },
    );

    test(
      'isScheduleFinished returns false when not all verses have been read',
      () async {
        final schedule = Schedule()
          ..name = 'Test Schedule'
          ..startDate = DateTime(2024, 1, 1)
          ..endDate = DateTime(2024, 1, 3)
          ..booksToRead = ['Book1'];

        final mockBible = MockBibleData(
          bookVerseCounts: {}, // Not used
          bookVerses: {
            'Book1': [
              {'book': 'Book1', 'chapter': 1, 'verse': 1, 'text': '...'},
              {'book': 'Book1', 'chapter': 1, 'verse': 2, 'text': '...'},
            ],
          },
        );

        // Only add one verse as read
        final verse1 = Verse()
          ..book = 'Book1'
          ..chapter = 1
          ..verse = 1;
        await isar.writeTxn(() async {
          await isar.verses.put(verse1);
          await isar.schedules.put(schedule);
          schedule.versesRead.add(verse1);
          await schedule.versesRead.save();
        });

        final isFinished = await schedule.isScheduleFinished(mockBible);
        expect(isFinished, isFalse);
      },
    );
  });

  test(
    'getVersesForScheduleDate handles multiple books and uneven division',
    () async {
      final schedule = Schedule()
        ..name = 'Multi-Book Schedule'
        ..startDate = DateTime(2024, 1, 1)
        ..endDate =
            DateTime(2024, 1, 4) // 4 days
        ..booksToRead = ['Book1', 'Book2'];

      // Book1 has 5 verses, Book2 has 6 → total 11 verses
      final mockBible = MockBibleData(
        bookVerseCounts: {'Book1': 5, 'Book2': 7},
        bookVerses: {
          'Book1': List.generate(
            5,
            (i) => {
              'book': 'Book1',
              'chapter': 1,
              'verse': i + 1,
              'text': 'B1 V${i + 1}',
            },
          ),
          'Book2': List.generate(
            6,
            (i) => {
              'book': 'Book2',
              'chapter': 1,
              'verse': i + 1,
              'text': 'B2 V${i + 1}',
            },
          ),
        },
      );

      final versesPerDay = await schedule.getVersesPerDay(mockBible);
      expect(versesPerDay, 3);

      // Day 0 (Jan 1)
      final day0 = await schedule.getVersesForScheduleDate(
        mockBible,
        DateTime(2024, 1, 1),
      );
      expect(day0.length, 3);
      expect(day0[0]['text'], 'B1 V1');
      expect(day0[2]['text'], 'B1 V3');

      // Day 1 (Jan 2)
      final day1 = await schedule.getVersesForScheduleDate(
        mockBible,
        DateTime(2024, 1, 2),
      );
      expect(day1.length, 3);
      expect(day1[0]['text'], 'B1 V4');
      expect(day1[2]['text'], 'B2 V1');

      // Day 2 (Jan 3)
      final day2 = await schedule.getVersesForScheduleDate(
        mockBible,
        DateTime(2024, 1, 3),
      );
      expect(day2.length, 3);
      expect(day2[0]['text'], 'B2 V2');
      expect(day2[2]['text'], 'B2 V4');

      // Day 3 (Jan 4) → last day may have fewer than versesPerDay
      final day3 = await schedule.getVersesForScheduleDate(
        mockBible,
        DateTime(2024, 1, 4),
      );
      expect(day3.length, 2);
      expect(day3[0]['text'], 'B2 V5');
      expect(day3[1]['text'], 'B2 V6');
    },
  );

  group('getTimeProgress', () {
    test('is 0 before start date', () {
      final schedule = Schedule()
        ..startDate = DateTime(2024, 1, 10)
        ..endDate = DateTime(2024, 1, 20);
      final progress = schedule.getTimeProgress(DateTime(2024, 1, 5));
      expect(progress, 0.0);
    });

    test('is ~0.5 in the middle', () {
      final schedule = Schedule()
        ..startDate = DateTime(2024, 1, 10)
        ..endDate = DateTime(2024, 1, 20);
      // Day 5 of a 10 day schedule.
      final progress = schedule.getTimeProgress(DateTime(2024, 1, 15));
      expect(progress, 0.5);
    });

    test('is 1.0 on the end date', () {
      final schedule = Schedule()
        ..startDate = DateTime(2024, 1, 10)
        ..endDate = DateTime(2024, 1, 20);
      final progress = schedule.getTimeProgress(DateTime(2024, 1, 20));
      expect(progress, 1.0);
    });

    test('is 1.0 after the end date', () {
      final schedule = Schedule()
        ..startDate = DateTime(2024, 1, 10)
        ..endDate = DateTime(2024, 1, 20);
      final progress = schedule.getTimeProgress(DateTime(2024, 1, 25));
      expect(progress, 1.0);
    });

    test('handles single-day schedule', () {
      final schedule = Schedule()
        ..startDate = DateTime(2024, 1, 10)
        ..endDate = DateTime(2024, 1, 10);
      final progress = schedule.getTimeProgress(DateTime(2024, 1, 10));
      expect(progress, 1.0);
    });
  });

  group('getReadingProgress', () {
    final mockBible = MockBibleData(
      bookVerseCounts: {'Book1': 10},
      bookVerses: {
        'Book1': List.generate(
          10,
          (i) => {
            'book': 'Book1',
            'chapter': 1,
            'verse': i + 1,
            'text': 'Verse ${i + 1}',
          },
        ),
      },
    );

    test('is 0.0 when no verses are read', () async {
      final schedule = Schedule()
        ..name = 'Test'
        ..startDate = DateTime(2024, 1, 1)
        ..endDate = DateTime(2024, 1, 3)
        ..booksToRead = ['Book1'];
      await isar.writeTxn(() async {
        isar.schedules.put(schedule);
      });

      final progress = await schedule.getReadingProgress(mockBible);
      expect(progress, 0.0);
    });

    test('is ~0.5 when half the verses are read', () async {
      final schedule = Schedule()
        ..name = 'Test'
        ..startDate = DateTime(2024, 1, 1)
        ..endDate = DateTime(2024, 1, 3)
        ..booksToRead = ['Book1'];
      await isar.writeTxn(() async {
        isar.schedules.put(schedule);
      });

      // Mark 5 out of 10 verses as read
      final verses = List.generate(5, (i) {
        return Verse()
          ..book = 'Book1'
          ..chapter = 1
          ..verse = i + 1;
      });

      await isar.writeTxn(() async {
        await isar.verses.putAll(verses);
        schedule.versesRead.addAll(verses);
        await schedule.versesRead.save();
      });

      final progress = await schedule.getReadingProgress(mockBible);
      expect(progress, 0.5);
    });

    test('is 1.0 when all verses are read', () async {
      final schedule = Schedule()
        ..name = 'Test'
        ..startDate = DateTime(2024, 1, 1)
        ..endDate = DateTime(2024, 1, 3)
        ..booksToRead = ['Book1'];
      await isar.writeTxn(() async {
        isar.schedules.put(schedule);
      });

      // Mark all 10 verses as read
      final verses = List.generate(10, (i) {
        return Verse()
          ..book = 'Book1'
          ..chapter = 1
          ..verse = i + 1;
      });
      await isar.writeTxn(() async {
        await isar.verses.putAll(verses);
        schedule.versesRead.addAll(verses);
        await schedule.versesRead.save();
      });

      final progress = await schedule.getReadingProgress(mockBible);
      expect(progress, 1.0);
    });

    test('is 1.0 for a schedule with no books', () async {
      final schedule = Schedule()
        ..name = 'Test'
        ..startDate = DateTime(2024, 1, 1)
        ..endDate = DateTime(2024, 1, 3)
        ..booksToRead = [];
      await isar.writeTxn(() async {
        isar.schedules.put(schedule);
      });

      final progress = await schedule.getReadingProgress(mockBible);
      expect(progress, 1.0);
    });
  });

  test('isReadingDoneToday works correctly', () async {
    // Arrange: create a schedule for today
    final today = DateTime.now();
    final schedule = Schedule.create(
      name: 'Test Schedule',
      startDate: today,
      endDate: today,
      booksToRead: ['TestBook'],
    );

    await isar.writeTxn(() async {
      await isar.schedules.put(schedule);
    });

    // Mock BibleData for today’s verses
    final mockBible = MockBibleData(
      bookVerseCounts: {'TestBook': 2},
      bookVerses: {
        'TestBook': [
          {'book': 'TestBook', 'chapter': 1, 'verse': 1},
          {'book': 'TestBook', 'chapter': 1, 'verse': 2},
        ],
      },
    );

    // Case 1: No verses read → should be false
    await schedule.versesRead.load();
    var result = await schedule.isReadingDone(mockBible, today);
    expect(result, isFalse);

    // Case 2: Read only one verse → still false
    final verse1 = Verse()
      ..book = 'TestBook'
      ..chapter = 1
      ..verse = 1;

    await isar.writeTxn(() async {
      await isar.verses.put(verse1);
      schedule.versesRead.add(verse1);
      await isar.schedules.put(schedule);
    });
    await schedule.versesRead.load();
    result = await schedule.isReadingDone(mockBible, today);
    expect(result, isFalse);

    // Case 3: Read all today’s verses → should be true
    final verse2 = Verse()
      ..book = 'TestBook'
      ..chapter = 1
      ..verse = 2;

    await isar.writeTxn(() async {
      await isar.verses.put(verse2);
      schedule.versesRead.add(verse2);
      await isar.schedules.put(schedule);
    });
    await schedule.versesRead.load();
    result = await schedule.isReadingDone(mockBible, today);
    expect(result, isTrue);
  });
}
