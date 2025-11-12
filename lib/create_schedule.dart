import 'package:bible/models/schedule.dart';
import 'package:bible/bible_data/bible_data.dart';
import 'package:bible/main.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:intl/intl.dart';

class CreateSchedulePage extends StatefulWidget {
  const CreateSchedulePage({super.key});

  @override
  State<CreateSchedulePage> createState() => _CreateSchedulePageState();
}

class _CreateSchedulePageState extends State<CreateSchedulePage> {
  final BibleData _bibleData = BibleData();
  Map<String, List<String>>? _booksByTestament;
  bool _loadingBooks = true;

  final ScrollController _booksScrollController = ScrollController();

  @override
  void dispose() {
    _booksScrollController.dispose();
    super.dispose();
  }

  // Form fields
  String _scheduleName = "My Reading Plan";
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 365));
  int _versesPerDay = 10;

  final Set<String> _selectedBooks = {};
  int _totalVersesSelected = 0;
  double _animatedProgress = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final data = await _bibleData.getBooksByTestament();
    setState(() {
      _booksByTestament = data;
      _loadingBooks = false;
    });
  }

  Widget _buildGroupTile(
    String label,
    List<String> books,
    Color primaryColor,
    TextStyle labelStyle,
  ) {
    final allSelected = books.every(_selectedBooks.contains);
    final someSelected = books.any(_selectedBooks.contains);

    return CheckboxListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: labelStyle),
      value: allSelected ? true : (someSelected ? null : false),
      tristate: true,
      activeColor: primaryColor,
      onChanged: (checked) {
        setState(() {
          if (checked == true) {
            _selectedBooks.addAll(books);
          } else {
            _selectedBooks.removeAll(books);
          }
          _updateTotalVersesSelected();
        });
      },
    );
  }

  Widget _buildBookTile(String book, Color primaryColor, TextStyle textStyle) {
    final selected = _selectedBooks.contains(book);
    return CheckboxListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(book, style: textStyle),
      value: selected,
      activeColor: primaryColor,
      onChanged: (checked) {
        setState(() {
          if (checked == true) {
            _selectedBooks.add(book);
          } else {
            _selectedBooks.remove(book);
          }
          _updateTotalVersesSelected();
        });
      },
    );
  }

  void _updateFromVersesPerDay() {
    if (_totalVersesSelected == 0) return;
    var totalDays = (_totalVersesSelected / _versesPerDay).ceil();
    if (_totalVersesSelected / _versesPerDay % 1 > 0) {
      totalDays += 1;
    }
    setState(() {
      _endDate = _startDate.add(Duration(days: max(1, totalDays - 1)));
      _updateAnimatedProgress();
    });
  }

  void _updateFromEndDate() {
    if (_totalVersesSelected == 0) return;
    final totalDays = _endDate.difference(_startDate).inDays + 1;
    setState(() {
      _versesPerDay = (_totalVersesSelected / totalDays).ceil();
      _updateAnimatedProgress();
    });
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
      });
      _updateFromVersesPerDay();
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
      _updateFromEndDate();
    }
  }

  Future<void> _updateTotalVersesSelected() async {
    final bookVerseCounts = await _bibleData.getVersesInBooks(
      _selectedBooks.toList(),
    );
    final total = _bibleData.countTotalVerses(bookVerseCounts);

    _totalVersesSelected = total;
    _updateFromVersesPerDay();
  }

  void _updateAnimatedProgress() {
    if (!_isDragging) {
      _animatedProgress = _mapVersesToRatio(_versesPerDay);
    }
  }

  int _mapRatioToVerses(double ratio) {
    if (ratio < 0.25) {
      return 1 + (ratio / 0.25 * 19).round();
    } else if (ratio < 0.75) {
      final t = (ratio - 0.25) / 0.5;
      final steps = (t * 19).round();
      return 20 + steps * 20;
    } else {
      final t = (ratio - 0.75) / 0.25;
      final steps = (t * 19).round();
      return 400 + steps * 400;
    }
  }

  double _mapVersesToRatio(int verses) {
    late double ratio;
    if (verses <= 20) {
      ratio = (verses - 1) / 19 * 0.25;
    } else if (verses <= 400) {
      final steps = ((verses - 20) / 20).round();
      ratio = 0.25 + (steps / 19) * 0.5;
    } else {
      final steps = ((verses - 400) / 400).round();
      ratio = 0.75 + (steps / 19) * 0.25;
    }
    return min(ratio, 1);
  }

  Widget _versesPerDayBar(
    bool isEnabled,
    Color primaryColor,
    Color onSurface,
    TextStyle textStyle,
  ) {
    final targetProgress = isEnabled ? _mapVersesToRatio(_versesPerDay) : 0.0;
    final displayProgress = _isDragging ? targetProgress : _animatedProgress;

    Widget buildFillBar() {
      if (_isDragging) {
        return LinearProgressIndicator(
          value: displayProgress,
          minHeight: 8,
          backgroundColor: onSurface.withValues(alpha: 0.2),
          color: isEnabled ? primaryColor : onSurface.withValues(alpha: 0.4),
        );
      } else {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: displayProgress, end: displayProgress),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          builder: (context, value, _) => LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: onSurface.withValues(alpha: 0.2),
            color: isEnabled ? primaryColor : onSurface.withValues(alpha: 0.4),
          ),
        );
      }
    }

    const knobSize = 12.0;
    Widget buildKnob(double width) {
      final knobPosition = (width - knobSize) * displayProgress;
      return AnimatedContainer(
        duration: _isDragging
            ? Duration.zero
            : const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        transform: Matrix4.translationValues(knobPosition, 0, 0),
        child: Container(
          width: knobSize,
          height: knobSize,
          decoration: BoxDecoration(
            color: isEnabled ? primaryColor : onSurface.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    return GestureDetector(
      onHorizontalDragStart: (_) {
        if (!isEnabled) return;
        setState(() => _isDragging = true);
      },
      onHorizontalDragUpdate: (details) {
        if (!isEnabled) return;
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final localOffset = box.globalToLocal(details.globalPosition);
        final width = box.size.width;
        final dx = (localOffset.dx - knobSize / 2).clamp(0.0, width - knobSize);
        final ratio = (dx / (width - knobSize)).clamp(0.0, 1.0);
        setState(() => _versesPerDay = _mapRatioToVerses(ratio));
        _updateFromVersesPerDay();
      },
      onHorizontalDragEnd: (_) {
        if (!isEnabled) return;
        setState(() {
          _isDragging = false;
          _animatedProgress = targetProgress;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _versesPerDayLabelAnimated(
            _versesPerDay,
            isEnabled,
            onSurface,
            textStyle,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: buildFillBar(),
                  ),
                  buildKnob(width),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _versesPerDayLabelAnimated(
    int verses,
    bool isEnabled,
    Color onSurface,
    TextStyle textStyle,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 0,
        end: _isDragging ? verses.toDouble() : verses.toDouble(),
      ),
      duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        final int displayValue = value.round();
        String text;
        if (displayValue <= 20) {
          text = "$displayValue verse${displayValue == 1 ? '' : 's'} a day";
        } else if (displayValue <= 400) {
          final chapters = (displayValue / 20).ceil();
          text = "$chapters chapter${chapters == 1 ? '' : 's'} a day";
        } else {
          final books = (displayValue / 400).ceil();
          text = "$books book${books == 1 ? '' : 's'} a day";
        }
        return Text(
          text,
          style: textStyle.copyWith(
            color: isEnabled
                ? textStyle.color
                : textStyle.color?.withValues(alpha: 0.5),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd();
    final otBooks = _booksByTestament?["Old Testament"] ?? [];
    final ntBooks = _booksByTestament?["New Testament"] ?? [];
    final isEnabled = _totalVersesSelected > 0;

    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final bookTextStyle = theme.textTheme.bodyMedium!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Create plan",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness:
              theme.colorScheme.brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: _loadingBooks
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      children: [
                        const SizedBox(height: 16),
                        Text("Plan name", style: theme.textTheme.titleMedium),
                        TextField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: -4,
                              vertical: 0,
                            ),
                          ),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          controller: TextEditingController(
                            text: _scheduleName,
                          ),
                          onChanged: (val) => _scheduleName = val,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          "What are you reading?",
                          style: theme.textTheme.titleMedium,
                        ),
                        Container(
                          height: 220,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Scrollbar(
                            controller: _booksScrollController,
                            thumbVisibility: true,
                            child: ListView(
                              controller: _booksScrollController,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              children: [
                                _buildGroupTile(
                                  "Old Testament",
                                  otBooks,
                                  primaryColor,
                                  bookTextStyle,
                                ),
                                ...otBooks.map(
                                  (b) => _buildBookTile(
                                    b,
                                    primaryColor,
                                    bookTextStyle,
                                  ),
                                ),
                                _buildGroupTile(
                                  "New Testament",
                                  ntBooks,
                                  primaryColor,
                                  bookTextStyle,
                                ),
                                ...ntBooks.map(
                                  (b) => _buildBookTile(
                                    b,
                                    primaryColor,
                                    bookTextStyle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          "How fast do you want to go?",
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: isEnabled ? _pickStartDate : null,
                              child: Text(
                                "${dateFormat.format(_startDate)}  - ",
                                style: bookTextStyle.copyWith(
                                  color: isEnabled
                                      ? bookTextStyle.color
                                      : bookTextStyle.color?.withValues(
                                          alpha: 0.5,
                                        ),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: isEnabled ? _pickEndDate : null,
                              child: Text(
                                dateFormat.format(_endDate),
                                style: bookTextStyle.copyWith(
                                  color: isEnabled
                                      ? bookTextStyle.color
                                      : bookTextStyle.color?.withValues(
                                          alpha: 0.5,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _versesPerDayBar(
                                isEnabled,
                                primaryColor,
                                onSurface,
                                bookTextStyle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(36, 16, 36, 36),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          foregroundColor: theme.colorScheme.onPrimaryContainer,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _selectedBooks.isEmpty
                            ? null
                            : () async {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Schedule created!"),
                                  ),
                                );
                                final schedule = Schedule.create(
                                  name: _scheduleName,
                                  startDate: _startDate,
                                  endDate: _endDate,
                                  booksToRead: _selectedBooks.toList(),
                                  uuid: null,
                                );
                                await isar.writeTxn(() async {
                                  await isar.schedules.put(schedule);
                                });
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                        child: Text(
                          "Create Plan",
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _selectedBooks.isEmpty
                                ? theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  )
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
