import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import '../models/game_state.dart';

// NOTE: Firebase requires google-services.json (Android) and
// GoogleService-Info.plist (iOS) from your Firebase project console.
// Add them to android/app/ and ios/Runner/ respectively.
// See: https://firebase.google.com/docs/flutter/setup

class MultiplayerService {
  static final MultiplayerService instance = MultiplayerService._();
  MultiplayerService._();

  final FirebaseDatabase _db = FirebaseDatabase.instance;
  StreamSubscription<DatabaseEvent>? _roomSub;

  static String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return String.fromCharCodes(
      List.generate(4, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
    );
  }

  DatabaseReference roomRef(String code) => _db.ref('rooms/$code');

  // ── Create a new room ─────────────────────────────────────────────────────

  Future<String> createRoom(SessionPlayer host, WorldId worldId) async {
    String code;
    // Retry until we get an unused code (extremely rare collision)
    do {
      code = _generateRoomCode();
    } while ((await roomRef(code).get()).exists);

    await roomRef(code).set({
      'hostId': host.id,
      'worldId': worldId.name,
      'status': 'lobby',
      'createdAt': ServerValue.timestamp,
      'players': {
        host.id: host.toMap(),
      },
    });

    // Auto-delete room after 10 minutes of inactivity via onDisconnect
    roomRef(code).onDisconnect().remove();

    return code;
  }

  // ── Join an existing room ─────────────────────────────────────────────────

  Future<void> joinRoom(String code, SessionPlayer player) async {
    final snap = await roomRef(code).get();
    if (!snap.exists) throw Exception('Room $code not found');
    final data = snap.value as Map<dynamic, dynamic>;
    if (data['status'] != 'lobby') throw Exception('Game already started');
    final players = (data['players'] as Map<dynamic, dynamic>?) ?? {};
    if (players.length >= 4) throw Exception('Room is full');

    await roomRef(code).child('players/${player.id}').set(player.toMap());
  }

  // ── Watch room changes ────────────────────────────────────────────────────

  Stream<Map<String, dynamic>> watchRoom(String code) {
    return roomRef(code).onValue.map((event) {
      if (!event.snapshot.exists) return <String, dynamic>{};
      return Map<String, dynamic>.from(
          event.snapshot.value as Map<dynamic, dynamic>);
    });
  }

  // ── Game actions ──────────────────────────────────────────────────────────

  Future<void> setReady(String code, String playerId) =>
      roomRef(code).child('players/$playerId/status').set('ready');

  Future<void> startGame(String code) =>
      roomRef(code).child('status').set('playing');

  Future<void> updateScore(String code, String playerId, int score,
      {double? progress}) async {
    final updates = <String, dynamic>{'players/$playerId/score': score};
    if (progress != null) updates['players/$playerId/progress'] = progress;
    await roomRef(code).update(updates);
  }

  Future<void> markFinished(String code, String playerId) =>
      roomRef(code).child('players/$playerId/status').set('finished');

  Future<void> leaveRoom(String code, String playerId) =>
      roomRef(code).child('players/$playerId').remove();

  // ── Cleanup ───────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    await _roomSub?.cancel();
  }
}

/// Builds a MultiplayerSession from a Firebase room snapshot.
MultiplayerSession sessionFromSnapshot(
  Map<String, dynamic> data,
  String roomCode,
  String localPlayerId,
) {
  final rawPlayers = (data['players'] as Map<dynamic, dynamic>?) ?? {};
  final players = rawPlayers.entries.map((e) {
    final p = SessionPlayer.fromMap(
        e.value as Map<dynamic, dynamic>, e.key as String);
    if (p.id == localPlayerId) {
      return SessionPlayer(
        id: p.id,
        name: p.name,
        isLocal: true,
        score: p.score,
        progress: p.progress,
        status: p.status,
      );
    }
    return p;
  }).toList();

  final worldName = data['worldId'] as String? ?? 'tiger';
  final worldId = WorldId.values.firstWhere(
    (w) => w.name == worldName,
    orElse: () => WorldId.tiger,
  );

  return MultiplayerSession(
    roomCode: roomCode,
    type: SessionType.online,
    players: players,
    worldId: worldId,
  );
}
