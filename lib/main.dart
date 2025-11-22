import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'package:bible/models/verse.dart';
import 'package:bible/models/schedule.dart';
import 'package:bible/view_schedules.dart';
import 'package:bible/services/home_widget_service.dart';

import 'firebase_options.dart';

late Isar isar;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final dir = await getApplicationDocumentsDirectory();
  isar = await Isar.open([ScheduleSchema, VerseSchema], directory: dir.path);
  await HomeWidgetService.initialize();
  await HomeWidgetService.registerBackgroundCallback();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bible Reading App',

      themeMode: ThemeMode.system,

      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: const Color(0xff1d7fff),
              brightness: Brightness.light,
            ).copyWith(
              primary: const Color(0xff1d7fff), // 💡 force vibrant blue
            ),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff1d7fff),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),

      home: const SchedulesPage(),
    );
  }
}
