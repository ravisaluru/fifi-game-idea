import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../screens/victory_screen.dart';
import '../widgets/animated_world_background.dart';
import '../widgets/virtual_controls.dart';

class _ChestSpot {
  final int id;
  final Offset pos; // normalized 0..1
  final int coins;
  final String coverEmoji;
  bool found = false;

  _ChestSpot({
    required this.id,
    required this.pos,
    required this.coins,
    required this.coverEmoji,
  });
}

class _AiOpponent {
  final String emoji;
  final String name;
  int coins = 0;
  double discoverInterval; // seconds

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

class _TreasureHuntScreenState extends State<TreasureHuntScreen>
    with SingleTickerProviderStateMixin {
  static const int _gameDuration = 120; // 2 minutes
  static const int _chestCount = 20;

  late List<_ChestSpot> _chests;
  late List<_AiOpponent> _opponents;
  int _playerCoins = 0;
  Offset _playerPos = const Offset(0.5, 0.5);
  Offset _moveDir = Offset.zero;
  int _secondsLeft = _gameDuration;
  bool _gameOver = false;

  late AnimationController _ticker;
  Timer? _countdownTimer;
  Timer? _aiTimer;
  DateTime? _lastFrame;
  final Random _rng = Random();

  static const List<String> _coverEmojis = [
    '🍃',
    '🪨',
    '🌿',
    '🍂',
    '🌱',
    '🪵',
    '🌾',
    '🍁',
  ];

  @override
  void initState() {
    super.initState();
    context.read<GameState>().resetForWorld();

    _chests = List.generate(
        _chestCount,
        (i) => _ChestSpot(
              id: i,
              pos: Offset(0.06 + _rng.nextDouble() * 0.88,
                  0.12 + _rng.nextDouble() * 0.72),
              coins: 1 + _rng.nextInt(5),
              coverEmoji: _coverEmojis[_rng.nextInt(_coverEmojis.length)],
            ));

    _opponents = [
      _AiOpponent(emoji: '🤖', name: 'Robo', discoverInterval: 3.5),
      _AiOpponent(emoji: '👻', name: 'Ghost', discoverInterval: 4.0),
    ];

    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120),
    )..repeat();
    _ticker.addListener(_onTick);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _onTimeUp();
    });

    // AI discovery timer
    _aiTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      for (final ai in _opponents) {
        // Each AI discovers a chest every ~discoverInterval seconds
        if (_rng.nextDouble() < 0.5 / ai.discoverInterval) {
          final unfound = _chests.where((c) => !c.found).toList();
          if (unfound.isEmpty) break;
          final chest = unfound[_rng.nextInt(unfound.length)];
          setState(() {
            chest.found = true;
            ai.coins += chest.coins;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _ticker.removeListener(_onTick);
    _ticker.dispose();
    _countdownTimer?.cancel();
    _aiTimer?.cancel();
    super.dispose();
  }

  void _onTick() {
    if (!mounted || _gameOver) return;

    final now = DateTime.now();
    final dt = _lastFrame != null
        ? now.difference(_lastFrame!).inMilliseconds / 16.0
        : 1.0;
    _lastFrame = now;

    if (_moveDir != Offset.zero) {
      final speed = 0.005 * dt;
      final newPos = _playerPos + _moveDir * speed;
      setState(() {
        _playerPos = Offset(
          newPos.dx.clamp(0.03, 0.97),
          newPos.dy.clamp(0.08, 0.92),
        );
      });
    }
  }

  void _onChestTap(_ChestSpot chest) {
    if (chest.found) return;
    setState(() {
      chest.found = true;
      _playerCoins += chest.coins;
    });

    // Check if all chests found
    if (_chests.every((c) => c.found)) _onTimeUp();
  }

  void _onTimeUp() {
    if (_gameOver) return;
    _gameOver = true;
    _countdownTimer?.cancel();
    _aiTimer?.cancel();

    final maxAiCoins = _opponents.map((a) => a.coins).reduce(max);
    final didWin = _playerCoins >= maxAiCoins; // tie goes to player

    context.read<GameState>().completeWorld(WorldId.treasure);
    context.read<GameState>().addCoins(_playerCoins);

    Navigator.pushReplacementNamed(context, '/victory',
        arguments: VictoryArgs(
          didWin: didWin,
          coinsEarned: _playerCoins,
          worldName: 'Forest Treasure Hunt',
        ));
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

              // Chests (hidden until found)
              ..._chests.map((chest) {
                if (chest.found) return const SizedBox.shrink();
                return Positioned(
                  left: chest.pos.dx * size.width - 24,
                  top: chest.pos.dy * size.height - 24,
                  child: GestureDetector(
                    onTap: () => _onChestTap(chest),
                    child: Text(
                      chest.coverEmoji,
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                );
              }),

              // Found chests (coin burst placeholder)
              ..._chests.where((c) => c.found).map((chest) => Positioned(
                    left: chest.pos.dx * size.width - 12,
                    top: chest.pos.dy * size.height - 12,
                    child: const Text('🪙', style: TextStyle(fontSize: 20)),
                  )),

              // Player
              AnimatedBuilder(
                animation: _ticker,
                builder: (context, _) => Positioned(
                  left: _playerPos.dx * size.width - 22,
                  top: _playerPos.dy * size.height - 22,
                  child: Text(
                    context.read<GameState>().selectedCharacter?.emoji ?? '🧒',
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),

              // Virtual controls
              VirtualControls(
                onMove: (dir) => setState(() => _moveDir = dir),
                onRelease: () => setState(() => _moveDir = Offset.zero),
                showJump: false,
                showAction: true,
                onAction: () {
                  // Try to find nearest chest
                  for (final chest in _chests) {
                    if (chest.found) continue;
                    final dx = chest.pos.dx - _playerPos.dx;
                    final dy = chest.pos.dy - _playerPos.dy;
                    if (sqrt(dx * dx + dy * dy) < 0.12) {
                      _onChestTap(chest);
                      break;
                    }
                  }
                },
              ),

              // Hint
              Positioned(
                bottom: 150,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Tap leaves & rocks to find chests! 🎁',
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
