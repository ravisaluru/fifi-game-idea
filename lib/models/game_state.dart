import 'dart:math';
import 'package:flutter/foundation.dart';
import 'character.dart';

enum WorldId { tiger, firefly, bubble, stones, star, snake, treasure }

class GameState extends ChangeNotifier {
  int lives = 3;
  int totalCoins = 0;
  int worldsCompleted = 0;
  WorldId? lastWorld;
  Character? selectedCharacter;

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

  void completeWorld() {
    worldsCompleted++;
    notifyListeners();
  }

  void selectCharacter(Character character) {
    selectedCharacter = character;
    notifyListeners();
  }

  WorldId pickNextWorld() {
    final pool = WorldId.values.where((w) => w != lastWorld).toList()..shuffle(Random());
    lastWorld = pool.first;
    return pool.first;
  }
}
