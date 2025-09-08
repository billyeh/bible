import 'package:bible/models/schedule.dart';
import 'package:bible/models/verse.dart';
import 'package:bible/bible_data/bible_data.dart';
import 'package:bible/main.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

class ReadingPage extends StatefulWidget {
  final Schedule schedule;
  final BibleData bible;

  const ReadingPage({super.key, required this.schedule, required this.bible});

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> verses = [];

  @override
  void initState() {
    super.initState();
    _loadVersesForDate(selectedDate);
  }

  Future<void> _loadVersesForDate(DateTime date) async {
    final v = await widget.schedule.getVersesForScheduleDate(
      widget.bible,
      date,
    );
    setState(() {
      selectedDate = date;
      verses = v;
    });
  }

  Future<void> _toggleVerse(Map<String, dynamic> verseRow) async {
    final book = verseRow['book'] as String;
    final chapter = verseRow['chapter'] as int;
    final verseNum = verseRow['verse'] as int;

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

    final isRead = widget.schedule.versesRead.contains(verseRef);

    await isar.writeTxn(() async {
      if (isRead) {
        widget.schedule.versesRead.remove(verseRef);
      } else if (verseRef != null) {
        widget.schedule.versesRead.add(verseRef);
      }
      await widget.schedule.versesRead.save();
    });

    setState(() {}); // Refresh UI
  }

  bool _isVerseRead(Map<String, dynamic> verseRow) {
    final book = verseRow['book'] as String;
    final chapter = verseRow['chapter'] as int;
    final verseNum = verseRow['verse'] as int;

    return widget.schedule.versesRead.any(
      (v) => v.book == book && v.chapter == chapter && v.verse == verseNum,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(
        title: Text("Reading for ${dateFormat.format(selectedDate)}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: widget.schedule.startDate,
                lastDate: widget.schedule.endDate,
              );
              if (picked != null) {
                _loadVersesForDate(picked);
              }
            },
            tooltip: 'Select date',
          ),
        ],
      ),
      body: Column(
        children: [
          // Verse list
          Expanded(
            child: verses.isEmpty
                ? Center(
                    child: Text(
                      'No reading for ${dateFormat.format(selectedDate)} 🎉',
                    ),
                  )
                : ListView.builder(
                    itemCount: verses.length,
                    itemBuilder: (context, index) {
                      final v = verses[index];
                      final isRead = _isVerseRead(v);
                      return ListTile(
                        title: Text(
                          "${v['book']} ${v['chapter']}:${v['verse']} ${v['text']}",
                          style: TextStyle(
                            decoration: isRead
                                ? TextDecoration.lineThrough
                                : null,
                            color: isRead ? Colors.grey : null,
                          ),
                        ),
                        trailing: Icon(
                          isRead
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isRead ? Colors.green : null,
                        ),
                        onTap: () => _toggleVerse(v),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
