import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import 'package:bible/main.dart';
import 'package:bible/create_schedule.dart';
import 'package:bible/reading.dart';
import 'package:bible/bible_data/bible_data.dart';
import 'models/schedule.dart';

class AnimatedScheduleTile extends StatefulWidget {
  final Widget child;
  final int index;

  const AnimatedScheduleTile({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  State<AnimatedScheduleTile> createState() => _AnimatedScheduleTileState();
}

class _AnimatedScheduleTileState extends State<AnimatedScheduleTile>
    with SingleTickerProviderStateMixin {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 100 * widget.index), () {
      if (mounted) {
        setState(() {
          _visible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: _visible ? 1 : 0,
      curve: Curves.easeOut,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        offset: _visible ? Offset.zero : const Offset(0, 0.1),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class SchedulesPage extends StatefulWidget {
  const SchedulesPage({super.key});

  @override
  State<SchedulesPage> createState() => _SchedulesPageState();
}

class _SchedulesPageState extends State<SchedulesPage> {
  Future<void> _deleteSchedule(Schedule schedule) async {
    await isar.writeTxn(() async {
      await isar.schedules.delete(schedule.id);
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Padding(
                padding: EdgeInsets.only(left: 14),
                child: Text(
                  "Reading Plans",
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 40),

              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: 10, right: 12),
                  child: FutureBuilder<List<Schedule>>(
                    future: isar.schedules.where().findAll(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text("No reading plans yet."),
                        );
                      }

                      final schedules = snapshot.data!;
                      return ListView.separated(
                        itemCount: schedules.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 28),
                        itemBuilder: (context, index) {
                          return AnimatedScheduleTile(
                            index: index,
                            child: _buildScheduleTile(
                              schedules[index],
                              dateFormat,
                              index,
                            ),
                          );
                        },
                      );
                    },
                  ),
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
          setState(() {});
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildScheduleTile(Schedule s, DateFormat dateFormat, int index) {
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
                builder: (_) => ReadingPage(schedule: s, bible: BibleData()),
              ),
            );
            setState(() {});
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
                      s.booksToRead.join(', '),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<double>(
                      future: s.getReadingProgress(BibleData()),
                      builder: (context, snapshot) {
                        final readingProgress = snapshot.data ?? 0.0;
                        final timeProgress = s.getTimeProgress(DateTime.now());
                        return TweenAnimationBuilder<double>(
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
                                            color:
                                                readingProgress >= timeProgress
                                                ? Color(0xff1d7fff)
                                                : Colors.grey.shade300,
                                            border: Border.all(
                                              color: Color(0xff1d7fff),
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
                    future: s.isReadingDone(BibleData(), DateTime.now()),
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
                                // : Color(0xffE6F0FA),
                                : Color(0xff1d7fff),
                            // : Colors.grey.shade300,
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
