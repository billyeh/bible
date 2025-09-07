import 'package:isar/isar.dart';
import 'verse.dart';

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
