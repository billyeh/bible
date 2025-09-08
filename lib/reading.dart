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

class _ReadingPageState extends State<ReadingPage>
    with SingleTickerProviderStateMixin {
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> verses = [];
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _bounceAnimation =
        TweenSequence([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(parent: _bounceController, curve: Curves.easeOut),
        );

    _loadVersesForDate(selectedDate);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _checkOrUncheckAll() async {
    final wasAllRead = _allVersesRead();
    if (wasAllRead) {
      // Uncheck all
      for (final v in verses) {
        if (_isVerseRead(v)) {
          await _toggleVerse(v);
        }
      }
    } else {
      // Check all
      for (final v in verses) {
        if (!_isVerseRead(v)) {
          await _toggleVerse(v);
        }
      }

      // Play bounce only if all are now read
      if (_allVersesRead()) {
        _bounceController.forward(from: 0);
      }
    }
    setState(() {});
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

  bool _allVersesRead() {
    return verses.isNotEmpty && verses.every((v) => _isVerseRead(v));
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton.filled(
              onPressed: widget.schedule.isAfterStartDate(selectedDate)
                  ? () => _loadVersesForDate(
                      selectedDate.subtract(const Duration(days: 1)),
                    )
                  : null,
              icon: const Icon(Icons.arrow_back),
              tooltip: "Previous Day",
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: ScaleTransition(
                key: ValueKey(_allVersesRead()),
                scale: _bounceAnimation,
                child: FloatingActionButton(
                  key: ValueKey(_allVersesRead()),
                  onPressed: _checkOrUncheckAll,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  highlightElevation: 12,

                  tooltip: _allVersesRead() ? "Uncheck All" : "Check All",
                  child: Icon(
                    _allVersesRead() ? Icons.clear_all : Icons.done_all,
                    size: 30,
                  ),
                ),
              ),
            ),
            IconButton.filled(
              onPressed: widget.schedule.isBeforeEndDate(selectedDate)
                  ? () => _loadVersesForDate(
                      selectedDate.add(const Duration(days: 1)),
                    )
                  : null,
              icon: const Icon(Icons.arrow_forward),
              tooltip: "Next Day",
            ),
          ],
        ),
      ),
    );
  }
}
