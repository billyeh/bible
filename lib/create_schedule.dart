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

  @override
  void initState() {
    super.initState();
    _booksFuture = _bibleData.getBooks();
  }

  void _updateFromVersesPerDay() {
    if (_totalVersesSelected == 0) return;
    final totalDays = (_totalVersesSelected / _versesPerDay).ceil();
    setState(() {
      _endDate = _startDate.add(Duration(days: totalDays));
    });
  }

  void _updateFromEndDate() {
    if (_totalVersesSelected == 0) return;
    final totalDays = _endDate.difference(_startDate).inDays;
    setState(() {
      _versesPerDay = (_totalVersesSelected / totalDays).ceil();
    });
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
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
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: Text("Create schedule")),
      body: FutureBuilder<List<String>>(
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Schedule name
              TextField(
                decoration: const InputDecoration(labelText: "Schedule Name"),
                controller: TextEditingController(text: _scheduleName),
                onChanged: (val) => _scheduleName = val,
              ),
              const SizedBox(height: 20),

              // Book selection
              const Text(
                "What are you reading?",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              SizedBox(
                height: 200, // constrain height
                child: Scrollbar(
                  controller: _booksScrollController,
                  thumbVisibility: true, // now works ✅
                  child: ListView(
                    controller: _booksScrollController,
                    children: books.map((book) {
                      final selected = _selectedBooks.contains(book);
                      return CheckboxListTile(
                        title: Text(book),
                        value: selected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedBooks.add(book);
                            } else {
                              _selectedBooks.remove(book);
                            }
                            _updateFromVersesPerDay();
                            _updateTotalVersesSelected();
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),

              const Divider(),

              const Text(
                "How fast do you want to go?",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              // Verses per day
              Row(
                children: [
                  const Text("Verses per day"),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Slider(
                      value: _versesPerDay.toDouble(),
                      min: 1,
                      max: max(
                        _totalVersesSelected.toDouble(),
                        _versesPerDay.toDouble(),
                      ),
                      divisions: _totalVersesSelected > 0
                          ? _totalVersesSelected
                          : _versesPerDay,
                      label: _versesPerDay.toString(),
                      onChanged: _totalVersesSelected > 0
                          ? (val) {
                              setState(() => _versesPerDay = val.round());
                              _updateFromVersesPerDay();
                            }
                          : null,
                    ),
                  ),
                  SizedBox(width: 40, child: Text("$_versesPerDay")),
                ],
              ),

              // Date pickers
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickStartDate,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Start "),
                          Text(
                            dateFormat.format(_startDate),
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: _pickEndDate,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("End "),
                          Text(
                            dateFormat.format(_endDate),
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(),

              // Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Summary",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text("Books: ${_selectedBooks.join(', ')}"),
                      Text("Total verses: $_totalVersesSelected"),
                      Text("Verses per day: $_versesPerDay"),
                      Text("Start: ${dateFormat.format(_startDate)}"),
                      Text("End: ${dateFormat.format(_endDate)}"),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _selectedBooks.isEmpty
                    ? null
                    : () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Schedule created!")),
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
                        if (mounted) {
                          Navigator.pop(context);
                        }
                      },
                child: const Text("Create Schedule"),
              ),
            ],
          );
        },
      ),
    );
  }
}
