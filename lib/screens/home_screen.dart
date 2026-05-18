import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../widgets/portal_button.dart';
import '../widgets/animated_world_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late List<_FloatingChar> _floaters;
  final Random _rng = Random();

  final List<String> _characterEmojis = ['🐯', '🌟', '🐍', '🪙', '🧚', '🦕'];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _floaters = List.generate(6, (i) => _FloatingChar(
      emoji: _characterEmojis[i % _characterEmojis.length],
      x: 0.05 + _rng.nextDouble() * 0.9,
      y: 0.1 + _rng.nextDouble() * 0.8,
      offset: _rng.nextDouble() * 2 * pi,
      amplitude: 8 + _rng.nextDouble() * 12,
    ));
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  void _onPortalTap(BuildContext context) {
    final state = context.read<GameState>();
    if (state.selectedCharacter != null) {
      Navigator.pushNamed(context, '/world-select');
    } else {
      Navigator.pushNamed(context, '/character');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedWorldBackground(
        theme: BackgroundTheme.meadow,
        child: SafeArea(
          child: Stack(
            children: [
              // Floating decorative characters
              AnimatedBuilder(
                animation: _floatController,
                builder: (context, _) => Stack(
                  children: _floaters.map((f) {
                    final dy = sin(_floatController.value * pi + f.offset) * f.amplitude;
                    return Positioned(
                      left: MediaQuery.of(context).size.width * f.x - 20,
                      top: MediaQuery.of(context).size.height * f.y + dy,
                      child: Opacity(
                        opacity: 0.6,
                        child: Text(f.emoji,
                            style: const TextStyle(fontSize: 36)),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Main content
              Column(
                children: [
                  const Spacer(),
                  // Title
                  const Text(
                    "Fifi's World\nAdventures",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                      shadows: [Shadow(blurRadius: 12, color: Colors.black38)],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Trophy counter
                  Consumer<GameState>(
                    builder: (context, state, _) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 4),
                        Text(
                          '${state.totalCoins}',
                          style: const TextStyle(
                            color: Colors.yellow,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text('🏆', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 4),
                        Text(
                          '${state.worldsCompleted}',
                          style: const TextStyle(
                            color: Colors.yellow,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Portal button
                  PortalButton(onTap: () => _onPortalTap(context)),

                  const SizedBox(height: 12),
                  const Text(
                    'Tap the portal!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Multiplayer button
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/multiplayer'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('👥', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text(
                            'Play with Others',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingChar {
  final String emoji;
  final double x, y, offset, amplitude;
  _FloatingChar({
    required this.emoji, required this.x, required this.y,
    required this.offset, required this.amplitude,
  });
}
