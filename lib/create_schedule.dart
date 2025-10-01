import 'package:bible/models/schedule.dart';
import 'package:bible/bible_data/bible_data.dart';
import 'package:bible/main.dart';

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';

class CreateSchedulePage extends StatefulWidget {
  const CreateSchedulePage({super.key});

  @override
  State<CreateSchedulePage> createState() => _CreateSchedulePageState();
}

class _CreateSchedulePageState extends State<CreateSchedulePage> {
  late Future<List<String>> _booksFuture;
  final BibleData _bibleData = BibleData();

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
    _booksFuture = _bibleData.getBooks();
  }

  void _updateFromVersesPerDay() {
    if (_totalVersesSelected == 0) return;

    final totalDays = (_totalVersesSelected / _versesPerDay).ceil();

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
        // Make sure end date is not before start date.
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

    setState(() {
      _totalVersesSelected = total;
    });
    _updateFromVersesPerDay();
  }

  void _updateAnimatedProgress() {
    if (!_isDragging) {
      _animatedProgress = _mapVersesToRatio(_versesPerDay);
    }
  }

  Widget _versesPerDayBar(bool isEnabled) {
    final activeColor = const Color(0xff1d7fff);
    final disabledColor = Colors.grey.shade400;
    final targetProgress = isEnabled ? _mapVersesToRatio(_versesPerDay) : 0.0;
    final displayProgress = _isDragging ? targetProgress : _animatedProgress;

    Widget buildFillBar() {
      if (_isDragging) {
        return LinearProgressIndicator(
          value: displayProgress,
          minHeight: 8,
          backgroundColor: Colors.grey.shade300,
          color: isEnabled ? activeColor : disabledColor,
        );
      } else {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: displayProgress, end: displayProgress),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          builder: (context, value, _) => LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: Colors.grey.shade300,
            color: isEnabled ? activeColor : disabledColor,
          ),
        );
      }
    }

    const knobSize = 12.0;
    Widget buildKnob(double width) {
      final knobPosition = (width - 12) * displayProgress;
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
            color: isEnabled ? activeColor : disabledColor,
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

        // Adjust for knob radius so it can actually reach both ends
        final dx = (localOffset.dx - knobSize / 2).clamp(0.0, width - knobSize);
        final ratio = (dx / (width - knobSize)).clamp(0.0, 1.0);

        final newValue = _mapRatioToVerses(ratio);
        setState(() => _versesPerDay = newValue);
        _updateFromVersesPerDay();
      },
      onHorizontalDragEnd: (_) {
        if (!isEnabled) return;
        setState(() {
          _isDragging = false;
          _animatedProgress = targetProgress; // animate to new value after drag
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _versesPerDayLabelAnimated(_versesPerDay, isEnabled),
          const SizedBox(height: 8),
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

  Widget _versesPerDayLabelAnimated(int verses, bool isEnabled) {
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
        } else if (displayValue <= 20 * 20) {
          final chapters = (displayValue / 20).ceil();
          text = "$chapters chapter${chapters == 1 ? '' : 's'} a day";
        } else {
          final books = (displayValue / (20 * 20)).ceil();
          text = "$books book${books == 1 ? '' : 's'} a day";
        }

        return Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isEnabled ? Colors.black : Colors.grey,
          ),
        );
      },
    );
  }

  int _mapRatioToVerses(double ratio) {
    if (ratio < 0.25) {
      // 0–25% → 1–20 verses (step 1)
      return 1 + (ratio / 0.25 * 19).round();
    } else if (ratio < 0.75) {
      // 25–75% → 1–20 chapters (step 1 chapter = 20 verses)
      final t = (ratio - 0.25) / 0.5;
      final steps = (t * 19).round(); // 0..19 steps
      return 20 + steps * 20; // start from 20 verses
    } else {
      // 75–100% → 1–20 books (step 1 book = 400 verses)
      final t = (ratio - 0.75) / 0.25;
      final steps = (t * 19).round(); // 0..19 steps
      return 400 + steps * 400; // start from 400 verses
    }
  }

  double _mapVersesToRatio(int verses) {
    late double ratio;
    if (verses <= 20) {
      ratio = (verses - 1) / 19 * 0.25;
    } else if (verses <= 20 * 20) {
      final steps = ((verses - 20) / 20).round();
      ratio = 0.25 + (steps / 19) * 0.5;
    } else {
      final steps = ((verses - 400) / 400).round();
      ratio = 0.75 + (steps / 19) * 0.25;
    }
    return min(ratio, 1);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Create plan",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: FutureBuilder<List<String>>(
          future: _booksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No books found"));
            }

            final books = snapshot.data!;
            final isEnabled = _totalVersesSelected > 0;

            return Column(
              children: [
                // Scrollable form content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    children: [
                      const SizedBox(height: 16),
                      // Name field
                      Text("Plan name", style: TextStyle(fontSize: 16)),
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
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                        controller: TextEditingController(text: _scheduleName),
                        onChanged: (val) => _scheduleName = val,
                      ),

                      const SizedBox(height: 32),

                      // Book selection
                      const Text(
                        "What are you reading?",
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
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
                            children: books.map((book) {
                              final selected = _selectedBooks.contains(book);
                              return CheckboxListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 0,
                                ),
                                title: Text(
                                  book,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                value: selected,
                                activeColor: const Color(0xff1d7fff),
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedBooks.add(book);
                                    } else {
                                      _selectedBooks.remove(book);
                                    }
                                    _updateTotalVersesSelected();
                                    _updateFromVersesPerDay();
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Reading speed
                      const Text(
                        "How fast do you want to go?",
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _versesPerDayBar(isEnabled)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Dates
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: isEnabled ? _pickStartDate : null,
                            child: Text(
                              "${dateFormat.format(_startDate)}  - ",
                              style: TextStyle(
                                fontSize: 16,
                                color: isEnabled ? Colors.black : Colors.grey,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: isEnabled ? _pickEndDate : null,
                            child: Text(
                              dateFormat.format(_endDate),
                              style: TextStyle(
                                fontSize: 16,
                                color: isEnabled ? Colors.black : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Bottom-aligned Create button
                Padding(
                  padding: const EdgeInsets.fromLTRB(36, 16, 36, 36),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff1d7fff),
                        foregroundColor: Colors.white,
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
                              );
                              await isar.writeTxn(() async {
                                await isar.schedules.put(schedule);
                              });
                              if (mounted) Navigator.pop(context);
                            },
                      child: const Text(
                        "Create Plan",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
