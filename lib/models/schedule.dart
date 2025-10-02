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

  // Computed compressed list of books for displaying.
  @ignore
  late String formattedBooks;
  Future<void> computeFormattedBooks(BibleData bibleData) async {
    formattedBooks = await bibleData.formatBookSelection(booksToRead);
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

  Future<List<Verse>> getAllVerses(BibleData bible) async {
    final verseMaps = await bible.getVerses(booksToRead);
    return verseMaps.map((map) {
      return Verse()
        ..book = map['book']
        ..chapter = map['chapter']
        ..verse = map['verse'];
    }).toList();
  }

  Future<bool> isScheduleFinished(BibleData bible) async {
    await versesRead.load();
    final allVerses = await getAllVerses(bible);

    if (allVerses.isEmpty && versesRead.isEmpty) {
      return true;
    }
    if (allVerses.length != versesRead.length) {
      return false;
    }

    final allVersesSet = allVerses
        .map((v) => '${v.book}-${v.chapter}-${v.verse}')
        .toSet();
    final versesReadSet = versesRead
        .map((v) => '${v.book}-${v.chapter}-${v.verse}')
        .toSet();

    return allVersesSet.difference(versesReadSet).isEmpty;
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

  double getTimeProgress(DateTime now) {
    final today = Schedule._normalize(now);

    if (today.isBefore(startDate)) {
      return 0.0;
    }
    if (today.isAfter(endDate) || today.isAtSameMomentAs(endDate)) {
      return 1.0;
    }

    final total = endDate.difference(startDate).inDays;
    if (total <= 0) {
      return 1.0;
    }
    final elapsed = today.difference(startDate).inDays;
    return elapsed / total;
  }

  Future<double> getReadingProgress(BibleData bible) async {
    await versesRead.load();
    final verseCounts = await bible.getVersesInBooks(booksToRead);
    final totalVerses = bible.countTotalVerses(verseCounts);

    if (totalVerses == 0) {
      return 1.0;
    }

    return versesRead.length / totalVerses;
  }

  /// Returns true if the user has completed today's reading.
  Future<bool> isReadingDone(BibleData bible, DateTime time) async {
    await versesRead.load();
    final todayVerses = await getVersesForScheduleDate(bible, time);

    if (todayVerses.isEmpty) {
      return true;
    }

    final todaySet = todayVerses
        .map((v) => '${v['book']}-${v['chapter']}-${v['verse']}')
        .toSet();
    final readSet = versesRead
        .map((v) => '${v.book}-${v.chapter}-${v.verse}')
        .toSet();
    return todaySet.difference(readSet).isEmpty;
  }
}
