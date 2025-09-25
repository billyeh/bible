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

class _ReadingPageState extends State<ReadingPage> {
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> verses = [];
  late PageController _pageController;
  late int _initialPageIndex;
  bool _isTogglingAll = false;
  bool _isPageLoading = true;

  // Fast lookup for verses read
  late Set<String> _versesReadSet;

  @override
  void initState() {
    super.initState();

    _versesReadSet = widget.schedule.versesRead
        .map((v) => '${v.book}:${v.chapter}:${v.verse}')
        .toSet();

    // Ensure selectedDate is within schedule.
    if (!widget.schedule.isAfterOrOnStartDate(DateTime.now())) {
      selectedDate = widget.schedule.startDate;
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

  Future<void> _loadVersesForDate(DateTime date) async {
    setState(() => _isPageLoading = true);

    final v = await widget.schedule.getVersesForScheduleDate(
      widget.bible,
      date,
    );

    setState(() {
      selectedDate = date;
      verses = v;
      _isPageLoading = false;
    });
  }

  bool _allVersesRead() {
    return verses.isNotEmpty &&
        verses.every(
          (v) => _versesReadSet.contains(
            '${v['book']}:${v['chapter']}:${v['verse']}',
          ),
        );
  }

  Future<void> _checkOrUncheckAll() async {
    if (verses.isEmpty) return;

    setState(() => _isTogglingAll = true);

    final wasAllRead = _allVersesRead();

    for (final v in verses) {
      final key = '${v['book']}:${v['chapter']}:${v['verse']}';
      final alreadyRead = _versesReadSet.contains(key);

      if (wasAllRead && alreadyRead) {
        await _toggleVerse(v);
      } else if (!wasAllRead && !alreadyRead) {
        await _toggleVerse(v);
      }
    }

    setState(() => _isTogglingAll = false);
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

    final key = '$book:$chapter:$verseNum';
    final isRead = _versesReadSet.contains(key);

    await isar.writeTxn(() async {
      if (isRead) {
        _versesReadSet.remove(key);
        widget.schedule.versesRead.remove(verseRef);
      } else if (verseRef != null) {
        _versesReadSet.add(key);
        widget.schedule.versesRead.add(verseRef);
      }
      await widget.schedule.versesRead.save();
    });

    setState(() {}); // only necessary to refresh FAB and tile
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
            if (verses.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView.builder(
              itemCount: verses.length,
              itemBuilder: (context, index) {
                final v = Map<String, dynamic>.from(verses[index]);
                v['index'] = index;

                return VerseTile(
                  verse: v,
                  isRead: _versesReadSet.contains(
                    '${v['book']}:${v['chapter']}:${v['verse']}',
                  ),
                  onToggle: (newState) async {
                    await _toggleVerse(v);
                    setState(() {}); // rebuild tiles to reflect new state
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: verses.isEmpty || _isTogglingAll || _isPageLoading
            ? null
            : _checkOrUncheckAll,
        backgroundColor: const Color(0xff1d7fff),
        tooltip: _isPageLoading
            ? "Loading..."
            : _allVersesRead()
            ? "Uncheck All"
            : "Check All",
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: (_isTogglingAll || _isPageLoading)
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
}

class VerseTile extends StatelessWidget {
  final Map<String, dynamic> verse;
  final bool isRead;
  final void Function(bool isNowRead) onToggle;

  const VerseTile({
    super.key,
    required this.verse,
    required this.isRead,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: 16,
      color: isRead ? Colors.grey.shade500 : Colors.black,
    );
    final boldTextStyle = textStyle.copyWith(fontWeight: FontWeight.w600);

    return AnimatedTile(
      uniqueKey: '${verse['book']}-${verse['chapter']}-${verse['verse']}',
      staggerIndex: verse['index'] ?? 0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onToggle(!isRead),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${verse['book']} ${verse['chapter']}:${verse['verse']}",
                  style: boldTextStyle,
                ),
                Text("${verse['text']}", style: textStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
