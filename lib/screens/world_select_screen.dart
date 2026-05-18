import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../widgets/bouncing_emoji.dart';
import '../widgets/shimmer_button.dart';

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
                    return ShimmerButton(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.pushReplacementNamed(
                          context, '/world/${w.id.name}'),
                      child: Container(
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
                                  BouncingEmoji(emoji: w.emoji, fontSize: 44),
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
