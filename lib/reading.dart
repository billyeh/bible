import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import 'package:bible/animated_tile.dart';
import 'package:bible/models/schedule.dart';
import 'package:bible/models/verse.dart';
import 'package:bible/bible_data/bible_data.dart';
import 'package:bible/main.dart';

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
  late PageController _pageController;
  late int _initialPageIndex;

  @override
  void initState() {
    super.initState();

    // Ensure selectedDate is within schedule.
    if (!widget.schedule.isAfterOrOnStartDate(DateTime.now())) {
      selectedDate = widget.schedule.startDate;
      // Delay SnackBar to show after build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Your schedule ${widget.schedule.name} hasn\'t started! Jumped to the first day of this schedule.',
            ),
          ),
        );
      });
    } else {
      selectedDate = DateTime.now();
    }

    _initialPageIndex = selectedDate
        .difference(widget.schedule.startDate)
        .inDays;
    _pageController = PageController(initialPage: _initialPageIndex);
    _loadVersesForDate(selectedDate);
  }

  @override
  void dispose() {
    _pageController.dispose();
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
    final dateFormat = DateFormat.MMMd();
    final totalDays =
        widget.schedule.endDate.difference(widget.schedule.startDate).inDays +
        1;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          "Reading for ${dateFormat.format(selectedDate)}",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
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
                final pageIndex = picked
                    .difference(widget.schedule.startDate)
                    .inDays;
                _pageController.jumpToPage(pageIndex);
                _loadVersesForDate(picked);
              }
            },
            tooltip: 'Select date',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        // Verse list
        child: PageView.builder(
          controller: _pageController,
          itemCount: totalDays,
          onPageChanged: (index) {
            final newDate = widget.schedule.startDate.add(
              Duration(days: index),
            );
            _loadVersesForDate(newDate);
          },
          itemBuilder: (context, index) {
            return verses.isEmpty
                ? Center(child: CircularProgressIndicator())
                : Padding(
                    padding: EdgeInsets.only(left: 10, right: 10),
                    child: ListView.builder(
                      itemCount: verses.length,
                      itemBuilder: (context, index) {
                        return AnimatedTile(
                          index: index,
                          child: _buildVerseTile(context, index),
                        );
                      },
                    ),
                  );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: verses.isEmpty ? null : _checkOrUncheckAll,
        backgroundColor: const Color(0xff1d7fff),
        tooltip: verses.isEmpty
            ? "Loading..."
            : _allVersesRead()
            ? "Uncheck All"
            : "Check All",
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: verses.isEmpty
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                )
              : Icon(
                  _allVersesRead() ? Icons.clear_all : Icons.done_all,
                  key: ValueKey(_allVersesRead()),
                ),
        ),
      ),
    );
  }

  Widget _buildVerseTile(BuildContext context, int index) {
    final v = verses[index];
    final isRead = _isVerseRead(v);
    final textStyle = TextStyle(
      fontSize: 16,
      color: isRead ? Colors.grey.shade500 : Colors.black,
    );
    final boldTextStyle = textStyle.copyWith(fontWeight: FontWeight.w600);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _toggleVerse(v),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${v['book']} ${v['chapter']}:${v['verse']}",
                style: boldTextStyle,
              ),
              Text("${v['text']}", style: textStyle),
            ],
          ),
        ),
      ),
    );
  }
}
