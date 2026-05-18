import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../screens/victory_screen.dart';
import '../widgets/animated_world_background.dart';
import '../widgets/lives_hud.dart';

class SteppingStonesScreen extends StatefulWidget {
  const SteppingStonesScreen({super.key});

  @override
  State<SteppingStonesScreen> createState() => _SteppingStonesScreenState();
}

class _SteppingStonesScreenState extends State<SteppingStonesScreen>
    with TickerProviderStateMixin {
  static const int _stoneCount = 6;

  late List<Offset> _stonePositions;
  late List<int> _sequence;
  late List<AnimationController> _glowControllers;
  int _playerStep = 0;
  int _playerStoneIndex = -1; // which stone Fifi is on
  bool _isShowingSequence = false;
  bool _playerCanTap = false;

  @override
  void initState() {
    super.initState();
    context.read<GameState>().resetForWorld();

    _glowControllers = List.generate(_stoneCount, (_) =>
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500)));

    _sequence = List.generate(_stoneCount, (i) => i); // in order
    _sequence.shuffle(Random());

    Future.delayed(const Duration(milliseconds: 600), _showSequence);
  }

  @override
  void dispose() {
    for (final c in _glowControllers) c.dispose();
    super.dispose();
  }

  void _buildPositions(Size size) {
    final rng = Random(42);
    _stonePositions = [];
    for (int i = 0; i < _stoneCount; i++) {
      final x = size.width * (0.12 + i * 0.14 + rng.nextDouble() * 0.04);
      final y = size.height * (0.38 + (i % 2 == 0 ? -0.06 : 0.06) + rng.nextDouble() * 0.04);
      _stonePositions.add(Offset(x, y));
    }
  }

  Future<void> _showSequence() async {
    if (!mounted) return;
    setState(() { _isShowingSequence = true; _playerCanTap = false; });

    for (final idx in _sequence) {
      if (!mounted) return;
      await _glowControllers[idx].forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 150));
      await _glowControllers[idx].reverse();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (!mounted) return;
    setState(() { _isShowingSequence = false; _playerCanTap = true; });
  }

  void _onStoneTap(int stoneIndex) {
    if (!_playerCanTap) return;
    final state = context.read<GameState>();

    _glowControllers[stoneIndex].forward(from: 0).then((_) {
      if (mounted) _glowControllers[stoneIndex].reverse();
    });

    if (stoneIndex == _sequence[_playerStep]) {
      setState(() {
        _playerStoneIndex = stoneIndex;
        _playerStep++;
      });
      if (_playerStep >= _stoneCount) {
        Future.delayed(const Duration(milliseconds: 500), _onWin);
      }
    } else {
      // Wrong stone
      state.loseLife();
      setState(() { _playerStep = 0; _playerStoneIndex = -1; });
      if (state.lives <= 0) {
        Future.delayed(const Duration(milliseconds: 600), _onLose);
        return;
      }
      Future.delayed(const Duration(milliseconds: 800), _showSequence);
    }
  }

  void _onWin() {
    context.read<GameState>().completeWorld(WorldId.stones);
    context.read<GameState>().addCoins(5);
    Navigator.pushReplacementNamed(context, '/victory',
        arguments: const VictoryArgs(didWin: true, coinsEarned: 5, worldName: 'Stepping Stones'));
  }

  void _onLose() {
    Navigator.pushReplacementNamed(context, '/victory',
        arguments: const VictoryArgs(didWin: false, worldName: 'Stepping Stones'));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final size = MediaQuery.of(context).size;
    _buildPositions(size);

    return Scaffold(
      body: AnimatedWorldBackground(
        theme: BackgroundTheme.river,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(top: 12, left: 16, child: LivesHud(lives: state.lives)),
              Positioned(
                top: 56, left: 0, right: 0,
                child: Center(
                  child: Text(
                    _isShowingSequence ? 'Remember the path...' : 'Hop the right stones!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Start bank label
              Positioned(
                left: 8, top: size.height * 0.3,
                child: const Text('🏖️', style: TextStyle(fontSize: 32)),
              ),
              // Goal bank label
              Positioned(
                right: 8, top: size.height * 0.3,
                child: const Text('🏆', style: TextStyle(fontSize: 32)),
              ),

              // Stones
              ..._stonePositions.asMap().entries.map((e) {
                final i = e.key;
                final pos = e.value;
                final isNext = _playerCanTap && _playerStep < _stoneCount &&
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
                              isNext ? Colors.greenAccent : const Color(0xFFFFD54F),
                              glow,
                            ),
                            boxShadow: glow > 0.1
                                ? [BoxShadow(
                                    color: (isNext ? Colors.green : Colors.amber)
                                        .withValues(alpha: glow * 0.7),
                                    blurRadius: 16 * glow,
                                  )]
                                : [const BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 3),
                                  )],
                          ),
                        );
                      },
                    ),
                  ),
                );
              }),

              // Player (Fifi) on stone
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
            ],
          ),
        ),
      ),
    );
  }
}
