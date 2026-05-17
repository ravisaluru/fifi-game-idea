import 'package:flutter/material.dart';

enum AccessoryType { none, hat, cape, shield, wand }

class Character {
  final String id;
  final String displayName;
  final String emoji;
  Color outfitColor;
  AccessoryType accessory;

  Character({
    required this.id,
    required this.displayName,
    required this.emoji,
    this.outfitColor = const Color(0xFF4CAF50),
    this.accessory = AccessoryType.none,
  });

  Character copyWith({Color? outfitColor, AccessoryType? accessory}) {
    return Character(
      id: id,
      displayName: displayName,
      emoji: emoji,
      outfitColor: outfitColor ?? this.outfitColor,
      accessory: accessory ?? this.accessory,
    );
  }
}

final List<Character> availableCharacters = [
  Character(id: 'fifi',  displayName: 'Fifi',  emoji: '👧', outfitColor: const Color(0xFFE91E63)),
  Character(id: 'leo',   displayName: 'Leo',   emoji: '👦', outfitColor: const Color(0xFF2196F3)),
  Character(id: 'zara',  displayName: 'Zara',  emoji: '🥷', outfitColor: const Color(0xFF9C27B0)),
  Character(id: 'milo',  displayName: 'Milo',  emoji: '🧭', outfitColor: const Color(0xFFFF9800)),
  Character(id: 'luna',  displayName: 'Luna',  emoji: '🧚', outfitColor: const Color(0xFF00BCD4)),
  Character(id: 'rex',   displayName: 'Rex',   emoji: '🦕', outfitColor: const Color(0xFF4CAF50)),
];

const List<Color> outfitColors = [
  Color(0xFFE91E63),
  Color(0xFF2196F3),
  Color(0xFF9C27B0),
  Color(0xFFFF9800),
  Color(0xFF4CAF50),
  Color(0xFFFF5722),
  Color(0xFF00BCD4),
  Color(0xFFFFEB3B),
];

const Map<AccessoryType, String> accessoryEmojis = {
  AccessoryType.none:   '✕',
  AccessoryType.hat:    '🎩',
  AccessoryType.cape:   '🦸',
  AccessoryType.shield: '🛡️',
  AccessoryType.wand:   '🪄',
};
