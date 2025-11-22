import 'package:isar/isar.dart';

part 'verse.g.dart';

@collection
class Verse {
  Id id = Isar.autoIncrement;

  late String book;

  late int chapter;

  late int verse;

  static Future<Verse> findOrCreate(
    Isar isar, {
    required String book,
    required int chapter,
    required int verseNum,
  }) async {
    Verse? verseRef = await isar.verses
        .filter()
        .bookEqualTo(book)
        .chapterEqualTo(chapter)
        .verseEqualTo(verseNum)
        .findFirst();

    if (verseRef == null) {
      verseRef = Verse()
        ..book = book
        ..chapter = chapter
        ..verse = verseNum;
      await isar.writeTxn(() async {
        await isar.verses.put(verseRef!);
      });
    }
    return verseRef;
  }
}
