import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:bible/models/schedule.dart';
import 'package:bible/models/verse.dart';

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
  });
}
