import 'package:bible/models/schedule.dart';
import 'package:bible/bible_data/bible_data.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReadingPage extends StatefulWidget {
  final Schedule schedule;
  final BibleData bible;

  const ReadingPage({super.key, required this.schedule, required this.bible});

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  late Future<List<Map<String, dynamic>>> _versesFuture;

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadVerses();
  }

  void _loadVerses() {
    _versesFuture = widget.schedule.getVersesForScheduleDate(
      widget.bible,
      _selectedDate,
    );
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: widget.schedule.startDate,
      lastDate: widget.schedule.endDate,
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _loadVerses();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.schedule.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickDate,
            tooltip: 'Select date',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _versesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final verses = snapshot.data ?? [];
          if (verses.isEmpty) {
            return Center(
              child: Text(
                'No reading for ${dateFormat.format(_selectedDate)} 🎉',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: verses.length,
            itemBuilder: (context, index) {
              final verse = verses[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  "${verse['book']} ${verse['chapter']}:${verse['verse']} ${verse['text']}",
                  style: const TextStyle(fontSize: 16),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
