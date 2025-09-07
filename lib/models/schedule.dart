import 'package:bible/models/verse.dart';
import 'package:bible/bible_data/bible_data.dart';

import 'package:isar/isar.dart';

part 'schedule.g.dart';

@collection
class Schedule {
  Id id = Isar.autoIncrement; // auto increment id

  late String name;

  late DateTime startDate;

  late DateTime endDate;

  late List<String> booksToRead;

  // You might use this later to track progress
  final versesRead = IsarLinks<Verse>();
}

extension ScheduleExtensions on Schedule {
  // Number of days in the plan.
  int get totalDays => endDate.difference(startDate).inDays + 1;

  // Number of verses to read per day.
  Future<int> getVersesPerDay(BibleData bible) async {
    final verseCounts = await bible.getVersesInBooks(booksToRead);

    final totalVerses = bible.countTotalVerses(verseCounts);

    return (totalVerses / totalDays).ceil();
  }

  // Verses to read for a given day.
  Future<List<Map<String, dynamic>>> getVersesForScheduleDate(
    BibleData bible,
    DateTime date,
  ) async {
    if (date.isBefore(startDate) || date.isAfter(endDate)) {
      return [];
    }

    final versesPerDay = await getVersesPerDay(bible);
    final dayIndex = date.difference(startDate).inDays;
    final offset = dayIndex * versesPerDay;

    final allVerses = await bible.getVerses(booksToRead);

    return allVerses.skip(offset).take(versesPerDay).toList();
  }
}
