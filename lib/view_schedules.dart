import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import 'package:bible/animated_tile.dart';
import 'package:bible/main.dart';
import 'package:bible/create_schedule.dart';
import 'package:bible/reading.dart';
import 'package:bible/bible_data/bible_data.dart';
import 'models/schedule.dart';

class SchedulesPage extends StatefulWidget {
  const SchedulesPage({super.key});

  @override
  State<SchedulesPage> createState() => _SchedulesPageState();
}

class _SchedulesPageState extends State<SchedulesPage> {
  List<Schedule> _schedules = [];
  bool _loading = true;
  final BibleData _bibleData = BibleData();
  String _filter = 'unfinished';

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _loading = true);

    final schedules = await isar.schedules.where().findAll();
    final filtered = <Schedule>[];

    for (final s in schedules) {
      final finished = await s.isScheduleFinished(_bibleData);
      if (_filter == 'finished' && finished) {
        filtered.add(s);
      } else if (_filter == 'unfinished' && !finished) {
        filtered.add(s);
      } else if (_filter == 'all') {
        filtered.add(s);
      }
    }
    _schedules = filtered;

    for (final s in _schedules) {
      await s.computeFormattedBooks(_bibleData);
    }

    setState(() => _loading = false);
  }

  Future<void> _deleteSchedule(Schedule schedule) async {
    await isar.writeTxn(() async {
      await isar.schedules.delete(schedule.id);
    });
    await _loadSchedules();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();

    late String noReadingPlans;
    if (_filter == 'finished') {
      noReadingPlans = "No finished reading plans.";
    } else if (_filter == 'unfinished') {
      noReadingPlans = "No unfinished reading plans.";
    } else {
      noReadingPlans = "No reading plans yet.";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Reading Plans",
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.w600),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.filter_list, size: 24),
                    onSelected: (value) async {
                      setState(() {
                        _filter = value;
                      });
                      await _loadSchedules();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'all', child: Text("All")),
                      const PopupMenuItem(
                        value: 'finished',
                        child: Text("Finished"),
                      ),
                      const PopupMenuItem(
                        value: 'unfinished',
                        child: Text("Unfinished"),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _schedules.isEmpty
                    ? Center(child: Text(noReadingPlans))
                    : ListView.separated(
                        padding: const EdgeInsets.only(left: 10, right: 12),
                        itemCount: _schedules.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 28),
                        itemBuilder: (context, index) {
                          final schedule = _schedules[index];
                          return AnimatedTile(
                            uniqueKey: schedule.id.toString(),
                            staggerIndex: index,
                            child: _buildScheduleTile(
                              schedule,
                              dateFormat,
                              index,
                              _bibleData,
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff1d7fff),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateSchedulePage()),
          );
          _loadSchedules(); // reload after adding a new schedule
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildScheduleTile(
    Schedule s,
    DateFormat dateFormat,
    int index,
    BibleData bibleData,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - t)),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReadingPage(schedule: s, bible: bibleData),
              ),
            );
            _loadSchedules(); // reload in case reading progress changed
          },
          onLongPress: () async {
            final confirm =
                await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Delete Schedule"),
                    content: Text(
                      "Are you sure you want to delete '${s.name}'?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text("Delete"),
                      ),
                    ],
                  ),
                ) ??
                false;
            if (confirm) _deleteSchedule(s);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${dateFormat.format(s.startDate)} - ${dateFormat.format(s.endDate)}",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.formattedBooks,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<double>(
                      future: s.getReadingProgress(bibleData),
                      builder: (context, snapshot) {
                        final readingProgress = snapshot.data ?? 0.0;
                        final timeProgress = s.getTimeProgress(DateTime.now());
                        final circleColor = readingProgress >= timeProgress
                            ? const Color(0xff1d7fff)
                            : Colors.grey.shade300;

                        return TweenAnimationBuilder<double>(
                          key: ValueKey(readingProgress),
                          tween: Tween(begin: 0.0, end: 1),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          builder: (context, t, child) {
                            return SizedBox(
                              height: 16,
                              child: Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: t * readingProgress,
                                      minHeight: 8,
                                      backgroundColor: Colors.grey.shade300,
                                      color: const Color(0xff1d7fff),
                                    ),
                                  ),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final width = constraints.maxWidth;
                                      final circlePosition =
                                          t * (width - 12) * timeProgress;
                                      return Transform.translate(
                                        offset: Offset(circlePosition, 0),
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: circleColor,
                                            border: Border.all(
                                              color: circleColor,
                                              width: 1.5,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
                Positioned(
                  top: 12,
                  right: 0,
                  child: FutureBuilder<bool>(
                    future: s.isReadingDone(bibleData, DateTime.now()),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox(width: 12, height: 12);
                      }
                      final done = snapshot.data ?? false;
                      return AnimatedOpacity(
                        opacity: done ? 0 : 1,
                        duration: const Duration(milliseconds: 500),
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: done
                                ? Colors.transparent
                                : const Color(0xff1d7fff),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
