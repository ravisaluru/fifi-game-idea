import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../screens/victory_screen.dart';
import '../widgets/animated_world_background.dart';
import '../widgets/lives_hud.dart';

class FireflyWorldScreen extends StatefulWidget {
  const FireflyWorldScreen({super.key});

  @override
  State<FireflyWorldScreen> createState() => _FireflyWorldScreenState();
}

class _FireflyWorldScreenState extends State<FireflyWorldScreen>
    with TickerProviderStateMixin {
  static const int _totalFireflies = 5;
  static const int _winsNeeded = 3;

  int _roundsWon = 0;
  int _sequenceLength = 3;
  List<int> _sequence = [];
  List<int> _playerTaps = [];
  bool _isShowingSequence = false;
  bool _playerCanTap = false;

  late List<AnimationController> _glowControllers;
  late List<Animation<double>> _glowAnims;

  @override
  void initState() {
    super.initState();
    context.read<GameState>().resetForWorld();

    _glowControllers = List.generate(
        _totalFireflies,
        (_) => AnimationController(
            vsync: this, duration: const Duration(milliseconds: 500)));
    _glowAnims = _glowControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeInOut))
        .toList();

    Future.delayed(const Duration(milliseconds: 800), _startRound);
  }

  @override
  void dispose() {
    for (final c in _glowControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _startRound() {
    if (!mounted) return;
    if (_sequence.isEmpty) {
      _sequence = List.generate(
          _sequenceLength, (_) => Random().nextInt(_totalFireflies));
    } else {
      _sequence.add(Random().nextInt(_totalFireflies));
    }
    _playerTaps = [];
    _isShowingSequence = true;
    _playerCanTap = false;
    _playSequence(0);
  }

  void _playSequence(int step) async {
    if (!mounted || step >= _sequence.length) {
      setState(() {
        _isShowingSequence = false;
        _playerCanTap = true;
      });
      return;
    }

    await _glowControllers[_sequence[step]].forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 100));
    await _glowControllers[_sequence[step]].reverse();
    await Future.delayed(const Duration(milliseconds: 200));
    _playSequence(step + 1);
  }

  void _onFireflyTap(int index) {
    if (!_playerCanTap) return;
    final state = context.read<GameState>();

    _glowControllers[index]
        .forward(from: 0)
        .then((_) => _glowControllers[index].reverse());

    _playerTaps.add(index);
    final tapPos = _playerTaps.length - 1;

    if (_playerTaps[tapPos] != _sequence[tapPos]) {
      // Wrong tap
      state.loseLife();
      if (state.lives <= 0) {
        Future.delayed(const Duration(milliseconds: 600), _onLose);
        return;
      }
      setState(() {
        _sequence = List.generate(
            _sequenceLength, (_) => Random().nextInt(_totalFireflies));
      });
      Future.delayed(const Duration(milliseconds: 800), _startRound);
      return;
    }

    if (_playerTaps.length == _sequence.length) {
      // Round complete
      _roundsWon++;
      if (_roundsWon >= _winsNeeded) {
        _onWin();
      } else {
        _sequenceLength++;
        Future.delayed(const Duration(milliseconds: 600), _startRound);
      }
    }
  }

  void _onWin() {
    context.read<GameState>().completeWorld(WorldId.firefly);
    context.read<GameState>().addCoins(5);
    Navigator.pushReplacementNamed(
      context,
      '/victory',
      arguments: const VictoryArgs(
          didWin: true, coinsEarned: 5, worldName: 'Firefly Forest'),
    );
  }

  void _onLose() {
    Navigator.pushReplacementNamed(
      context,
      '/victory',
      arguments: const VictoryArgs(didWin: false, worldName: 'Firefly Forest'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final size = MediaQuery.of(context).size;

    // Positions in a loose arc
    final positions = List.generate(_totalFireflies, (i) {
      final angle = -pi * 0.7 + i * pi * 1.4 / (_totalFireflies - 1);
      return Offset(
        size.width * 0.5 + cos(angle) * size.width * 0.32,
        size.height * 0.42 + sin(angle) * size.height * 0.18,
      );
    });

    return Scaffold(
      body: AnimatedWorldBackground(
        theme: BackgroundTheme.night,
        child: SafeArea(
          child: Stack(
            children: [
              // HUD
              Positioned(
                top: 12,
                left: 16,
                child: LivesHud(lives: state.lives),
              ),
              Positioned(
                top: 12,
                right: 16,
                child: Text(
                  'Round ${_roundsWon + 1}/$_winsNeeded',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),

              // Instruction
              Positioned(
                top: 52,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    _isShowingSequence
                        ? 'Watch carefully...'
                        : 'Your turn! Tap them!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Fireflies
              ...List.generate(
                  _totalFireflies,
                  (i) => Positioned(
                        left: positions[i].dx - 40,
                        top: positions[i].dy - 40,
                        child: GestureDetector(
                          onTap: () => _onFireflyTap(i),
                          child: AnimatedBuilder(
                            animation: _glowAnims[i],
                            builder: (context, _) {
                              final glow = _glowAnims[i].value;
                              return Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color.lerp(
                                    Colors.transparent,
                                    const Color(0xFFCCFF90),
                                    glow,
                                  ),
                                  boxShadow: glow > 0.1
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF76FF03)
                                                .withValues(alpha: glow * 0.8),
                                            blurRadius: 24 * glow,
                                            spreadRadius: 8 * glow,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    '✨',
                                    style: TextStyle(
                                      fontSize: 28 + glow * 12,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      )),
            ],
          ),
        ),
      ),
    );
  }
}
