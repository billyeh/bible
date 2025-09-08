import 'package:bible/models/verse.dart';
import 'package:bible/bible_data/bible_data.dart';

import 'package:isar/isar.dart';

part 'schedule.g.dart';

@collection
class Schedule {
  Id id = Isar.autoIncrement;

  late String name;

  late DateTime startDate;

  late DateTime endDate;

  late List<String> booksToRead;

  final versesRead = IsarLinks<Verse>();

  Schedule();

  static DateTime _normalize(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  factory Schedule.create({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> booksToRead,
  }) {
    return Schedule()
      ..name = name
      ..startDate = _normalize(startDate)
      ..endDate = _normalize(endDate)
      ..booksToRead = booksToRead;
  }
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
    // Get the requested date, not including the time portion.
    final DateTime requestedDate = Schedule._normalize(date);
    if (requestedDate.isBefore(startDate) || requestedDate.isAfter(endDate)) {
      return [];
    }

    final versesPerDay = await getVersesPerDay(bible);
    final dayIndex = requestedDate.difference(startDate).inDays;
    final offset = dayIndex * versesPerDay;

    final allVerses = await bible.getVerses(booksToRead);

    return allVerses.skip(offset).take(versesPerDay).toList();
  }

  bool isAfterStartDate(DateTime date) {
    return Schedule._normalize(date).isAfter(startDate);
  }

  bool isAfterOrOnStartDate(DateTime date) {
    return Schedule._normalize(date).isAfter(startDate) ||
        Schedule._normalize(date).isAtSameMomentAs(startDate);
  }

  bool isBeforeEndDate(DateTime date) {
    return Schedule._normalize(date).isBefore(endDate);
  }
}
