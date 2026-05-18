import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../screens/victory_screen.dart';
import '../widgets/animated_world_background.dart';
import '../widgets/lives_hud.dart';
import '../widgets/particle_burst.dart';
import '../widgets/virtual_controls.dart';

class _FallingStar {
  final int id;
  double x, y;
  double dx, dy;
  double rotation;
  double rotationSpeed;
  bool caught = false;

  _FallingStar({
    required this.id, required this.x, required this.y,
    required this.dx, required this.dy,
    required this.rotation, required this.rotationSpeed,
  });
}

class StarCatcherScreen extends StatefulWidget {
  const StarCatcherScreen({super.key});

  @override
  State<StarCatcherScreen> createState() => _StarCatcherScreenState();
}

class _StarCatcherScreenState extends State<StarCatcherScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final List<_FallingStar> _stars = [];
  int _caught = 0;
  static const int _target = 10;
  static const int _totalSpawned = 13;
  int _spawned = 0;
  double _basketX = 0.5; // 0..1 normalized
  final Random _rng = Random();
  Timer? _spawnTimer;
  DateTime? _lastFrame;
  int _burstCount = 0;
  bool _showBurst = false;
  Offset _burstPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    context.read<GameState>().resetForWorld();

    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _ticker.addListener(_onTick);

    _spawnTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (_spawned < _totalSpawned && mounted) _spawnStar();
    });
  }

  @override
  void dispose() {
    _ticker.removeListener(_onTick);
    _ticker.dispose();
    _spawnTimer?.cancel();
    super.dispose();
  }

  void _spawnStar() {
    if (!mounted) return;
    _spawned++;
    setState(() {
      _stars.add(_FallingStar(
        id: _spawned,
        x: 0.1 + _rng.nextDouble() * 0.8,
        y: 0.0,
        dx: (_rng.nextDouble() - 0.5) * 0.001,
        dy: 0.002 + _rng.nextDouble() * 0.001,
        rotation: _rng.nextDouble() * 2 * pi,
        rotationSpeed: (_rng.nextDouble() - 0.5) * 0.15,
      ));
    });
  }

  void _onTick() {
    if (!mounted) return;
    final now = DateTime.now();
    final dt = _lastFrame != null
        ? now.difference(_lastFrame!).inMilliseconds / 16.0
        : 1.0;
    _lastFrame = now;

    final state = context.read<GameState>();
    bool changed = false;

    final toRemove = <_FallingStar>[];
    for (final star in _stars) {
      if (star.caught) continue;
      star.x += star.dx * dt;
      star.y += star.dy * dt + 0.00015 * dt; // gravity
      star.rotation += star.rotationSpeed * dt;

      if (star.y > 1.05) {
        toRemove.add(star);
        state.loseLife();
        changed = true;
        if (state.lives <= 0) {
          Future.microtask(_onLose);
          return;
        }
      }
    }
    for (final s in toRemove) { _stars.remove(s); }
    if (changed) setState(() {});
  }

  void _onStarTap(_FallingStar star, Offset tapPosition) {
    if (star.caught) return;
    star.caught = true;
    setState(() {
      _caught++;
      _stars.remove(star);
      _burstCount++;
      _burstPosition = tapPosition;
      _showBurst = true;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showBurst = false);
    });
    if (_caught >= _target) _onWin();
  }

  void _onMoveBasket(Offset dir) {
    setState(() {
      _basketX = (_basketX + dir.dx * 0.03).clamp(0.05, 0.95);
    });
  }

  void _onWin() {
    _spawnTimer?.cancel();
    context.read<GameState>().completeWorld(WorldId.star);
    context.read<GameState>().addCoins(5);
    Navigator.pushReplacementNamed(context, '/victory',
        arguments: const VictoryArgs(didWin: true, coinsEarned: 5, worldName: 'Star Shower'));
  }

  void _onLose() {
    _spawnTimer?.cancel();
    Navigator.pushReplacementNamed(context, '/victory',
        arguments: const VictoryArgs(didWin: false, worldName: 'Star Shower'));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedWorldBackground(
        theme: BackgroundTheme.night,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(top: 12, left: 16, child: LivesHud(lives: state.lives)),
              Positioned(
                top: 12, right: 16,
                child: Text(
                  '⭐ $_caught / $_target',
                  style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Cloud emitter
              Positioned(
                top: size.height * 0.02,
                left: size.width * 0.35,
                child: const Text('☁️', style: TextStyle(fontSize: 48)),
              ),

              // Falling stars
              AnimatedBuilder(
                animation: _ticker,
                builder: (context, _) => Stack(
                  children: _stars.map((star) => Positioned(
                    left: star.x * size.width - 30,
                    top: star.y * size.height,
                    child: GestureDetector(
                      onTap: () => _onStarTap(star, Offset(star.x * size.width, star.y * size.height)),
                      child: Transform.rotate(
                        angle: star.rotation,
                        child: const Text('⭐', style: TextStyle(fontSize: 44)),
                      ),
                    ),
                  )).toList(),
                ),
              ),

              // Basket
              Positioned(
                left: _basketX * size.width - 40,
                bottom: 140,
                child: Text(
                  context.read<GameState>().selectedCharacter?.emoji ?? '🧺',
                  style: const TextStyle(fontSize: 52),
                ),
              ),

              // Virtual controls
              VirtualControls(
                onMove: _onMoveBasket,
                onRelease: () {},
                showJump: false,
              ),
              if (_showBurst)
                Positioned(
                  left: _burstPosition.dx - 40,
                  top: _burstPosition.dy - 40,
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: ParticleBurst(
                      key: ValueKey(_burstCount),
                      color: Colors.yellow,
                      particleCount: 14,
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
