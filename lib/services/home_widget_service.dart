import 'dart:io';

import 'package:home_widget/home_widget.dart';
import 'package:isar/isar.dart';
import 'package:bible/models/schedule.dart';
import 'package:bible/models/verse.dart';
import 'package:bible/bible_data/bible_data.dart';
import 'package:bible/main.dart';

class HomeWidgetService {
  static const _verseTextKey = 'verse_text';
  static const _verseReferenceKey = 'verse_reference';
  static const _androidWidgetReceiver =
      'com.example.bible.widget.HomeWidgetReceiver';

  /// Gets the current verse that the user should read.
  /// Returns a map with 'text' and 'reference' keys, or null if no verse found.
  static Future<Map<String, String>?> getCurrentVerse() async {
    final bibleData = BibleData();
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    // 1. Load all schedules
    final allSchedules = await isar.schedules.where().findAll();

    // 2. Filter out finished schedules
    final unfinishedSchedules = <Schedule>[];
    for (final schedule in allSchedules) {
      final finished = await schedule.isScheduleFinished(bibleData);
      if (!finished) {
        unfinishedSchedules.add(schedule);
      }
    }

    if (unfinishedSchedules.isEmpty) {
      return null;
    }

    // 3. Check each unfinished schedule for today's reading
    for (final schedule in unfinishedSchedules) {
      // Check if today is within schedule date range
      if (!schedule.isAfterOrOnStartDate(normalizedToday) ||
          normalizedToday.isAfter(schedule.endDate)) {
        continue;
      }

      // Check if today's reading is done
      final isDone = await schedule.isReadingDone(bibleData, normalizedToday);
      if (!isDone) {
        // Get today's verses
        final todayVerses = await schedule.getVersesForScheduleDate(
          bibleData,
          normalizedToday,
        );
        if (todayVerses.isEmpty) {
          continue;
        }

        // Load read verses
        await schedule.versesRead.load();
        final readSet = schedule.versesRead
            .map((v) => '${v.book}:${v.chapter}:${v.verse}')
            .toSet();

        // Find first unread verse from today
        for (final verseMap in todayVerses) {
          final verseKey =
              '${verseMap['book']}:${verseMap['chapter']}:${verseMap['verse']}';
          if (!readSet.contains(verseKey)) {
            final text = verseMap['text'] as String? ?? '';
            final reference =
                '${verseMap['book']} ${verseMap['chapter']}:${verseMap['verse']}';
            return {'text': text, 'reference': reference};
          }
        }
      }
    }

    // 4. If all today's readings are done, get first unread verse from first unfinished schedule
    if (unfinishedSchedules.isNotEmpty) {
      final firstSchedule = unfinishedSchedules.first;
      await firstSchedule.versesRead.load();
      final readSet = firstSchedule.versesRead
          .map((v) => '${v.book}:${v.chapter}:${v.verse}')
          .toSet();

      // Get all verses from the schedule
      final allVersesMaps = await bibleData.getVerses(
        firstSchedule.booksToRead,
      );

      // Find first unread verse
      for (final verseMap in allVersesMaps) {
        final verseKey =
            '${verseMap['book']}:${verseMap['chapter']}:${verseMap['verse']}';
        if (!readSet.contains(verseKey)) {
          final text = verseMap['text'] as String? ?? '';
          final reference =
              '${verseMap['book']} ${verseMap['chapter']}:${verseMap['verse']}';
          return {'text': text, 'reference': reference};
        }
      }
    }

    return null;
  }

  static Future<void> initialize() async {
    if (!Platform.isAndroid) return;

    await updateCurrentVerse();
  }

  static Future<void> updateCurrentVerse() async {
    if (!Platform.isAndroid) return;

    final currentVerse = await getCurrentVerse();
    if (currentVerse != null) {
      await HomeWidget.saveWidgetData<String>(
        _verseTextKey,
        currentVerse['text'] ?? '',
      );
      await HomeWidget.saveWidgetData<String>(
        _verseReferenceKey,
        currentVerse['reference'] ?? '',
      );
    } else {
      // No current verse found, show a default message
      await HomeWidget.saveWidgetData<String>(
        _verseTextKey,
        'No reading scheduled',
      );
      await HomeWidget.saveWidgetData<String>(_verseReferenceKey, '');
    }
    await HomeWidget.updateWidget(qualifiedAndroidName: _androidWidgetReceiver);
  }
}
