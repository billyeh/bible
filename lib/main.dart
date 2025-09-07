import 'package:flutter/material.dart';
import 'bible_data/bible_data.dart';
import 'package:intl/intl.dart'; // for date formatting

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bible Reading App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'New Schedule'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<String>> _booksFuture;
  final BibleData _bibleData = BibleData();

  final ScrollController _booksScrollController = ScrollController();

  // dispose it in your State class
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

  // Selected books
  final Set<String> _selectedBooks = {};

  // TODO: Hook this up to verse counts from your Bible DB
  int get _totalVersesSelected {
    // for now, fake it — replace with real lookup later
    return _selectedBooks.length * 1000;
  }

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

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
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
                  const Text("Verses per day:"),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Slider(
                      value: _versesPerDay.toDouble(),
                      min: 1,
                      max: _totalVersesSelected.toDouble(),
                      divisions: 49,
                      label: _versesPerDay.toString(),
                      onChanged: (val) {
                        setState(() => _versesPerDay = val.round());
                        _updateFromVersesPerDay();
                      },
                    ),
                  ),
                  SizedBox(width: 40, child: Text("$_versesPerDay")),
                ],
              ),

              // Date pickers
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text("Start Date"),
                      subtitle: Text(dateFormat.format(_startDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _pickStartDate,
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text("End Date"),
                      subtitle: Text(dateFormat.format(_endDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _pickEndDate,
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
                    : () {
                        // TODO: Save to Isar later
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Schedule created!")),
                        );
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
