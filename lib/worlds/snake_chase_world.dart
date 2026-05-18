import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../screens/victory_screen.dart';
import '../widgets/animated_world_background.dart';
import '../widgets/lives_hud.dart';
import '../widgets/virtual_controls.dart';
import '../widgets/multiplayer_scoreboard.dart';

class SnakeChaseScreen extends StatefulWidget {
  const SnakeChaseScreen({super.key});

  @override
  State<SnakeChaseScreen> createState() => _SnakeChaseScreenState();
}

class _SnakeChaseScreenState extends State<SnakeChaseScreen>
    with SingleTickerProviderStateMixin {
  static const int _surviveSeconds = 60;
  static const double _catchRadius = 0.08; // normalized distance

  late AnimationController _ticker;
  Offset _playerPos = const Offset(0.5, 0.5);
  Offset _snakePos = const Offset(0.1, 0.1);
  Offset _moveDir = Offset.zero;
  int _secondsLeft = _surviveSeconds;
  bool _stunnedAfterCatch = false;
  DateTime? _lastFrame;
  Timer? _countdownTimer;
  final Random _rng = Random();

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

    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _ticker.addListener(_onTick);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _onWin();
    });
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

    // Move player
    if (_moveDir != Offset.zero) {
      final speed = 0.006 * dt;
      final newPos = _playerPos + _moveDir * speed;
      _playerPos = Offset(
        newPos.dx.clamp(0.02, 0.98),
        newPos.dy.clamp(0.08, 0.92),
      );
    }

    // Move snake toward player (steering AI)
    final toPlayer = _playerPos - _snakePos;
    final dist = toPlayer.distance;
    if (dist > 0.001) {
      final dir = toPlayer / dist;
      _snakePos = _snakePos + dir * _snakeSpeed * dt;
    }

    // Check catch
    if (dist < _catchRadius) {
      _onCaught();
      return;
    }

    setState(() {});
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

    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) setState(() => _stunnedAfterCatch = false);
  }

  void _onWin() {
    _countdownTimer?.cancel();
    context.read<GameState>().completeWorld(WorldId.snake);
    context.read<GameState>().addCoins(8);
    Navigator.pushReplacementNamed(context, '/victory',
        arguments: const VictoryArgs(
            didWin: true, coinsEarned: 8, worldName: 'Snake Grassland'));
  }

  void _onLose() {
    _countdownTimer?.cancel();
    Navigator.pushReplacementNamed(context, '/victory',
        arguments:
            const VictoryArgs(didWin: false, worldName: 'Snake Grassland'));
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
                right: 16,
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
                onMove: (dir) => setState(() => _moveDir = dir),
                onRelease: () => setState(() => _moveDir = Offset.zero),
                showJump: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
