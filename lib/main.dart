import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'package:bible/models/verse.dart';
import 'package:bible/models/schedule.dart';
import 'package:bible/view_schedules.dart';
import 'package:bible/services/home_widget_service.dart';

import 'dart:async';
import 'package:home_widget/home_widget.dart';
import 'package:app_links/app_links.dart';
import 'package:bible/reading.dart';
import 'package:bible/bible_data/bible_data.dart';

import 'firebase_options.dart';

late Isar isar;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final dir = await getApplicationDocumentsDirectory();
  isar = await Isar.open([ScheduleSchema, VerseSchema], directory: dir.path);
  await HomeWidgetService.initialize();
  await HomeWidgetService.registerBackgroundCallback();
  runApp(const MyApp());
}

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with RouteAware {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  String? _currentRouteName;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // We can't subscribe here because the navigator is inside MaterialApp which is a child of this widget.
    // So we'll rely on the navigator observer to track the top route.
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Check initial link
    final appLink = await _appLinks.getInitialLink();
    if (appLink != null) {
      _handleWidgetLaunch(appLink);
    }

    // Handle link when app is in background or foreground
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleWidgetLaunch(uri);
    });
  }

  void _handleWidgetLaunch(Uri? uri) async {
    if (uri == null || uri.scheme != 'bible' || uri.host != 'reading') {
      return;
    }
    final scheduleIdStr = uri.queryParameters['scheduleId'];
    final dateStr = uri.queryParameters['date'];
    if (scheduleIdStr == null || dateStr == null) {
      return;
    }
    final scheduleId = int.tryParse(scheduleIdStr);
    if (scheduleId == null) {
      return;
    }
    final schedule = await isar.schedules.get(scheduleId);
    if (schedule == null) {
      return;
    }
    final date = DateTime.tryParse(dateStr);
    if (date == null) {
      return;
    }
    final routeName = ReadingPage.routeName(schedule, date);
    print('widget routeName: $routeName');

    // Check if we are already on this page
    bool isAlreadyOnPage = false;
    navigatorKey.currentState?.popUntil((route) {
      if (route.settings.name == routeName) {
        isAlreadyOnPage = true;
      }
      return true; // Stop immediately, we just want to check top
    });

    if (isAlreadyOnPage) {
      print('Already on route: $routeName');
      return;
    }

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        settings: RouteSettings(name: routeName),
        builder:
            (context) => ReadingPage(
              schedule: schedule,
                      bible: BibleData(),
                      initialDate: date)));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [
        routeObserver,
        _RouteTracker((routeName) {
          _currentRouteName = routeName;
        }),
      ],
      title: 'Bible Reading App',

      themeMode: ThemeMode.system,

      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
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

class _RouteTracker extends NavigatorObserver {
  final ValueChanged<String?> onRouteChanged;

  _RouteTracker(this.onRouteChanged);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRouteChanged(route.settings.name);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRouteChanged(previousRoute?.settings.name);
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    onRouteChanged(newRoute?.settings.name);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
