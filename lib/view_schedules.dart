import 'package:bible/main.dart';
import 'package:bible/create_schedule.dart';
import 'package:bible/reading.dart';
import 'package:bible/bible_data/bible_data.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import 'models/schedule.dart';

class SchedulesPage extends StatefulWidget {
  const SchedulesPage({super.key});

  @override
  State<SchedulesPage> createState() => _SchedulesPageState();
}

class _SchedulesPageState extends State<SchedulesPage> {
  final _pageController = PageController(viewportFraction: 0.9);

  Future<void> _deleteSchedule(Schedule schedule) async {
    await isar.writeTxn(() async {
      await isar.schedules.delete(schedule.id);
    });
    setState(() {}); // refresh after delete
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      backgroundColor: Color(0xFFF9F9F9),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 0),
              child: _buildReadingPlansCard(dateFormat),
            ),

            // Example of a second page for later:
            // Padding(
            //   padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            //   child: Card(child: Center(child: Text("Another Feature"))),
            // ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateSchedulePage()),
          );
          setState(() {});
        },
        backgroundColor: const Color(0xff1d7fff),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildReadingPlansCard(DateFormat dateFormat) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(28.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 5,
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "My Reading Plans",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: FutureBuilder<List<Schedule>>(
                  future: isar.schedules.where().findAll(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("No reading plans yet."));
                    }

                    final schedules = snapshot.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: schedules.length,
                      itemBuilder: (context, index) {
                        final s = schedules[index];
                        return Dismissible(
                          key: ValueKey(s.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Delete Schedule"),
                                    content: Text(
                                      "Are you sure you want to delete '${s.name}'?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text("Delete"),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false;
                          },
                          onDismissed: (direction) {
                            _deleteSchedule(s);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Deleted '${s.name}'")),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFfbf2e0),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReadingPage(
                                      schedule: s,
                                      bible: BibleData(),
                                    ),
                                  ),
                                ).then((_) => setState(() {}));
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          CupertinoIcons.rocket_fill,
                                          color: Color(
                                            0xFF8B4513,
                                          ), // SaddleBrown
                                          size: 40,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                s.name,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              Text(
                                                "${dateFormat.format(s.startDate)} → ${dateFormat.format(s.endDate)}",
                                                style: TextStyle(
                                                  color: Colors.grey.shade800,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(CupertinoIcons.book),
                                        const SizedBox(width: 2),
                                        Text(
                                          s.booksToRead.join(', '),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    FutureBuilder<double>(
                                      future: s.getReadingProgress(BibleData()),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const LinearProgressIndicator();
                                        }

                                        final readingProgress =
                                            snapshot.data ?? 0.0;
                                        final timeProgress = s.getTimeProgress(
                                          DateTime.now(),
                                        );

                                        return LayoutBuilder(
                                          builder: (context, constraints) {
                                            final barWidth =
                                                constraints.maxWidth *
                                                readingProgress;
                                            final markerLeft =
                                                constraints.maxWidth *
                                                timeProgress;

                                            return Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Container(
                                                    height: 12,
                                                    color: Colors.black
                                                        .withOpacity(0.1),
                                                  ),
                                                ),
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Container(
                                                    height: 12,
                                                    width: barWidth,
                                                    decoration:
                                                        const BoxDecoration(
                                                          gradient:
                                                              LinearGradient(
                                                                colors: [
                                                                  Color(
                                                                    0xff1d7fff,
                                                                  ),
                                                                  Color(
                                                                    0xFFbfd9a3,
                                                                  ),
                                                                ],
                                                                begin: Alignment
                                                                    .centerLeft,
                                                                end: Alignment
                                                                    .centerRight,
                                                              ),
                                                        ),
                                                  ),
                                                ),
                                                Positioned(
                                                  left: markerLeft.clamp(
                                                    0,
                                                    constraints.maxWidth - 1,
                                                  ),
                                                  top: -6,
                                                  bottom: -6,
                                                  child: Container(
                                                    width: 2,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            1,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(0.4),
                                                          blurRadius: 3,
                                                          spreadRadius: 0.5,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
