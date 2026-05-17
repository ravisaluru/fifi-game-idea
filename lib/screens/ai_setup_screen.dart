import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/multiplayer_session.dart';
import '../models/character.dart';
import '../widgets/animated_world_background.dart';

class AiSetupScreen extends StatefulWidget {
  const AiSetupScreen({super.key});

  @override
  State<AiSetupScreen> createState() => _AiSetupScreenState();
}

class _AiSetupScreenState extends State<AiSetupScreen> {
  int _aiCount = 1;
  AiDifficulty _difficulty = AiDifficulty.medium;

  void _startGame(BuildContext context) {
    final state = context.read<GameState>();

    // Build local player
    final localChar = state.selectedCharacter ?? availableCharacters[0];
    final localPlayer = SessionPlayer(
      id: 'local_player',
      name: localChar.displayName,
      character: localChar,
      isLocal: true,
    );

    // Build AI players
    final ais = List.generate(_aiCount, (i) {
      final p = aiPersonalities[i % aiPersonalities.length];
      return SessionPlayer(
        id: 'ai_$i',
        name: p['name']!,
        isAi: true,
        aiDifficulty: _difficulty,
      );
    });

    final session = MultiplayerSession(
      roomCode: 'LOCAL',
      type: SessionType.localAi,
      players: [localPlayer, ...ais],
    );

    state.setMultiplayerSession(session);
    Navigator.pushNamed(context, '/character');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedWorldBackground(
        theme: BackgroundTheme.grassland,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'Play vs AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black38)],
                ),
              ),
              const Spacer(),

              // Number of AI opponents
              _Section(
                label: 'AI Opponents',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [1, 2, 3].map((n) {
                    final selected = _aiCount == n;
                    return GestureDetector(
                      onTap: () => setState(() => _aiCount = n),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected
                              ? Colors.white.withOpacity(0.3)
                              : Colors.white.withOpacity(0.1),
                          border: Border.all(
                            color: selected ? Colors.white : Colors.white30,
                            width: selected ? 3 : 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              List.generate(n, (_) => '🤖').join(),
                              style: TextStyle(fontSize: n == 1 ? 28 : 18),
                            ),
                            Text('$n', style: const TextStyle(
                                color: Colors.white, fontSize: 14)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 32),

              // Difficulty
              _Section(
                label: 'Difficulty',
                child: Column(
                  children: AiDifficulty.values.map((d) {
                    final selected = _difficulty == d;
                    final label = difficultyLabels[d]!;
                    return GestureDetector(
                      onTap: () => setState(() => _difficulty = d),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        width: 260,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: selected
                              ? Colors.white.withOpacity(0.25)
                              : Colors.white.withOpacity(0.08),
                          border: Border.all(
                            color: selected ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const Spacer(),

              // AI previews
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_aiCount, (i) {
                  final p = aiPersonalities[i % aiPersonalities.length];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Text(p['emoji']!, style: const TextStyle(fontSize: 36)),
                        Text(p['name']!,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),

              // Start
              GestureDetector(
                onTap: () => _startGame(context),
                child: Container(
                  width: 220,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.5),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "Let's Play! 🎮",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('← Back',
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  final Widget child;
  const _Section({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
