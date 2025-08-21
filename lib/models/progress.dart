import 'package:bible_reading/models/verse.dart';

class Progress {
  String? id;
  String? userId;
  String? scheduleId;
  Verse? verse;
  DateTime? timestamp;

  Progress({
    this.id,
    this.userId,
    this.scheduleId,
    this.verse,
    this.timestamp,
  });

  factory Progress.fromJson(Map<String, dynamic> json) {
    return Progress(
      id: json['id'],
      userId: json['userId'],
      scheduleId: json['scheduleId'],
      verse: json['verse'] != null ? Verse.fromJson(json['verse']) : null,
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'scheduleId': scheduleId,
      'verse': verse?.toJson(),
      'timestamp': timestamp?.toIso8601String(),
    };
  }
}
