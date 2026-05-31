import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../widgets/animated_world_background.dart';
import '../widgets/lives_hud.dart';
import '../widgets/particle_burst.dart';
import '../widgets/back_to_menu_button.dart';
import '../widgets/victory_popup.dart';

enum _BubbleColor { red, yellow, blue, green, purple, orange, cyan }

class _Bubble {
  final int id;
  final _BubbleColor color;
  double x;
  bool isPopped = false;
  bool isSelected = false;
  late AnimationController controller;

  _Bubble({required this.id, required this.color, required this.x});
}

const Map<_BubbleColor, Color> _colorMap = {
  _BubbleColor.red: Color(0xFFEF5350),
  _BubbleColor.yellow: Color(0xFFFFEE58),
  _BubbleColor.blue: Color(0xFF42A5F5),
  _BubbleColor.green: Color(0xFF66BB6A),
  _BubbleColor.purple: Color(0xFFAB47BC),
  _BubbleColor.orange: Color(0xFFFF7043),
  _BubbleColor.cyan: Color(0xFF26C6DA),
};

class BubbleWorldScreen extends StatefulWidget {
  const BubbleWorldScreen({super.key});

  @override
  State<BubbleWorldScreen> createState() => _BubbleWorldScreenState();
}

class _BubbleWorldScreenState extends State<BubbleWorldScreen>
    with TickerProviderStateMixin {
  static const int _maxLevel = 5;
  // Pairs double per level: 2, 4, 8, 16, 32
  static const List<int> _pairsPerLevel = [2, 4, 8, 16, 32];
  // Base duration per level (ms) — 20% slower than original at level 1,
  // getting faster each level
  static const List<int> _baseDurationPerLevel = [9600, 8400, 7200, 6000, 4800];

  int _level = 1;
  List<_Bubble> _bubbles = [];
  _Bubble? _selected;
  int _poppedPairs = 0;
  int _burstCount = 0;
  bool _showBurst = false;
  Color _burstColor = Colors.yellow;
  bool _showLevelBanner = false;
  String _levelBannerText = '';

  int get _currentPairs => _pairsPerLevel[_level - 1];
  int get _currentBaseDuration => _baseDurationPerLevel[_level - 1];

  @override
  void initState() {
    super.initState();
    context.read<GameState>().resetForWorld();
    _initBubbles();
  }

  void _initBubbles() {
    // Dispose old controllers if any
    // Double-dispose was causing Level 2 to crash. Just clear the list!
    // Disposing happens in `_onLevelComplete`.

    final rng = Random();
    final pairs = <_BubbleColor>[];
    for (int i = 0; i < _currentPairs; i++) {
      final c = _BubbleColor.values[rng.nextInt(_BubbleColor.values.length)];
      pairs.add(c);
      pairs.add(c);
    }
    pairs.shuffle(rng);

    _bubbles = List.generate(pairs.length, (i) {
      final b = _Bubble(
        id: i,
        color: pairs[i],
        x: 0.08 + rng.nextDouble() * 0.82,
      );
      final duration = Duration(
          milliseconds: _currentBaseDuration + rng.nextInt(3000));
      final delay = rng.nextInt(2000);
      b.controller = AnimationController(vsync: this, duration: duration);
      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted) b.controller.forward();
      });
      b.controller.addStatusListener((status) {
        if (!mounted) return;
        if (status == AnimationStatus.completed && !b.isPopped) {
          context.read<GameState>().loseLife();
          if (context.read<GameState>().lives <= 0) _onLose();
          setState(() => b.isPopped = true);
        }
      });
      return b;
    });

    _selected = null;
    _poppedPairs = 0;
  }

  @override
  void dispose() {
    for (final b in _bubbles) {
      b.controller.dispose();
    }
    super.dispose();
  }

  void _onBubbleTap(_Bubble tapped) {
    if (tapped.isPopped || _showLevelBanner) return;
    final state = context.read<GameState>();

    if (_selected == null) {
      setState(() {
        _selected = tapped;
        tapped.isSelected = true;
      });
    } else if (_selected == tapped) {
      setState(() {
        tapped.isSelected = false;
        _selected = null;
      });
    } else if (_selected!.color == tapped.color) {
      // Match found — stop controllers for popped bubbles
      _selected!.controller.stop();
      tapped.controller.stop();
      setState(() {
        _selected!.isPopped = true;
        tapped.isPopped = true;
        _selected = null;
        _poppedPairs++;
        _burstCount++;
        _burstColor = _colorMap[tapped.color]!;
        _showBurst = true;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _showBurst = false);
      });
      if (_poppedPairs >= _currentPairs) {
        _onLevelComplete();
      }
    } else {
      setState(() {
        _selected!.isSelected = false;
        _selected = null;
      });
      state.loseLife();
      if (state.lives <= 0) _onLose();
    }
  }

  void _onLevelComplete() {
    if (_level >= _maxLevel) {
      _onWin();
      return;
    }

    // Show level banner then advance
    setState(() {
      _showLevelBanner = true;
      _levelBannerText = 'Level $_level Complete! 🎉';
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      
      // Store reference to old bubbles to dispose them after rebuild
      final oldBubbles = List<_Bubble>.from(_bubbles);
      
      setState(() {
        _level++;
        _showLevelBanner = false;
        _initBubbles();
      });
      
      // Safely dispose old controllers now that they are no longer in the active widget tree
      for (final b in oldBubbles) {
        b.controller.dispose();
      }
    });
  }

  void _onWin() {
    context.read<GameState>().completeWorld(WorldId.bubble);
    context.read<GameState>().addCoins(5);
    VictoryPopup.show(context, didWin: true, coinsEarned: 5, worldName: 'Bubble Sky');
  }

  void _onLose() {
    VictoryPopup.show(context, didWin: false, worldName: 'Bubble Sky');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedWorldBackground(
        theme: BackgroundTheme.meadow,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                  top: 12, left: 16, child: LivesHud(lives: state.lives)),
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Level $_level / $_maxLevel  •  Pop matching pairs!',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ),
              const BackToMenuButton(),
              ..._bubbles.where((b) => !b.isPopped).map((b) {
                return AnimatedBuilder(
                  animation: b.controller,
                  builder: (context, _) {
                    final yFraction = 1.0 - b.controller.value;
                    final screenY =
                        size.height * 0.15 + yFraction * size.height * 0.7;
                    return Positioned(
                      left: b.x * size.width - 35,
                      top: screenY,
                      child: GestureDetector(
                        onTap: () => _onBubbleTap(b),
                        child: _BubbleWidget(
                          color: _colorMap[b.color]!,
                          isSelected: b.isSelected,
                        ),
                      ),
                    );
                  },
                );
              }),
              if (_showBurst)
                Positioned(
                  left: MediaQuery.of(context).size.width / 2 - 40,
                  top: MediaQuery.of(context).size.height * 0.4 - 40,
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: ParticleBurst(
                      key: ValueKey(_burstCount),
                      color: _burstColor,
                      particleCount: 12,
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

class _BubbleWidget extends StatelessWidget {
  final Color color;
  final bool isSelected;

  const _BubbleWidget({required this.color, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.75),
        border: Border.all(
          color: isSelected ? Colors.white : color.withValues(alpha: 0.5),
          width: isSelected ? 3 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: isSelected ? 16 : 6,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Specular highlight
          Positioned(
            left: 12,
            top: 10,
            child: Container(
              width: 18,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
