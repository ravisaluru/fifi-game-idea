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

class SteppingStonesScreen extends StatefulWidget {
  const SteppingStonesScreen({super.key});

  @override
  State<SteppingStonesScreen> createState() => _SteppingStonesScreenState();
}

class _SteppingStonesScreenState extends State<SteppingStonesScreen>
    with TickerProviderStateMixin {
  static const int _maxLevel = 3;
  static const List<int> _stonesPerLevel = [6, 10, 15];

  int _level = 1;
  int get _stoneCount => _stonesPerLevel[_level - 1];

  List<Offset> _stonePositions = [];
  Size? _lastSize;
  late List<int> _sequence;
  List<AnimationController> _glowControllers = [];
  int _playerStep = 0;
  int _playerStoneIndex = -1;
  bool _isShowingSequence = false;
  bool _playerCanTap = false;
  late int _seed;
  int _burstCount = 0;
  bool _showBurst = false;
  Offset _burstPosition = Offset.zero;
  bool _showLevelBanner = false;
  String _levelBannerText = '';

  @override
  void initState() {
    super.initState();
    context.read<GameState>().resetForWorld();
    _initLevel();
  }

  void _initLevel() {
    _seed = DateTime.now().millisecondsSinceEpoch;
    _stonePositions = [];
    _lastSize = null;
    _playerStep = 0;
    _playerStoneIndex = -1;

    // Dispose old glow controllers
    for (final c in _glowControllers) {
      c.dispose();
    }

    _glowControllers = List.generate(
        _stoneCount,
        (_) => AnimationController(
            vsync: this, duration: const Duration(milliseconds: 500)));

    _sequence = List.generate(_stoneCount, (i) => i)..shuffle(Random());

    Future.delayed(const Duration(milliseconds: 600), _showSequence);
  }

  @override
  void dispose() {
    for (final c in _glowControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _buildPositions(Size size) {
    final rng = Random(_seed);
    _stonePositions = [];
    int attempts = 0;
    while (_stonePositions.length < _stoneCount && attempts < 1000) {
      attempts++;
      final x = size.width * (0.10 + rng.nextDouble() * 0.80);
      final y = size.height * (0.20 + rng.nextDouble() * 0.60);
      final candidate = Offset(x, y);
      final tooClose =
          _stonePositions.any((p) => (p - candidate).distance < 90);
      if (!tooClose) {
        _stonePositions.add(candidate);
      }
    }
  }

  Future<void> _showSequence() async {
    if (!mounted) return;
    setState(() {
      _isShowingSequence = true;
      _playerCanTap = false;
    });

    for (final idx in _sequence) {
      if (!mounted) return;
      await _glowControllers[idx].forward(from: 0);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await _glowControllers[idx].reverse();
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }

    if (!mounted) return;
    setState(() {
      _isShowingSequence = false;
      _playerCanTap = true;
    });
  }

  void _onStoneTap(int stoneIndex) {
    if (!_playerCanTap || _showLevelBanner) return;
    final state = context.read<GameState>();

    _glowControllers[stoneIndex].forward(from: 0).then((_) {
      if (mounted) {
        _glowControllers[stoneIndex].reverse();
      }
    });

    if (stoneIndex == _sequence[_playerStep]) {
      setState(() {
        _playerStoneIndex = stoneIndex;
        _playerStep++;
        _burstCount++;
        _burstPosition = _stonePositions[stoneIndex];
        _showBurst = true;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _showBurst = false);
      });
      if (_playerStep >= _stoneCount) {
        Future.delayed(const Duration(milliseconds: 500), _onLevelComplete);
      }
    } else {
      state.loseLife();
      setState(() {
        _playerStep = 0;
        _playerStoneIndex = -1;
      });
      if (state.lives <= 0) {
        Future.delayed(const Duration(milliseconds: 600), _onLose);
        return;
      }
      Future.delayed(const Duration(milliseconds: 800), _showSequence);
    }
  }

  void _onLevelComplete() {
    if (_level >= _maxLevel) {
      _onWin();
      return;
    }

    setState(() {
      _showLevelBanner = true;
      _levelBannerText = 'Level $_level Complete! 🎉';
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _level++;
        _showLevelBanner = false;
      });
      _initLevel();
      setState(() {});
    });
  }

  void _onWin() {
    context.read<GameState>().completeWorld(WorldId.stones);
    context.read<GameState>().addCoins(5);
    VictoryPopup.show(context, didWin: true, coinsEarned: 5, worldName: 'Stepping Stones');
  }

  void _onLose() {
    VictoryPopup.show(context, didWin: false, worldName: 'Stepping Stones');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final size = MediaQuery.of(context).size;
    if (_stonePositions.isEmpty || size != _lastSize) {
      _lastSize = size;
      _buildPositions(size);
    }

    return Scaffold(
      body: AnimatedWorldBackground(
        theme: BackgroundTheme.river,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                  top: 12, left: 16, child: LivesHud(lives: state.lives)),
              Positioned(
                top: 56,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'Level $_level / $_maxLevel',
                        style: const TextStyle(
                          color: Colors.yellow,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isShowingSequence
                            ? 'Remember the path...'
                            : 'Hop the right stones!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const BackToMenuButton(),
              Positioned(
                left: 8,
                top: size.height * 0.3,
                child: const Text('🏖️', style: TextStyle(fontSize: 32)),
              ),
              Positioned(
                right: 8,
                top: size.height * 0.3,
                child: const Text('🏆', style: TextStyle(fontSize: 32)),
              ),
              ..._stonePositions.asMap().entries.map((e) {
                final i = e.key;
                final pos = e.value;
                final isNext = _playerCanTap &&
                    _playerStep < _stoneCount &&
                    i == _sequence[_playerStep];
                return Positioned(
                  left: pos.dx - 35,
                  top: pos.dy - 20,
                  child: GestureDetector(
                    onTap: () => _onStoneTap(i),
                    child: AnimatedBuilder(
                      animation: _glowControllers[i],
                      builder: (context, _) {
                        final glow = _glowControllers[i].value;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 70,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Color.lerp(
                              const Color(0xFF78909C),
                              isNext
                                  ? Colors.greenAccent
                                  : const Color(0xFFFFD54F),
                              glow,
                            ),
                            boxShadow: glow > 0.1
                                ? [
                                    BoxShadow(
                                      color:
                                          (isNext ? Colors.green : Colors.amber)
                                              .withValues(alpha: glow * 0.7),
                                      blurRadius: 16 * glow,
                                    )
                                  ]
                                : [
                                    const BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 3),
                                    )
                                  ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              }),
              if (_playerStoneIndex >= 0)
                Positioned(
                  left: _stonePositions[_playerStoneIndex].dx - 20,
                  top: _stonePositions[_playerStoneIndex].dy - 55,
                  child: Text(
                    context.read<GameState>().selectedCharacter?.emoji ?? '🧒',
                    style: const TextStyle(fontSize: 36),
                  ),
                )
              else
                Positioned(
                  left: 8,
                  top: size.height * 0.24,
                  child: Text(
                    context.read<GameState>().selectedCharacter?.emoji ?? '🧒',
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              if (_showBurst && _burstPosition != Offset.zero)
                Positioned(
                  left: _burstPosition.dx - 40,
                  top: _burstPosition.dy - 60,
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: ParticleBurst(
                      key: ValueKey(_burstCount),
                      color: Colors.amber,
                      particleCount: 10,
                    ),
                  ),
                ),
              // Level transition banner
              if (_showLevelBanner)
                Positioned.fill(
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
            ],
          ),
        ),
      ),
    );
  }
}
