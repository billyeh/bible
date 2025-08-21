import 'package:bible_reading/models/verse.dart';

enum ScheduleType {
  booksByDate,
  versesPerDay,
}

class Schedule {
  String? id;
  String? userId;
  String? name;
  ScheduleType? type;
  DateTime? startDate;
  DateTime? endDate;
  List<String>? books;
  int? dailyVerseGoal;
  Verse? currentVerse;
  bool? isArchived;

  Schedule({
    this.id,
    this.userId,
    this.name,
    this.type,
    this.startDate,
    this.endDate,
    this.books,
    this.dailyVerseGoal,
    this.currentVerse,
    this.isArchived = false,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      type: json['type'] != null ? ScheduleType.values.byName(json['type']) : null,
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      books: json['books'] != null ? List<String>.from(json['books']) : null,
      dailyVerseGoal: json['dailyVerseGoal'],
      currentVerse: json['currentVerse'] != null ? Verse.fromJson(json['currentVerse']) : null,
      isArchived: json['isArchived'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'type': type?.name,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'books': books,
      'dailyVerseGoal': dailyVerseGoal,
      'currentVerse': currentVerse?.toJson(),
      'isArchived': isArchived,
    };
  }
}
