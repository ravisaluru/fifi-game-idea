import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../screens/victory_screen.dart';
import '../widgets/animated_world_background.dart';
import '../widgets/lives_hud.dart';

enum _BubbleColor { red, yellow, blue, green, purple }

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
  _BubbleColor.red:    Color(0xFFEF5350),
  _BubbleColor.yellow: Color(0xFFFFEE58),
  _BubbleColor.blue:   Color(0xFF42A5F5),
  _BubbleColor.green:  Color(0xFF66BB6A),
  _BubbleColor.purple: Color(0xFFAB47BC),
};

class BubbleWorldScreen extends StatefulWidget {
  const BubbleWorldScreen({super.key});

  @override
  State<BubbleWorldScreen> createState() => _BubbleWorldScreenState();
}

class _BubbleWorldScreenState extends State<BubbleWorldScreen>
    with TickerProviderStateMixin {
  static const int _pairs = 5;
  late List<_Bubble> _bubbles;
  _Bubble? _selected;
  int _poppedPairs = 0;

  @override
  void initState() {
    super.initState();
    context.read<GameState>().resetForWorld();
    _initBubbles();
  }

  void _initBubbles() {
    final rng = Random();
    final colors = _BubbleColor.values.toList()..shuffle(rng);
    final pairs = colors.take(_pairs).expand((c) => [c, c]).toList()..shuffle(rng);

    _bubbles = List.generate(pairs.length, (i) {
      final b = _Bubble(
        id: i,
        color: pairs[i],
        x: 0.08 + rng.nextDouble() * 0.82,
      );
      final duration = Duration(milliseconds: 4000 + rng.nextInt(3000));
      final delay = rng.nextInt(2000);
      b.controller = AnimationController(vsync: this, duration: duration);
      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted) b.controller.forward();
      });
      b.controller.addStatusListener((status) {
        if (status == AnimationStatus.completed && !b.isPopped) {
          context.read<GameState>().loseLife();
          if (context.read<GameState>().lives <= 0) _onLose();
          setState(() => b.isPopped = true);
        }
      });
      return b;
    });
  }

  @override
  void dispose() {
    for (final b in _bubbles) b.controller.dispose();
    super.dispose();
  }

  void _onBubbleTap(_Bubble tapped) {
    if (tapped.isPopped) return;
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
      setState(() {
        _selected!.isPopped = true;
        tapped.isPopped = true;
        _selected = null;
        _poppedPairs++;
      });
      if (_poppedPairs >= _pairs) _onWin();
    } else {
      setState(() {
        _selected!.isSelected = false;
        _selected = null;
      });
      state.loseLife();
      if (state.lives <= 0) _onLose();
    }
  }

  void _onWin() {
    context.read<GameState>().completeWorld(WorldId.bubble);
    context.read<GameState>().addCoins(5);
    Navigator.pushReplacementNamed(context, '/victory',
        arguments: const VictoryArgs(didWin: true, coinsEarned: 5, worldName: 'Bubble Sky'));
  }

  void _onLose() {
    Navigator.pushReplacementNamed(context, '/victory',
        arguments: const VictoryArgs(didWin: false, worldName: 'Bubble Sky'));
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
              Positioned(top: 12, left: 16, child: LivesHud(lives: state.lives)),
              Positioned(
                top: 12, right: 16,
                child: Text('Pop matching pairs!',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ),

              ..._bubbles.where((b) => !b.isPopped).map((b) {
                return AnimatedBuilder(
                  animation: b.controller,
                  builder: (context, _) {
                    final yFraction = 1.0 - b.controller.value;
                    final screenY = size.height * 0.15 + yFraction * size.height * 0.7;
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
            left: 12, top: 10,
            child: Container(
              width: 18, height: 10,
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
