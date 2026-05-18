import 'dart:math';
import 'package:flutter/foundation.dart';
import 'character.dart';
import 'multiplayer_session.dart';

export 'multiplayer_session.dart';

enum WorldId { tiger, firefly, bubble, stones, star, snake, treasure }

class GameState extends ChangeNotifier {
  int lives = 3;
  int totalCoins = 0;
  int worldsCompleted = 0;
  final Set<WorldId> completedWorlds = {};
  WorldId? lastWorld;
  Character? selectedCharacter;
  MultiplayerSession? multiplayerSession;

  bool get isMultiplayer => multiplayerSession != null;

  void resetForWorld() {
    lives = 3;
    notifyListeners();
  }

  void loseLife() {
    if (lives > 0) lives--;
    notifyListeners();
  }

  void addCoins(int amount) {
    totalCoins += amount;
    notifyListeners();
  }

  void completeWorld(WorldId id) {
    completedWorlds.add(id);
    worldsCompleted = completedWorlds.length;
    notifyListeners();
  }

  void selectCharacter(Character character) {
    selectedCharacter = character;
    notifyListeners();
  }

  void setMultiplayerSession(MultiplayerSession? session) {
    multiplayerSession = session;
    notifyListeners();
  }

  void clearMultiplayerSession() {
    multiplayerSession = null;
    notifyListeners();
  }

  WorldId pickNextWorld() {
    final pool = WorldId.values.where((w) => w != lastWorld).toList()..shuffle(Random());
    lastWorld = pool.first;
    return pool.first;
  }
}
