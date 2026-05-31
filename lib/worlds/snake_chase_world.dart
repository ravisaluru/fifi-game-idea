import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../widgets/animated_world_background.dart';
import '../widgets/lives_hud.dart';
import '../widgets/virtual_controls.dart';
import '../widgets/multiplayer_scoreboard.dart';
import '../widgets/back_to_menu_button.dart';
import '../widgets/victory_popup.dart';

class _Obstacle {
  final Offset pos;
  final double radius;
  final String emoji;

  const _Obstacle({required this.pos, required this.radius, required this.emoji});
}

class SnakeChaseScreen extends StatefulWidget {
  const SnakeChaseScreen({super.key});

  @override
  State<SnakeChaseScreen> createState() => _SnakeChaseScreenState();
}

class _SnakeChaseScreenState extends State<SnakeChaseScreen>
    with SingleTickerProviderStateMixin {
  static const int _surviveSeconds = 60;
  static const double _catchRadius = 0.08;
  static const double _obstacleRadius = 0.04;
  static const List<String> _obstacleEmojis = ['🪨', '🌳', '🌿', '🪵'];

  late AnimationController _ticker;
  Offset _playerPos = const Offset(0.5, 0.5);
  Offset _snakePos = const Offset(0.1, 0.1);
  Offset _moveDir = Offset.zero;
  int _secondsLeft = _surviveSeconds;
  bool _stunnedAfterCatch = false;
  DateTime? _lastFrame;
  Timer? _countdownTimer;
  final Random _rng = Random();
  late List<_Obstacle> _obstacles;

  double get _snakeSpeed {
    final elapsed = _surviveSeconds - _secondsLeft;
    if (elapsed < 15) return 0.0018;
    if (elapsed < 30) return 0.0023;
    if (elapsed < 45) return 0.0028;
    return 0.0034;
  }

  @override
  void initState() {
    super.initState();
    context.read<GameState>().resetForWorld();

    _snakePos = Offset(_rng.nextDouble() * 0.3, _rng.nextDouble() * 0.3);
    _obstacles = _generateObstacles();

    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _ticker.addListener(_onTick);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsLeft--;
        // Randomize obstacles every 15 seconds
        if (_secondsLeft % 15 == 0 && _secondsLeft > 0 && _secondsLeft < _surviveSeconds) {
          _obstacles = _generateObstacles();
        }
      });
      if (_secondsLeft <= 0) _onWin();
    });
  }

  List<_Obstacle> _generateObstacles() {
    final obstacles = <_Obstacle>[];
    int attempts = 0;
    final count = 8 + _rng.nextInt(5); // 8-12 obstacles

    while (obstacles.length < count && attempts < 500) {
      attempts++;
      final pos = Offset(
        0.08 + _rng.nextDouble() * 0.84,
        0.12 + _rng.nextDouble() * 0.76,
      );

      // Must not be too close to player start
      if ((pos - _playerPos).distance < 0.15) continue;
      // Must not be too close to snake start
      if ((pos - _snakePos).distance < 0.15) continue;
      // Must not be too close to other obstacles
      if (obstacles.any((o) => (o.pos - pos).distance < 0.10)) continue;

      obstacles.add(_Obstacle(
        pos: pos,
        radius: _obstacleRadius,
        emoji: _obstacleEmojis[_rng.nextInt(_obstacleEmojis.length)],
      ));
    }
    return obstacles;
  }

  bool _collidesWithObstacle(Offset pos) {
    for (final obs in _obstacles) {
      if ((obs.pos - pos).distance < obs.radius + 0.03) return true;
    }
    return false;
  }

  @override
  void dispose() {
    _ticker.removeListener(_onTick);
    _ticker.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _onTick() {
    if (!mounted || _stunnedAfterCatch) return;

    final now = DateTime.now();
    final dt = _lastFrame != null
        ? now.difference(_lastFrame!).inMilliseconds / 16.0
        : 1.0;
    _lastFrame = now;

    // Move player (with obstacle collision)
    if (_moveDir != Offset.zero) {
      final speed = 0.006 * dt;
      final newPos = Offset(
        (_playerPos.dx + _moveDir.dx * speed).clamp(0.02, 0.98),
        (_playerPos.dy + _moveDir.dy * speed).clamp(0.08, 0.92),
      );
      if (!_collidesWithObstacle(newPos)) {
        _playerPos = newPos;
      } else {
        // Try sliding along X only
        final slideX = Offset(newPos.dx, _playerPos.dy);
        if (!_collidesWithObstacle(slideX)) {
          _playerPos = slideX;
        } else {
          // Try sliding along Y only
          final slideY = Offset(_playerPos.dx, newPos.dy);
          if (!_collidesWithObstacle(slideY)) {
            _playerPos = slideY;
          }
          // If both blocked, don't move
        }
      }
    }

    // Move snake toward player (with obstacle avoidance)
    final toPlayer = _playerPos - _snakePos;
    final dist = toPlayer.distance;
    if (dist > 0.001) {
      final dir = toPlayer / dist;
      var newSnakePos = _snakePos + dir * _snakeSpeed * dt;

      // Snake is a ghost, passes through obstacles!
      _snakePos = newSnakePos;
    }

    // Check catch
    final catchDist = (_playerPos - _snakePos).distance;
    if (catchDist < _catchRadius) {
      _onCaught();
    }
  }

  void _onCaught() async {
    if (_stunnedAfterCatch) return;
    _stunnedAfterCatch = true;

    final state = context.read<GameState>();
    state.loseLife();

    if (state.lives <= 0) {
      _onLose();
      return;
    }

    // Reset snake to a far corner
    final corners = [
      const Offset(0.05, 0.05),
      const Offset(0.95, 0.05),
      const Offset(0.05, 0.95),
      const Offset(0.95, 0.95),
    ];
    corners.sort((a, b) =>
        (b - _playerPos).distance.compareTo((a - _playerPos).distance));
    setState(() {
      _snakePos = corners.first;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (mounted) setState(() => _stunnedAfterCatch = false);
  }

  void _onWin() {
    _countdownTimer?.cancel();
    context.read<GameState>().completeWorld(WorldId.snake);
    context.read<GameState>().addCoins(8);
    VictoryPopup.show(context, didWin: true, coinsEarned: 8, worldName: 'Snake Grassland');
  }

  void _onLose() {
    _countdownTimer?.cancel();
    VictoryPopup.show(context, didWin: false, worldName: 'Snake Grassland');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final size = MediaQuery.of(context).size;

    final timerColor = _secondsLeft <= 10 ? Colors.red : Colors.white;

    return Scaffold(
      body: AnimatedWorldBackground(
        theme: BackgroundTheme.grassland,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                  top: 12, left: 16, child: LivesHud(lives: state.lives)),

              // Timer
              Positioned(
                top: 12,
                right: 60,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    color: timerColor,
                    fontSize: _secondsLeft <= 10 ? 28 : 22,
                    fontWeight: FontWeight.bold,
                  ),
                  child: Text('⏱ $_secondsLeft s'),
                ),
              ),

              const BackToMenuButton(),

              // Instruction
              Positioned(
                top: 56,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    _stunnedAfterCatch
                        ? '😵 Ouch! Keep running!'
                        : 'Run from the snake! 🐍',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Obstacles
              ..._obstacles.map((obs) => Positioned(
                    left: obs.pos.dx * size.width - 22,
                    top: obs.pos.dy * size.height - 22,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(obs.emoji, style: const TextStyle(fontSize: 36)),
                    ),
                  )),

              // Snake
              AnimatedBuilder(
                animation: _ticker,
                builder: (context, _) {
                  return Positioned(
                    left: _snakePos.dx * size.width - 24,
                    top: _snakePos.dy * size.height - 24,
                    child: AnimatedOpacity(
                      opacity: _stunnedAfterCatch ? 0.4 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: const Text('🐍', style: TextStyle(fontSize: 44)),
                    ),
                  );
                },
              ),

              // Player
              AnimatedBuilder(
                animation: _ticker,
                builder: (context, _) => Positioned(
                  left: _playerPos.dx * size.width - 24,
                  top: _playerPos.dy * size.height - 24,
                  child: Text(
                    _stunnedAfterCatch
                        ? '😵'
                        : (context.read<GameState>().selectedCharacter?.emoji ??
                            '🏃'),
                    style: const TextStyle(fontSize: 44),
                  ),
                ),
              ),

              // Multiplayer scoreboard
              if (state.isMultiplayer)
                MultiplayerScoreboard(
                  session: state.multiplayerSession!,
                  worldId: WorldId.snake,
                ),

              // Virtual controls
              VirtualControls(
                onMove: (dir) => _moveDir = dir,
                onRelease: () => _moveDir = Offset.zero,
                showJump: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


