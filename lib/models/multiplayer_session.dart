import 'dart:math';
import 'character.dart';
import 'game_state.dart';

enum AiDifficulty { easy, medium, hard }
enum SessionType { localAi, online }
enum PlayerStatus { waiting, ready, playing, finished }

class SessionPlayer {
  final String id;
  final String name;
  final Character? character;
  final bool isLocal;
  final bool isAi;
  final AiDifficulty aiDifficulty;
  int score;
  double progress; // 0.0–1.0 for worlds that have a finish line
  PlayerStatus status;

  SessionPlayer({
    required this.id,
    required this.name,
    this.character,
    this.isLocal = false,
    this.isAi = false,
    this.aiDifficulty = AiDifficulty.medium,
    this.score = 0,
    this.progress = 0.0,
    this.status = PlayerStatus.waiting,
  });

  factory SessionPlayer.fromMap(Map<dynamic, dynamic> map, String id) {
    return SessionPlayer(
      id: id,
      name: map['name'] as String? ?? 'Player',
      isLocal: false,
      isAi: map['isAi'] as bool? ?? false,
      score: (map['score'] as num?)?.toInt() ?? 0,
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      status: PlayerStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String? ?? 'waiting'),
        orElse: () => PlayerStatus.waiting,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'isAi': isAi,
    'score': score,
    'progress': progress,
    'status': status.name,
  };
}

class MultiplayerSession {
  final String roomCode;
  final SessionType type;
  final List<SessionPlayer> players;
  WorldId? worldId;
  bool gameStarted = false;

  MultiplayerSession({
    required this.roomCode,
    required this.type,
    required this.players,
    this.worldId,
  });

  SessionPlayer? get localPlayer =>
      players.where((p) => p.isLocal).firstOrNull;

  List<SessionPlayer> get sortedByScore =>
      [...players]..sort((a, b) => b.score.compareTo(a.score));

  void updateScore(String playerId, int score, {double? progress}) {
    final p = players.firstWhere((p) => p.id == playerId, orElse: () => players.first);
    p.score = score;
    if (progress != null) p.progress = progress;
  }
}

/// Simulates AI behaviour for a world. Produces realistic score/progress
/// increments that the host publishes to the session.
class AiSimulator {
  final AiDifficulty difficulty;
  final Random _rng = Random();

  AiSimulator(this.difficulty);

  /// Returns a per-second score increment for treasure hunt / scoring worlds.
  int scoreTickForWorld(WorldId world) {
    final base = switch (difficulty) {
      AiDifficulty.easy   => 0,
      AiDifficulty.medium => 1,
      AiDifficulty.hard   => 2,
    };
    // Add some randomness so AI doesn't feel robotic
    final noise = switch (difficulty) {
      AiDifficulty.easy   => _rng.nextDouble() < 0.2 ? 1 : 0,
      AiDifficulty.medium => _rng.nextDouble() < 0.4 ? 1 : 0,
      AiDifficulty.hard   => _rng.nextDouble() < 0.6 ? 1 : 0,
    };
    return base + noise;
  }

  /// Returns a per-second progress increment for race worlds (0–1 scale).
  double progressTickForWorld(WorldId world) {
    final base = switch (difficulty) {
      AiDifficulty.easy   => 0.005,
      AiDifficulty.medium => 0.012,
      AiDifficulty.hard   => 0.020,
    };
    final jitter = (_rng.nextDouble() - 0.5) * 0.005;
    return (base + jitter).clamp(0.0, 0.04);
  }

  /// Chance (0–1) that AI makes a mistake this second.
  double mistakeChance() => switch (difficulty) {
    AiDifficulty.easy   => 0.35,
    AiDifficulty.medium => 0.15,
    AiDifficulty.hard   => 0.04,
  };
}

const Map<AiDifficulty, String> difficultyLabels = {
  AiDifficulty.easy:   'Easy 🌱',
  AiDifficulty.medium: 'Medium ⚡',
  AiDifficulty.hard:   'Hard 🔥',
};

const List<Map<String, String>> aiPersonalities = [
  {'name': 'Robo',  'emoji': '🤖'},
  {'name': 'Ghost', 'emoji': '👻'},
  {'name': 'Dino',  'emoji': '🦕'},
];
