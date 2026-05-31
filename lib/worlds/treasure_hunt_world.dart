import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../widgets/animated_world_background.dart';
import '../widgets/back_to_menu_button.dart';
import '../widgets/victory_popup.dart';

class _CoverSpot {
  final int id;
  final Offset pos;
  final String coverEmoji;
  final bool hasTreasure;
  final int coins;
  bool collected = false; // treasure taken
  bool revealed = false;  // currently flipped

  _CoverSpot({
    required this.id,
    required this.pos,
    required this.coverEmoji,
    required this.hasTreasure,
    required this.coins,
  });
}

class _AiOpponent {
  final String emoji;
  final String name;
  int coins = 0;
  double discoverInterval;

  _AiOpponent(
      {required this.emoji,
      required this.name,
      required this.discoverInterval});
}

class TreasureHuntScreen extends StatefulWidget {
  const TreasureHuntScreen({super.key});

  @override
  State<TreasureHuntScreen> createState() => _TreasureHuntScreenState();
}

class _TreasureHuntScreenState extends State<TreasureHuntScreen> {
  static const int _gameDuration = 120;
  static const int _spotCount = 25;
  static const int _treasureCount = 10;

  late List<_CoverSpot> _spots;
  late List<_AiOpponent> _opponents;
  int _playerCoins = 0;
  int _playerTreasuresFound = 0;
  int _secondsLeft = _gameDuration;
  bool _gameOver = false;

  Timer? _countdownTimer;
  Timer? _aiTimer;
  final Random _rng = Random();

  static const List<String> _coverEmojis = [
    '🍃', '🪨', '🌿', '🍂', '🌱', '🪵', '🌾', '🍁',
  ];

  @override
  void initState() {
    super.initState();
    context.read<GameState>().resetForWorld();

    // Generate spots — first _treasureCount have treasure, rest don't
    final indices = List.generate(_spotCount, (i) => i)..shuffle(_rng);
    final treasureIndices = indices.take(_treasureCount).toSet();

    _spots = List.generate(
        _spotCount,
        (i) => _CoverSpot(
              id: i,
              pos: Offset(0.06 + _rng.nextDouble() * 0.88,
                  0.18 + _rng.nextDouble() * 0.65),
              coverEmoji: _coverEmojis[_rng.nextInt(_coverEmojis.length)],
              hasTreasure: treasureIndices.contains(i),
              coins: 1 + _rng.nextInt(5),
            ));

    _opponents = [
      _AiOpponent(emoji: '🤖', name: 'Robo', discoverInterval: 3.5),
      _AiOpponent(emoji: '👻', name: 'Ghost', discoverInterval: 4.0),
    ];

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _onTimeUp();
    });

    _aiTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      for (final ai in _opponents) {
        if (_rng.nextDouble() < 0.5 / ai.discoverInterval) {
          final available = _spots.where((s) => s.hasTreasure && !s.collected).toList();
          if (available.isEmpty) break;
          final spot = available[_rng.nextInt(available.length)];
          setState(() {
            spot.collected = true;
            ai.coins += spot.coins;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _aiTimer?.cancel();
    super.dispose();
  }

  void _onSpotTap(_CoverSpot spot) {
    if (spot.collected || spot.revealed || _gameOver) return;

    setState(() {
      spot.revealed = true;
    });

    if (spot.hasTreasure) {
      // Collect treasure
      setState(() {
        spot.collected = true;
        _playerCoins += spot.coins;
        _playerTreasuresFound++;
      });

      // Check if all player-findable treasures are found
      final remainingTreasures = _spots.where((s) => s.hasTreasure && !s.collected).length;
      if (remainingTreasures == 0) _onTimeUp();
    } else {
      // No treasure — re-hide after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => spot.revealed = false);
      });
    }
  }

  void _onTimeUp() {
    if (_gameOver) return;
    _gameOver = true;
    _countdownTimer?.cancel();
    _aiTimer?.cancel();

    final maxAiCoins = _opponents.map((a) => a.coins).reduce(max);
    final didWin = _playerCoins >= maxAiCoins;

    // Only complete world on win
    if (didWin) {
      context.read<GameState>().completeWorld(WorldId.treasure);
    }
    context.read<GameState>().addCoins(_playerCoins);

    VictoryPopup.show(context, didWin: didWin, coinsEarned: _playerCoins, worldName: 'Forest Treasure Hunt');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final timerColor = _secondsLeft <= 20 ? Colors.red : Colors.white;

    return Scaffold(
      body: AnimatedWorldBackground(
        theme: BackgroundTheme.forest,
        child: SafeArea(
          child: Stack(
            children: [
              // Timer
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      color: timerColor,
                      fontSize: _secondsLeft <= 20 ? 26 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                    child: Text('⏱ $_secondsLeft s'),
                  ),
                ),
              ),

              const BackToMenuButton(),

              // Scoreboard
              Positioned(
                top: 40,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ScoreChip(
                      emoji:
                          context.read<GameState>().selectedCharacter?.emoji ??
                              '🧒',
                      name: 'You',
                      coins: _playerCoins,
                      highlight: true,
                    ),
                    ..._opponents.map((a) => _ScoreChip(
                          emoji: a.emoji,
                          name: a.name,
                          coins: a.coins,
                        )),
                  ],
                ),
              ),

              // Treasures found counter
              Positioned(
                top: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '🪙 Treasures: $_playerTreasuresFound / $_treasureCount',
                      style: const TextStyle(
                        color: Colors.yellow,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // Cover spots
              ..._spots.map((spot) {
                // Collected spots show coin permanently
                if (spot.collected) {
                  return Positioned(
                    left: spot.pos.dx * size.width - 18,
                    top: spot.pos.dy * size.height - 18,
                    child: const Text('🪙', style: TextStyle(fontSize: 28)),
                  );
                }
                // Revealed but no treasure — show ❌
                if (spot.revealed && !spot.hasTreasure) {
                  return Positioned(
                    left: spot.pos.dx * size.width - 18,
                    top: spot.pos.dy * size.height - 18,
                    child: const Text('❌', style: TextStyle(fontSize: 28)),
                  );
                }
                // Hidden — show cover emoji
                return Positioned(
                  left: spot.pos.dx * size.width - 24,
                  top: spot.pos.dy * size.height - 24,
                  child: GestureDetector(
                    onTap: () => _onSpotTap(spot),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        spot.coverEmoji,
                        style: const TextStyle(fontSize: 36),
                      ),
                    ),
                  ),
                );
              }),

              // Hint
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Tap leaves & rocks to find hidden treasure! 🎁',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String emoji, name;
  final int coins;
  final bool highlight;

  const _ScoreChip({
    required this.emoji,
    required this.name,
    required this.coins,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.yellow.withValues(alpha: 0.25)
            : Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: highlight
            ? Border.all(
                color: Colors.yellow.withValues(alpha: 0.6), width: 1.5)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 4),
          Text(
            '$coins🪙',
            style: TextStyle(
              color: highlight ? Colors.yellow : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
