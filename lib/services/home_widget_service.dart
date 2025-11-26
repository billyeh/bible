import 'dart:io';

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bible/models/schedule.dart';
import 'package:bible/models/verse.dart';
import 'package:bible/bible_data/bible_data.dart';
import 'package:bible/main.dart';

@pragma("vm:entry-point")
class HomeWidgetService {
  static const _verseTextKey = 'verse_text';
  static const _verseReferenceKey = 'verse_reference';
  static const _verseBookKey = 'verse_book';
  static const _verseChapterKey = 'verse_chapter';
  static const _verseNumKey = 'verse_num';
  static const _scheduleIdKey = 'schedule_id';
  static const _verseDateKey = 'verse_date';
  static const _androidWidgetReceiver =
      'com.example.bible.widget.HomeWidgetReceiver';

  /// Gets the current verse that the user should read.
  /// Returns a map with 'text', 'reference', 'book', 'chapter', 'verse', 'scheduleId', 'date' keys, or null if no verse found.
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
            return {
              'text': text,
              'reference': reference,
              'book': verseMap['book'],
              'chapter': verseMap['chapter'].toString(),
              'verse': verseMap['verse'].toString(),
              'scheduleId': schedule.id.toString(),
              'date': normalizedToday.toIso8601String(),
            };
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

      final versesPerDay = await firstSchedule.getVersesPerDay(bibleData);

      // Find first unread verse
      for (int i = 0; i < allVersesMaps.length; i++) {
        final verseMap = allVersesMaps[i];
        final verseKey =
            '${verseMap['book']}:${verseMap['chapter']}:${verseMap['verse']}';
        if (!readSet.contains(verseKey)) {
          final text = verseMap['text'] as String? ?? '';
          final reference =
              '${verseMap['book']} ${verseMap['chapter']}:${verseMap['verse']}';

          // Calculate date for this verse
          final dayIndex = (i / versesPerDay).floor();
          final date = firstSchedule.startDate.add(Duration(days: dayIndex));

          return {
            'text': text,
            'reference': reference,
            'book': verseMap['book'],
            'chapter': verseMap['chapter'].toString(),
            'verse': verseMap['verse'].toString(),
            'scheduleId': firstSchedule.id.toString(),
            'date': date.toIso8601String(),
          };
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
      await HomeWidget.saveWidgetData<String>(
        _verseBookKey,
        currentVerse['book'] ?? '',
      );
      await HomeWidget.saveWidgetData<String>(
        _verseChapterKey,
        currentVerse['chapter'] ?? '',
      );
      await HomeWidget.saveWidgetData<String>(
        _verseNumKey,
        currentVerse['verse'] ?? '',
      );
      await HomeWidget.saveWidgetData<String>(
        _scheduleIdKey,
        currentVerse['scheduleId'] ?? '',
      );
      await HomeWidget.saveWidgetData<String>(
        _verseDateKey,
        currentVerse['date'] ?? '',
      );
    } else {
      // No current verse found, show a default message
      await HomeWidget.saveWidgetData<String>(
        _verseTextKey,
        'No reading scheduled',
      );
      await HomeWidget.saveWidgetData<String>(_verseReferenceKey, '');
      await HomeWidget.saveWidgetData<String>(_verseBookKey, '');
      await HomeWidget.saveWidgetData<String>(_verseChapterKey, '');
      await HomeWidget.saveWidgetData<String>(_verseNumKey, '');
      await HomeWidget.saveWidgetData<String>(_scheduleIdKey, '');
      await HomeWidget.saveWidgetData<String>(_verseDateKey, '');
    }
    await HomeWidget.updateWidget(qualifiedAndroidName: _androidWidgetReceiver);
  }

  @pragma("vm:entry-point")
  static Future<void> backgroundCallback(Uri? data) async {
    if (data?.host == 'markread') {
      try {
        WidgetsFlutterBinding.ensureInitialized();
        final dir = await getApplicationDocumentsDirectory();

        if (Isar.instanceNames.isEmpty) {
          isar = await Isar.open([
            ScheduleSchema,
            VerseSchema,
          ], directory: dir.path);
        } else {
          isar = Isar.getInstance()!;
        }

        final scheduleIdStr = await HomeWidget.getWidgetData<String>(
          _scheduleIdKey,
        );
        final book = await HomeWidget.getWidgetData<String>(_verseBookKey);
        final chapterStr = await HomeWidget.getWidgetData<String>(
          _verseChapterKey,
        );
        final verseNumStr = await HomeWidget.getWidgetData<String>(
          _verseNumKey,
        );

        if (scheduleIdStr != null &&
            book != null &&
            chapterStr != null &&
            verseNumStr != null &&
            scheduleIdStr.isNotEmpty &&
            book.isNotEmpty) {
          final scheduleId = int.parse(scheduleIdStr);
          final chapter = int.parse(chapterStr);
          final verseNum = int.parse(verseNumStr);

          final schedule = await isar.schedules.get(scheduleId);
          if (schedule != null) {
            final verseRef = await Verse.findOrCreate(
              isar,
              book: book,
              chapter: chapter,
              verseNum: verseNum,
            );

            await schedule.versesRead.load();
            final isRead = await schedule.versesRead
                .filter()
                .bookEqualTo(book)
                .chapterEqualTo(chapter)
                .verseEqualTo(verseNum)
                .isNotEmpty();

            if (!isRead) {
              await isar.writeTxn(() async {
                schedule.versesRead.add(verseRef);
                await schedule.versesRead.save();
              });
            }
          }
        }

        await updateCurrentVerse();
      } catch (e) {
        print('Error in background callback: $e');
      }
    }
  }

  static Future<void> registerBackgroundCallback() async {
    if (!Platform.isAndroid) return;
    await HomeWidget.registerInteractivityCallback(backgroundCallback);
  }
}
