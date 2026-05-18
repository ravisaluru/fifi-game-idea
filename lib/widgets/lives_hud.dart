import 'package:flutter/material.dart';

class LivesHud extends StatefulWidget {
  final int lives;
  final int maxLives;

  const LivesHud({super.key, required this.lives, this.maxLives = 3});

  @override
  State<LivesHud> createState() => _LivesHudState();
}

class _LivesHudState extends State<LivesHud> with TickerProviderStateMixin {
  late List<AnimationController> _pulseControllers;
  late List<Animation<double>> _pulseAnims;
  int _prevLives = 3;

  @override
  void initState() {
    super.initState();
    _prevLives = widget.lives;
    _pulseControllers = List.generate(widget.maxLives, (_) =>
      AnimationController(vsync: this, duration: const Duration(milliseconds: 300)));
    _pulseAnims = _pulseControllers.map((c) =>
      TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 1.4, end: 0.7), weight: 1),
      ]).animate(c)).toList();
  }

  @override
  void didUpdateWidget(LivesHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lives < _prevLives && widget.lives >= 0) {
      final idx = widget.lives;
      if (idx < _pulseControllers.length) {
        _pulseControllers[idx].forward(from: 0);
      }
    }
    _prevLives = widget.lives;
  }

  @override
  void dispose() {
    for (final c in _pulseControllers) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.maxLives, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedBuilder(
            animation: _pulseControllers[i],
            builder: (context, _) {
              final double scale;
              if (_pulseControllers[i].isAnimating) {
                scale = _pulseAnims[i].value;
              } else {
                scale = i < widget.lives ? 1.0 : 0.7;
              }
              return Transform.scale(
                scale: scale,
                child: Text(
                  i < widget.lives ? '❤️' : '🖤',
                  style: const TextStyle(fontSize: 28),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
