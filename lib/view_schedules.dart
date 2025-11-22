import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:bible/main.dart';
import 'package:bible/create_schedule.dart';
import 'package:bible/reading.dart';
import 'package:bible/bible_data/bible_data.dart';
import 'package:bible/bottom_action_bar.dart';
import 'models/schedule.dart';
import 'package:bible/services/pocketbase_service.dart';
import 'package:bible/services/auth_manager.dart';
import 'package:bible/services/home_widget_service.dart';

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
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

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

    // Update widget with current verse after loading schedules
    if (Platform.isAndroid) {
      HomeWidgetService.updateCurrentVerse();
    }
  }

  void _deleteSchedule(int index, Schedule schedule) async {
    final removedItem = _schedules.removeAt(index);
    _listKey.currentState!.removeItem(
      index,
      (context, animation) => SlideTransition(
        position: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(1.0, 0.0),
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
        child: FadeTransition(
          opacity: animation,
          child: _buildScheduleTile(
            removedItem,
            DateFormat('MM/dd'),
            index,
            _bibleData,
            Theme.of(context).colorScheme,
            Theme.of(context).textTheme,
          ),
        ),
      ),
      duration: const Duration(milliseconds: 300),
    );

    final user = AuthManager().currentUser;
    if (user != null) {
      await PocketbaseService().deleteParticipantAndMaybeSchedule(
        scheduleUuid: schedule.uuid,
        firebaseUserId: user.uid,
      );
    }
    await isar.writeTxn(() async {
      await isar.schedules.delete(schedule.id);
    });

    if (_schedules.isEmpty) {
      setState(() {});
    }
  }

  Future<void> _shareSchedule(Schedule s) async {
    final user = AuthManager().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to share a schedule.')),
      );
      return;
    }
    final firebaseUserRecord = await PocketbaseService().syncFirebaseUser(user);

    try {
      RecordModel record;
      try {
        // Try to find an existing schedule in PocketBase.
        record = await PocketbaseService().pb
            .collection('schedules')
            .getFirstListItem('uuid = "${s.uuid}"');
        print('Found existing schedule');
      } on ClientException catch (e) {
        // If not found, create it.
        print('Creating new schedule in PocketBase: $e');
        record = await PocketbaseService().createSchedule(
          uuid: s.uuid,
          name: s.name,
          startDate: s.startDate,
          endDate: s.endDate,
          booksToRead: s.booksToRead,
        );
        // Add the participant relationship (owner) on creation.
        await PocketbaseService().addParticipant(
          scheduleId: record.id,
          firebaseUserId: firebaseUserRecord.id,
        );
      }

      final token = record.data['share_token'] as String;
      final message =
          'Join my Bible reading plan "${s.name}"!\n\nUse this code to join: $token\n\nOr open: https://biblereading.duckdns.org/share/$token';
      late RenderBox? box;
      if (mounted) {
        box = context.findRenderObject() as RenderBox?;
      } else {
        box = null;
      }
      final origin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;

      await SharePlus.instance.share(
        ShareParams(
          text: message,
          subject: 'Bible Reading Plan Invite',
          sharePositionOrigin: origin,
        ),
      );
    } catch (e) {
      print('Error sharing schedule: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to share schedule: $e')));
      }
    }
    setState(() => {});
  }

  Future<void> _joinSharedSchedule(String token, BuildContext context) async {
    final user = AuthManager().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to join a shared schedule.'),
        ),
      );
      return;
    }
    try {
      final pocketbase = PocketbaseService();

      // 1️⃣ Fetch the schedule by token.
      final record = await pocketbase.pb
          .collection('schedules')
          .getFirstListItem('share_token = "$token"');

      final schedule = Schedule.fromPocketBaseRecord(record, _bibleData);

      // 2️⃣ Save schedule locally first
      await isar.writeTxn(() async {
        await isar.schedules.put(schedule);
      });

      // 3️⃣ Add participant record
      final firebaseUserRecord = await PocketbaseService().syncFirebaseUser(
        user,
      );
      await pocketbase.addParticipant(
        scheduleId: record.id,
        firebaseUserId: firebaseUserRecord.id,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Joined "${schedule.name}"')));
        _loadSchedules();
      }
    } catch (e) {
      print('Error joining shared schedule: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to join schedule')),
        );
      }
    }
  }

  Widget _buildParticipantAvatar(RecordModel participant, {double size = 24}) {
    final user = participant
        .get<List<RecordModel>>('expand.firebase_user')
        .first;
    print('_buildParticipantAvatar ${user.data['avatar']}');
    final avatarUrl = user.data['avatar'] as String?;
    final displayName = user.data['displayName'] as String?;

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(avatarUrl),
      );
    }

    // fallback: initials
    final initials = (displayName?.isNotEmpty ?? false)
        ? displayName!.trim().split(' ').map((w) => w[0]).take(2).join()
        : '?';

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.grey.shade300,
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          fontSize: size / 2.2,
          color: Colors.grey.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showJoinScheduleDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join shared schedule'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Enter sharing token'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final token = controller.text.trim();
              Navigator.pop(ctx);
              if (token.isNotEmpty) {
                await _joinSharedSchedule(token, context);
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
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
                    : AnimatedList(
                        key: _listKey,
                        initialItemCount: _schedules.length,
                        itemBuilder: (context, index, animation) {
                          final schedule = _schedules[index];
                          return SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(0, 0.1),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOut,
                                  ),
                                ),
                            child: FadeTransition(
                              opacity: animation,
                              child: _buildScheduleTile(
                                schedule,
                                dateFormat,
                                index,
                                _bibleData,
                                colorScheme,
                                textTheme,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final action = await showModalBottomSheet<String>(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            builder: (_) => SafeArea(
              child: Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.add_box),
                    title: const Text('Create new schedule'),
                    onTap: () => Navigator.pop(context, 'create'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.link),
                    title: const Text('Join shared schedule'),
                    onTap: () => Navigator.pop(context, 'join'),
                  ),
                ],
              ),
            ),
          );

          if (action == 'create' && context.mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateSchedulePage()),
            );
            _loadSchedules();
          } else if (action == 'join' && context.mounted) {
            _showJoinScheduleDialog(context);
          }
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomActionBar(),
    );
  }

  Widget _buildParticipantsAndDoneDot(
    Schedule s,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Positioned(
      top: 0,
      right: 0,
      child: FutureBuilder<List<RecordModel>>(
        future: PocketbaseService().getScheduleParticipants(s.uuid),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SizedBox.shrink();
          }
          final participants = snapshot.data!;
          const maxAvatars = 5;
          final displayCount = participants.length > maxAvatars
              ? maxAvatars
              : participants.length;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < displayCount; i++)
                Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                  child: _buildParticipantAvatar(participants[i], size: 24),
                ),
              if (participants.length > maxAvatars)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    child: Text(
                      '+${participants.length - maxAvatars}',
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
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
    return Material(
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
          final action = await showModalBottomSheet<String>(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            context: context,
            builder: (context) => SafeArea(
              child: Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.share),
                    title: const Text('Share schedule'),
                    onTap: () => Navigator.pop(context, 'share'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('Delete schedule'),
                    onTap: () async {
                      Navigator.pop(context);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Delete schedule"),
                          content: Text(
                            "Are you sure you want to delete '${s.name}'?",
                            style: textTheme.bodyMedium,
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
                      );
                      if (confirm == true) {
                        final idx = _schedules.indexOf(s);
                        _deleteSchedule(idx, s);
                      }
                    },
                  ),
                ],
              ),
            ),
          );

          if (action == 'share') _shareSchedule(s);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: "schedule-title-${s.id}",
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
              _buildParticipantsAndDoneDot(s, colorScheme, textTheme),
            ],
          ),
        ),
      ),
    );
  }
}
