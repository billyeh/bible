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

  late Set<String> _versesReadSet;
  final Map<int, ScrollController> _scrollControllers = {};

  ScrollController _getScrollController(int pageIndex) {
    return _scrollControllers.putIfAbsent(pageIndex, () => ScrollController());
  }

  @override
  void initState() {
    super.initState();

    _versesReadSet = widget.schedule.versesRead
        .map((v) => '${v.book}:${v.chapter}:${v.verse}')
        .toSet();

    // Ensure selectedDate is within schedule
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
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  int _getVersesToRead() => verses.length;

  int _getVersesRead() {
    return verses
        .where(
          (v) => _versesReadSet.contains(
            '${v['book']}:${v['chapter']}:${v['verse']}',
          ),
        )
        .length;
  }

  double _getOverallProgress() {
    final totalVerses = verses.length;
    final readCount = _getVersesRead();
    return totalVerses == 0 ? 0.0 : readCount / totalVerses;
  }

  String _getProgressText() => "${_getVersesRead()}/${_getVersesToRead()}";

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

    setState(() {});
  }

  Future<void> _toggleAllAbove(int index) async {
    if (verses.isEmpty) return;

    for (int i = 0; i <= index; i++) {
      final v = verses[i];
      final key = '${v['book']}:${v['chapter']}:${v['verse']}';
      if (!_versesReadSet.contains(key)) {
        await _toggleVerse(v);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    final totalDays =
        widget.schedule.endDate.difference(widget.schedule.startDate).inDays +
        1;

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Hero(
          tag: "schedule-title-${widget.schedule.id}",
          child: Material(
            color: Colors.transparent,
            child: Text(
              widget.schedule.name,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_today,
              color: colorScheme.onSurface,
              size: textTheme.titleLarge?.fontSize,
            ),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Hero(
              tag: "schedule-dates-${widget.schedule.id}",
              child: Text(
                dateFormat.format(selectedDate),
                style: textTheme.bodyMedium?.copyWith(
                  color: textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
          // Progress bar
          Hero(
            tag: "schedule-progress-${widget.schedule.id}",
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: _getOverallProgress()),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 8,
                            color: colorScheme.primary,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getProgressText(),
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // PageView
          Expanded(
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

                final scrollController = _getScrollController(index);

                return Scrollbar(
                  controller: scrollController,
                  thumbVisibility: false,
                  interactive: true,
                  thickness: 8,
                  radius: const Radius.circular(4),
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    itemCount: verses.length,
                    itemBuilder: (context, idx) {
                      final v = Map<String, dynamic>.from(verses[idx]);
                      return VerseTile(
                        verse: v,
                        index: index,
                        isRead: _versesReadSet.contains(
                          '${v['book']}:${v['chapter']}:${v['verse']}',
                        ),
                        onToggle: (newState) async {
                          await _toggleVerse(v);
                        },
                        onLongPress: () async {
                          await _toggleAllAbove(idx);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 100),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: verses.isEmpty || _isTogglingAll || _isPageLoading
            ? null
            : _checkOrUncheckAll,
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
  final int index;
  final bool isRead;
  final void Function(bool isNowRead) onToggle;
  final VoidCallback? onLongPress;

  const VerseTile({
    super.key,
    required this.verse,
    required this.index,
    required this.isRead,
    required this.onToggle,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final textStyle =
        textTheme.bodyMedium?.copyWith(
          color: isRead
              ? colorScheme.onSurface.withValues(alpha: 0.2)
              : colorScheme.onSurface,
        ) ??
        const TextStyle();

    final boldTextStyle = textStyle.copyWith(
      fontSize: textTheme.titleMedium?.fontSize,
    );

    return AnimatedTile(
      uniqueKey: '${verse['book']}-${verse['chapter']}-${verse['verse']}',
      staggerIndex: verse['index'] ?? 0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onToggle(!isRead),
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${verse['book']} ${verse['chapter']}:${verse['verse']}",
                  style: boldTextStyle,
                ),
                SizedBox(height: 8),
                Text("${verse['text']}", style: textStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
