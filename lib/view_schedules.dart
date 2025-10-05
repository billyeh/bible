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
  String _filter = 'all';

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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    late String noReadingPlans;
    if (_filter == 'finished') {
      noReadingPlans = "No finished reading plans.";
    } else if (_filter == 'unfinished') {
      noReadingPlans = "No unfinished reading plans.";
    } else {
      noReadingPlans = "No reading plans yet.";
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
                  Text(
                    "Reading Plans",
                    style: textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.filter_list,
                      size: textTheme.headlineLarge?.fontSize,
                    ),
                    onSelected: (value) async {
                      setState(() {
                        _filter = value;
                      });
                      await _loadSchedules();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'all',
                        child: Text(
                          "All",
                          style: _filter == 'all'
                              ? const TextStyle(fontWeight: FontWeight.bold)
                              : null,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'finished',
                        child: Text(
                          "Finished",
                          style: _filter == 'finished'
                              ? const TextStyle(fontWeight: FontWeight.bold)
                              : null,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'unfinished',
                        child: Text(
                          "Unfinished",
                          style: _filter == 'unfinished'
                              ? const TextStyle(fontWeight: FontWeight.bold)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _schedules.isEmpty
                    ? Center(child: Text(noReadingPlans))
                    : ListView.separated(
                        itemCount: _schedules.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 28),
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
                              colorScheme,
                              textTheme,
                            ),
                          );
                        },
                      ),
              ),
              SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
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
    ColorScheme colorScheme,
    TextTheme textTheme,
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
            _loadSchedules();
          },
          onLongPress: () async {
            final confirm =
                await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Delete Schedule"),
                    content: Text(
                      "Are you sure you want to delete '${s.name}'?",
                      style: Theme.of(context).textTheme.bodyMedium,
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
                    Hero(
                      tag: "schedule-title-${s.id}", // unique per schedule
                      child: Text(
                        s.name,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Hero(
                      tag: "schedule-dates-${s.id}",
                      child: Text(
                        "${dateFormat.format(s.startDate)} - ${dateFormat.format(s.endDate)}",
                        style: textTheme.bodyMedium?.copyWith(
                          color: textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(s.formattedBooks, style: textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    Hero(
                      tag: "schedule-progress-${s.id}",
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: FutureBuilder<double>(
                          future: s.getReadingProgress(bibleData),
                          builder: (context, snapshot) {
                            final readingProgress = snapshot.data ?? 0.0;
                            final timeProgress = s.getTimeProgress(
                              DateTime.now(),
                            );
                            final primary = colorScheme.primary;

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
                                          color: primary,
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
                                                color: primary,
                                                border: Border.all(
                                                  color: primary,
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
                      ),
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
                                : colorScheme.primary,
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
