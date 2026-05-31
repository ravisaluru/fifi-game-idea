import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';


class WorldSelectScreen extends StatelessWidget {
  const WorldSelectScreen({super.key});

  static const _worlds = [
    _WorldCard(
        id: WorldId.tiger,
        emoji: '🐯',
        name: 'Tiger Plains',
        gradient: [Color(0xFFFF8F00), Color(0xFFE65100)]),
    _WorldCard(
        id: WorldId.firefly,
        emoji: '🧚',
        name: 'Firefly Forest',
        gradient: [Color(0xFF1B5E20), Color(0xFF4CAF50)]),
    _WorldCard(
        id: WorldId.bubble,
        emoji: '🫧',
        name: 'Bubble World',
        gradient: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
    _WorldCard(
        id: WorldId.stones,
        emoji: '🪨',
        name: 'Stepping Stones',
        gradient: [Color(0xFF4E342E), Color(0xFF8D6E63)]),
    _WorldCard(
        id: WorldId.star,
        emoji: '⭐',
        name: 'Star Shower',
        gradient: [Color(0xFF0D1B4B), Color(0xFF1A237E)]),
    _WorldCard(
        id: WorldId.snake,
        emoji: '🐍',
        name: 'Snake Grassland',
        gradient: [Color(0xFF33691E), Color(0xFF8BC34A)]),
    _WorldCard(
        id: WorldId.treasure,
        emoji: '🪙',
        name: 'Treasure Hunt',
        gradient: [Color(0xFF4A148C), Color(0xFF9C27B0)]),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF7B1FA2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Choose a World!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/character'),
                      icon: const Text('🎭', style: TextStyle(fontSize: 20)),
                      label: const Text('Change Hero',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _worlds.length,
                  itemBuilder: (context, i) {
                    final w = _worlds[i];
                    final done = state.completedWorlds.contains(w.id);
                    return GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(
                          context, '/world/${w.id.name}'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: w.gradient,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: done
                              ? Border.all(color: Colors.yellow, width: 2.5)
                              : null,
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 60,
                                    child: Center(
                                      child: WorldGamePreview(id: w.id),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    w.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (done)
                              const Positioned(
                                top: 8,
                                right: 10,
                                child:
                                    Text('⭐', style: TextStyle(fontSize: 20)),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorldCard {
  final WorldId id;
  final String emoji;
  final String name;
  final List<Color> gradient;
  const _WorldCard({
    required this.id,
    required this.emoji,
    required this.name,
    required this.gradient,
  });
}

// ==========================================
// Loop Previews for World Select Cards
// ==========================================

class WorldGamePreview extends StatelessWidget {
  final WorldId id;
  const WorldGamePreview({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    switch (id) {
      case WorldId.tiger:
        return const TigerPlainsPreview();
      case WorldId.firefly:
        return const FireflyForestPreview();
      case WorldId.bubble:
        return const BubbleWorldPreview();
      case WorldId.stones:
        return const SteppingStonesPreview();
      case WorldId.star:
        return const StarShowerPreview();
      case WorldId.snake:
        return const SnakeGrasslandPreview();
      case WorldId.treasure:
        return const TreasureHuntPreview();
    }
  }
}

class TigerPlainsPreview extends StatefulWidget {
  const TigerPlainsPreview({super.key});
  @override
  State<TigerPlainsPreview> createState() => _TigerPlainsPreviewState();
}

class _TigerPlainsPreviewState extends State<TigerPlainsPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final isGreen = progress < 0.4 || (progress >= 0.5 && progress < 0.9);

        double posX = 0.0;
        if (progress < 0.4) {
          posX = progress / 0.4 * 0.4;
        } else if (progress < 0.5) {
          posX = 0.4;
        } else if (progress < 0.9) {
          posX = 0.4 + (progress - 0.5) / 0.4 * 0.4;
        } else {
          posX = 0.8;
        }

        return SizedBox(
          width: 100,
          height: 60,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned(
                  left: 4, bottom: 4, child: Text('🏖️', style: TextStyle(fontSize: 12))),
              const Positioned(
                  right: 4, bottom: 4, child: Text('🐯', style: TextStyle(fontSize: 20))),
              Positioned(
                left: 32,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: (isGreen ? Colors.green : Colors.red)
                        .withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: isGreen ? Colors.greenAccent : Colors.redAccent,
                        width: 0.8),
                  ),
                  child: Text(
                    isGreen ? 'GO' : 'STOP',
                    style: TextStyle(
                      color: isGreen ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10 + posX * 60,
                bottom: 4,
                child: const Text('🏃', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class FireflyForestPreview extends StatefulWidget {
  const FireflyForestPreview({super.key});
  @override
  State<FireflyForestPreview> createState() => _FireflyForestPreviewState();
}

class _FireflyForestPreviewState extends State<FireflyForestPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value * 2 * pi;
        return SizedBox(
          width: 100,
          height: 60,
          child: Stack(
            children: [
              const Center(
                  child: Text('🧚', style: TextStyle(fontSize: 22))),
              Positioned(
                left: 30 + 15 * cos(t),
                top: 20 + 12 * sin(t),
                child: _GlowingDot(
                    opacity: (0.4 + 0.6 * sin(t)).clamp(0.0, 1.0)),
              ),
              Positioned(
                left: 55 + 18 * sin(t + pi / 2),
                top: 15 + 15 * cos(t + pi / 2),
                child: _GlowingDot(
                    opacity: (0.4 + 0.6 * cos(t + pi / 2)).clamp(0.0, 1.0)),
              ),
              Positioned(
                left: 45 + 20 * cos(t * 1.5 + pi),
                top: 35 + 10 * sin(t * 1.5 + pi),
                child: _GlowingDot(
                    opacity: (0.3 + 0.7 * sin(t * 1.5)).clamp(0.0, 1.0)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlowingDot extends StatelessWidget {
  final double opacity;
  const _GlowingDot({required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.yellowAccent,
          boxShadow: [
            BoxShadow(
              color: Colors.yellow.withValues(alpha: 0.8),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class BubbleWorldPreview extends StatefulWidget {
  const BubbleWorldPreview({super.key});
  @override
  State<BubbleWorldPreview> createState() => _BubbleWorldPreviewState();
}

class _BubbleWorldPreviewState extends State<BubbleWorldPreview>
    with TickerProviderStateMixin {
  late AnimationController _c1;
  late AnimationController _c2;

  @override
  void initState() {
    super.initState();
    _c1 = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat();
    _c2 = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
  }

  @override
  void dispose() {
    _c1.dispose();
    _c2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 60,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _c1,
            builder: (context, _) {
              final val = _c1.value;
              final isPopped = val > 0.85;
              final opacity = isPopped ? 0.0 : 1.0;
              final size = isPopped ? 24.0 : 14.0;
              return Positioned(
                left: 25 + val * 10,
                bottom: val * 45,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.lightBlueAccent.withValues(alpha: 0.5),
                      border: Border.all(color: Colors.white70, width: 1.0),
                    ),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _c2,
            builder: (context, _) {
              final val = _c2.value;
              final isPopped = val > 0.9;
              final opacity = isPopped ? 0.0 : 1.0;
              final size = isPopped ? 22.0 : 12.0;
              return Positioned(
                left: 55 - val * 8,
                bottom: val * 48,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.redAccent.withValues(alpha: 0.5),
                      border: Border.all(color: Colors.white70, width: 1.0),
                    ),
                  ),
                ),
              );
            },
          ),
          const Center(
              child: Text('🫧', style: TextStyle(fontSize: 22))),
        ],
      ),
    );
  }
}

class SteppingStonesPreview extends StatefulWidget {
  const SteppingStonesPreview({super.key});
  @override
  State<SteppingStonesPreview> createState() => _SteppingStonesPreviewState();
}

class _SteppingStonesPreviewState extends State<SteppingStonesPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;

        double posX = 15.0;
        double posY = 35.0;
        double hopHeight = 0.0;

        if (progress < 0.25) {
          final t = progress / 0.25;
          posX = 15.0 + t * 30.0;
          hopHeight = sin(t * pi) * 20.0;
        } else if (progress < 0.5) {
          final t = (progress - 0.25) / 0.25;
          posX = 45.0 + t * 30.0;
          hopHeight = sin(t * pi) * 20.0;
        } else if (progress < 0.75) {
          final t = (progress - 0.5) / 0.25;
          posX = 75.0 - t * 30.0;
          hopHeight = sin(t * pi) * 20.0;
        } else {
          final t = (progress - 0.75) / 0.25;
          posX = 45.0 - t * 30.0;
          hopHeight = sin(t * pi) * 20.0;
        }

        posY = 35.0 - hopHeight;

        return SizedBox(
          width: 110,
          height: 60,
          child: Stack(
            children: [
              const Positioned(left: 15, bottom: 6, child: _MiniStone()),
              const Positioned(left: 45, bottom: 6, child: _MiniStone()),
              const Positioned(left: 75, bottom: 6, child: _MiniStone()),
              Positioned(
                left: posX,
                top: posY - 18,
                child: const Text('🧒', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniStone extends StatelessWidget {
  const _MiniStone();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 10,
      decoration: BoxDecoration(
        color: const Color(0xFF90A4AE),
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(
              color: Colors.black26, blurRadius: 2, offset: Offset(0, 1.0)),
        ],
      ),
    );
  }
}

class StarShowerPreview extends StatefulWidget {
  const StarShowerPreview({super.key});
  @override
  State<StarShowerPreview> createState() => _StarShowerPreviewState();
}

class _StarShowerPreviewState extends State<StarShowerPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        return SizedBox(
          width: 100,
          height: 60,
          child: Stack(
            children: [
              Positioned(
                left: 15,
                top: ((progress * 60) % 60) - 10,
                child: Transform.rotate(
                  angle: progress * 2 * pi,
                  child: const Text('⭐', style: TextStyle(fontSize: 10)),
                ),
              ),
              Positioned(
                left: 45,
                top: (((progress + 0.3) * 60) % 60) - 10,
                child: Transform.rotate(
                  angle: (progress + 0.3) * 2 * pi,
                  child: const Text('⭐', style: TextStyle(fontSize: 14)),
                ),
              ),
              Positioned(
                left: 75,
                top: (((progress + 0.6) * 60) % 60) - 10,
                child: Transform.rotate(
                  angle: (progress + 0.6) * 2 * pi,
                  child: const Text('⭐', style: TextStyle(fontSize: 9)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SnakeGrasslandPreview extends StatefulWidget {
  const SnakeGrasslandPreview({super.key});
  @override
  State<SnakeGrasslandPreview> createState() => _SnakeGrasslandPreviewState();
}

class _SnakeGrasslandPreviewState extends State<SnakeGrasslandPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value * 2 * pi;
        return SizedBox(
          width: 100,
          height: 60,
          child: Stack(
            children: [
              const Center(
                  child: Text('🪨', style: TextStyle(fontSize: 12))),
              Positioned(
                left: 40 + 20 * cos(t),
                top: 20 + 12 * sin(t),
                child: Transform.rotate(
                  angle: t + pi / 2,
                  child: const Text('🐍', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TreasureHuntPreview extends StatefulWidget {
  const TreasureHuntPreview({super.key});
  @override
  State<TreasureHuntPreview> createState() => _TreasureHuntPreviewState();
}

class _TreasureHuntPreviewState extends State<TreasureHuntPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final val = _controller.value;

        final angle = (val < 0.5) ? (val / 0.5 * pi) : ((1.0 - val) / 0.5 * pi);

        final showCoin = val > 0.25 && val < 0.75;

        return SizedBox(
          width: 100,
          height: 60,
          child: Stack(
            children: [
              if (showCoin)
                const Center(
                    child: Text('🪙', style: TextStyle(fontSize: 16))),
              Center(
                child: Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateY(angle),
                  alignment: Alignment.center,
                  child: showCoin
                      ? const SizedBox.shrink()
                      : const Text('🍁', style: TextStyle(fontSize: 20)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
