import 'package:firebase_auth/firebase_auth.dart';
import 'package:pocketbase/pocketbase.dart';

class PocketbaseService {
  static final PocketbaseService _instance = PocketbaseService._internal();
  factory PocketbaseService() => _instance;
  PocketbaseService._internal() {
    pb = PocketBase('https://biblereading.duckdns.org');
  }

  late final PocketBase pb;

  // ==============================================================
  // 🔹 Firebase user synchronization
  // ==============================================================

  Future<RecordModel> syncFirebaseUser(User firebaseUser) async {
    final firebaseUid = firebaseUser.uid;

    try {
      // 🔍 Try to find an existing PocketBase record
      final existing = await pb
          .collection('firebase_users')
          .getFirstListItem('firebase_uid = "$firebaseUid"');
      return existing;
    } catch (_) {
      // ❌ If not found, create one
      final data = {
        'firebase_uid': firebaseUid,
        'display_name': firebaseUser.displayName ?? '',
        'email': firebaseUser.email ?? '',
        'avatar': firebaseUser.photoURL ?? '',
      };

      final created = await pb.collection('firebase_users').create(body: data);
      return created;
    }
  }

  // ==============================================================
  // 🔹 Schedule sharing
  // ==============================================================

  Future<RecordModel> createSchedule({
    required String uuid,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> booksToRead,
  }) async {
    final shareToken = _generateShareToken();

    final body = {
      'uuid': uuid,
      'name': name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'books_to_read': booksToRead,
      'share_token': shareToken,
    };

    return await pb.collection('schedules').create(body: body);
  }

  Future<RecordModel?> getScheduleByShareToken(String token) async {
    try {
      return await pb
          .collection('schedules')
          .getFirstListItem('share_token = "$token"', expand: 'creator_uid');
    } catch (_) {
      return null;
    }
  }

  Future<RecordModel> addParticipant({
    required String scheduleId,
    required String firebaseUserId,
  }) async {
    final body = {'schedule': scheduleId, 'firebase_user': firebaseUserId};
    return await pb.collection('participants').create(body: body);
  }

  Future<List<RecordModel>> getScheduleParticipants(String scheduleUuid) async {
    try {
      final result = await pb
          .collection('participants')
          .getFullList(
            filter: 'schedule.uuid = "$scheduleUuid"',
            expand: 'firebase_user',
            sort: 'joined',
          );
      print('Fetched ${result.length} participants for schedule $scheduleUuid');
      return result;
    } catch (e) {
      print('getScheduleParticipants ClientException: $e');
      return [];
    }
  }

  Future<void> deleteParticipantAndMaybeSchedule({
    required String scheduleUuid,
    required String firebaseUserId,
  }) async {
    try {
      // 1️⃣ Find participant record for this user + schedule.
      final participant = await pb
          .collection('participants')
          .getFirstListItem(
            'schedule.uuid = "$scheduleUuid" && firebase_user.firebase_uid = "$firebaseUserId"',
          );

      // 2️⃣ Delete that participant.
      await pb.collection('participants').delete(participant.id);
      print('Deleted participant ${participant.id} for user $firebaseUserId');

      // 3️⃣ Check if any participants remain for this schedule.
      final remaining = await pb
          .collection('participants')
          .getList(filter: 'schedule.uuid = "$scheduleUuid"', perPage: 1);

      if (remaining.items.isEmpty) {
        // 4️⃣ No one left → delete the schedule itself.
        final schedule = await pb
            .collection('schedules')
            .getFirstListItem('uuid = "$scheduleUuid"');
        await pb.collection('schedules').delete(schedule.id);
        print('Deleted schedule $scheduleUuid (no participants remain).');
      }
    } on ClientException catch (e) {
      print('deleteParticipantAndMaybeSchedule PocketBase error: $e');
    } catch (e) {
      print('Unexpected error deleting participant/schedule: $e');
    }
  }

  // ==============================================================
  // 🔹 Helpers
  // ==============================================================

  String _generateShareToken() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = DateTime.now().microsecondsSinceEpoch;
    return List.generate(
      6,
      (i) => chars[(random + i * 31) % chars.length],
    ).join();
  }
}
