import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/multiplayer_session.dart';
import '../widgets/animated_world_background.dart';

class MultiplayerMenuScreen extends StatelessWidget {
  const MultiplayerMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedWorldBackground(
        theme: BackgroundTheme.meadow,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'Play Together!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black38)],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose how to play',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const Spacer(),

              // Online
              _ModeCard(
                emoji: '🌐',
                title: 'Play Online',
                subtitle: 'Invite friends with a room code',
                color: const Color(0xFF1565C0),
                onTap: () => Navigator.pushNamed(context, '/lobby'),
              ),

              const SizedBox(height: 20),

              // vs AI
              _ModeCard(
                emoji: '🤖',
                title: 'Play vs AI',
                subtitle: 'Challenge computer players',
                color: const Color(0xFF6A1B9A),
                onTap: () => Navigator.pushNamed(context, '/ai-setup'),
              ),

              const Spacer(),

              // Back
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Text('←'),
                  label: const Text('Back',
                      style: TextStyle(color: Colors.white70, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatefulWidget {
  final String emoji, title, subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({
    required this.emoji, required this.title, required this.subtitle,
    required this.color, required this.onTap,
  });

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 300,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.5),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      )),
                  Text(widget.subtitle,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
