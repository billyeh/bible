import 'package:isar/isar.dart';

part 'verse.g.dart';

@collection
class Verse {
  Id id = Isar.autoIncrement;

  late String book;

  late int chapter;

  late int verse;
}
