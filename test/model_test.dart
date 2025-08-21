import 'package:bible_reading/models/progress.dart';
import 'package:bible_reading/models/schedule.dart';
import 'package:bible_reading/models/verse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Schedule', () {
    test('fromJson and toJson', () {
      final schedule = Schedule(
        id: '1',
        userId: 'user1',
        name: 'Test Schedule',
        type: ScheduleType.booksByDate,
        startDate: DateTime(2023, 1, 1),
        endDate: DateTime(2023, 12, 31),
        books: ['Genesis', 'Exodus'],
        dailyVerseGoal: 10,
        currentVerse: Verse(id: 1, book: 1, chapter: 1, verse: 1, text: 'In the beginning...'),
        isArchived: false,
      );

      final json = schedule.toJson();
      final newSchedule = Schedule.fromJson(json);

      expect(newSchedule.id, schedule.id);
      expect(newSchedule.userId, schedule.userId);
      expect(newSchedule.name, schedule.name);
      expect(newSchedule.type, schedule.type);
      expect(newSchedule.startDate, schedule.startDate);
      expect(newSchedule.endDate, schedule.endDate);
      expect(newSchedule.books, schedule.books);
      expect(newSchedule.dailyVerseGoal, schedule.dailyVerseGoal);
      expect(newSchedule.currentVerse?.id, schedule.currentVerse?.id);
      expect(newSchedule.isArchived, schedule.isArchived);
    });
  });

  group('Progress', () {
    test('fromJson and toJson', () {
      final progress = Progress(
        id: '1',
        userId: 'user1',
        scheduleId: 'schedule1',
        verse: Verse(id: 1, book: 1, chapter: 1, verse: 1, text: 'In the beginning...'),
        timestamp: DateTime(2023, 1, 1),
      );

      final json = progress.toJson();
      final newProgress = Progress.fromJson(json);

      expect(newProgress.id, progress.id);
      expect(newProgress.userId, progress.userId);
      expect(newProgress.scheduleId, progress.scheduleId);
      expect(newProgress.verse?.id, progress.verse?.id);
      expect(newProgress.timestamp, progress.timestamp);
    });
  });

  group('Verse', () {
    test('fromMap and toJson', () {
      final verse = Verse(
        id: 1,
        book: 1,
        chapter: 1,
        verse: 1,
        text: 'In the beginning...',
      );

      final json = verse.toJson();
      final newVerse = Verse.fromJson(json);

      expect(newVerse.id, verse.id);
      expect(newVerse.book, verse.book);
      expect(newVerse.chapter, verse.chapter);
      expect(newVerse.verse, verse.verse);
      expect(newVerse.text, verse.text);
    });
  });
}
