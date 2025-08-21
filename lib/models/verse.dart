class Verse {
  final int id;
  final int book;
  final int chapter;
  final int verse;
  final String text;

  static const String columnId = 'id';
  static const String columnBook = 'b';
  static const String columnChapter = 'c';
  static const String columnVerse = 'v';
  static const String columnText = 't';

  static final columns = [columnId, columnBook, columnChapter, columnVerse, columnText];

  Verse({
    required this.id,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
  });

  factory Verse.fromMap(Map<String, dynamic> map) {
    return Verse(
      id: map[columnId],
      book: map[columnBook],
      chapter: map[columnChapter],
      verse: map[columnVerse],
      text: map[columnText],
    );
  }

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      id: json[columnId],
      book: json[columnBook],
      chapter: json[columnChapter],
      verse: json[columnVerse],
      text: json[columnText],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      columnId: id,
      columnBook: book,
      columnChapter: chapter,
      columnVerse: verse,
      columnText: text,
    };
  }
}
