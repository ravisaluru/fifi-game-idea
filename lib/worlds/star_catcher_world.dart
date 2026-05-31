import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../widgets/animated_world_background.dart';
import '../widgets/lives_hud.dart';
import '../widgets/particle_burst.dart';
import '../widgets/back_to_menu_button.dart';
import '../widgets/victory_popup.dart';

class _FallingStar {
  final int id;
  double x, y;
  double dx, dy;
  double rotation;
  double rotationSpeed;
  bool caught = false;

  _FallingStar({
    required this.id,
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.rotation,
    required this.rotationSpeed,
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
  int _spawned = 0;
  final Random _rng = Random();
  Timer? _spawnTimer;
  DateTime? _lastFrame;
  int _burstCount = 0;
  bool _showBurst = false;
  Offset _burstPosition = Offset.zero;
  bool _showLevelBanner = false;
  String _levelBannerText = '';

  // Level definitions
  int _level = 1;
  static const List<int> _levelTargets = [7, 7, 6]; // targets for each level
  static const List<double> _levelBaseDy = [0.001, 0.0015, 0.002];
  static const List<double> _levelGravity = [0.00008, 0.00012, 0.00018];
  static const List<int> _levelSpawnMs = [1200, 1000, 800];
  static const List<int> _levelMaxStars = [15, 18, 22];

  double get _currentGravity => _levelGravity[_level - 1];

  @override
  void initState() {
    super.initState();
    context.read<GameState>().resetForWorld();

    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _ticker.addListener(_onTick);

    _startSpawning();
  }

  void _startSpawning() {
    _spawnTimer?.cancel();
    _spawnTimer = Timer.periodic(
      Duration(milliseconds: _levelSpawnMs[_level - 1]),
      (_) {
        if (_spawned < _levelMaxStars[_level - 1] && mounted) _spawnStar();
      },
    );
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
    final baseDy = _levelBaseDy[_level - 1];
    setState(() {
      _stars.add(_FallingStar(
        id: _spawned,
        x: 0.1 + _rng.nextDouble() * 0.8,
        y: 0.0,
        dx: (_rng.nextDouble() - 0.5) * 0.001,
        dy: baseDy + _rng.nextDouble() * 0.001,
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

    final toRemove = <_FallingStar>[];
    for (final star in _stars) {
      if (star.caught) continue;
      star.x += star.dx * dt;
      star.y += star.dy * dt + _currentGravity * dt;
      star.rotation += star.rotationSpeed * dt;

      if (star.y > 1.05) {
        toRemove.add(star);
        if (!_showLevelBanner) {
          state.loseLife();
          if (state.lives <= 0) {
            Future.microtask(_onLose);
            return;
          }
        }
      }
    }
    if (toRemove.isNotEmpty) {
      for (final s in toRemove) {
        _stars.remove(s);
      }
      setState(() {});
    }
  }

  void _onStarTap(_FallingStar star, Offset tapPosition) {
    if (star.caught || _showLevelBanner) return;
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

    if (_showLevelBanner) return; // Prevent double trigger
    // Check level transition
    if (_caught >= _levelTargets[_level - 1]) {
      if (_level >= 3) {
        _onWin();
      } else {
        _advanceLevel();
      }
    }
  }

  void _advanceLevel() {
    _spawnTimer?.cancel();
    setState(() {
      _showLevelBanner = true;
      _levelBannerText = 'Level $_level Complete! ⭐';
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _level++;
        _caught = 0; // Reset caught count for the new level
        _showLevelBanner = false;
        _spawned = 0;
        _stars.clear(); // Clear old level's stars
      });
      _startSpawning();
    });
  }

  void _onWin() {
    _spawnTimer?.cancel();
    context.read<GameState>().completeWorld(WorldId.star);
    context.read<GameState>().addCoins(5);
    VictoryPopup.show(context, didWin: true, coinsEarned: 5, worldName: 'Star Shower');
  }

  void _onLose() {
    _spawnTimer?.cancel();
    VictoryPopup.show(context, didWin: false, worldName: 'Star Shower');
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
              Positioned(
                  top: 12, left: 16, child: LivesHud(lives: state.lives)),
              Positioned(
                top: 12,
                right: 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '⭐ $_caught / ${_levelTargets[_level - 1]}',
                      style: const TextStyle(
                        color: Colors.yellow,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Level $_level / 3',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const BackToMenuButton(),

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
                  children: _stars
                      .map((star) => Positioned(
                            left: star.x * size.width - 30,
                            top: star.y * size.height,
                            child: GestureDetector(
                              onTap: () => _onStarTap(
                                  star,
                                  Offset(star.x * size.width,
                                      star.y * size.height)),
                              child: Container(
                                color: Colors.transparent,
                                width: 80,
                                height: 80,
                                child: Center(
                                  child: Transform.rotate(
                                    angle: star.rotation,
                                    child: const Text('⭐',
                                        style: TextStyle(fontSize: 44)),
                                  ),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
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

              // Level transition banner
              if (_showLevelBanner)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: Center(
                        child: Text(
                          _levelBannerText,
                          style: const TextStyle(
                            color: Colors.yellow,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(blurRadius: 12, color: Colors.black54)
                            ],
                          ),
                        ),
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
