import 'package:bible/main.dart';
import 'package:bible/create_schedule.dart';
import 'package:bible/reading.dart';
import 'package:bible/bible_data/bible_data.dart';

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
      appBar: AppBar(title: const Text("My Schedules")),
      body: FutureBuilder<List<Schedule>>(
        future: isar.schedules.where().findAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No schedules found"));
          }

          final schedules = snapshot.data!;
          return ListView.builder(
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final s = schedules[index];
              return Dismissible(
                key: ValueKey(s.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
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
                },
                onDismissed: (direction) {
                  _deleteSchedule(s);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Deleted '${s.name}'")),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(s.name),
                        subtitle: Text(
                          "${dateFormat.format(s.startDate)} → ${dateFormat.format(s.endDate)}\n"
                          "Books: ${s.booksToRead.join(', ')}",
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ReadingPage(schedule: s, bible: BibleData()),
                            ),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: FutureBuilder<double>(
                          future: s.getReadingProgress(BibleData()),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const LinearProgressIndicator();
                            }

                            final readingProgress = snapshot.data ?? 0.0;
                            final timeProgress = s.getTimeProgress(DateTime.now());

                            return LayoutBuilder(
                              builder: (context, constraints) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: Stack(
                                    children: [
                                      // Reading progress
                                      Container(
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      Container(
                                        height: 10,
                                        width: constraints.maxWidth * readingProgress,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                        ),
                                      ),

                                      // Time indicator
                                      Positioned(
                                        top: -2.5,
                                        left: constraints.maxWidth * timeProgress - 1,
                                        child: Container(
                                          height: 15,
                                          width: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateSchedulePage()),
          );
          setState(() {}); // Refresh list when returning.
        },
      ),
    );
  }
}
