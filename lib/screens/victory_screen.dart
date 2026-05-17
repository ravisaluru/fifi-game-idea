import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';

class VictoryArgs {
  final bool didWin;
  final int coinsEarned;
  final String worldName;

  const VictoryArgs({
    required this.didWin,
    this.coinsEarned = 0,
    this.worldName = '',
  });
}

class VictoryScreen extends StatefulWidget {
  const VictoryScreen({super.key});

  @override
  State<VictoryScreen> createState() => _VictoryScreenState();
}

class _VictoryScreenState extends State<VictoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;
  final List<_ConfettiParticle> _particles = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)!.settings.arguments as VictoryArgs?;
      if (args?.didWin == true) {
        _spawnConfetti();
        _confettiController.forward();
      }
      _scaleController.forward();
    });
  }

  void _spawnConfetti() {
    for (int i = 0; i < 60; i++) {
      _particles.add(_ConfettiParticle(
        x: _rng.nextDouble(),
        y: -_rng.nextDouble() * 0.5,
        dx: (_rng.nextDouble() - 0.5) * 0.003,
        dy: 0.003 + _rng.nextDouble() * 0.004,
        color: _confettiColors[_rng.nextInt(_confettiColors.length)],
        size: 6 + _rng.nextDouble() * 8,
        rotation: _rng.nextDouble() * 2 * pi,
        rotationSpeed: (_rng.nextDouble() - 0.5) * 0.1,
      ));
    }
  }

  static const _confettiColors = [
    Colors.red, Colors.orange, Colors.yellow, Colors.green,
    Colors.blue, Colors.purple, Colors.pink, Colors.teal,
  ];

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as VictoryArgs?;
    final didWin = args?.didWin ?? false;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: didWin
                ? [const Color(0xFF1565C0), const Color(0xFF7B1FA2)]
                : [const Color(0xFF37474F), const Color(0xFF263238)],
          ),
        ),
        child: Stack(
          children: [
            // Confetti layer
            if (didWin)
              AnimatedBuilder(
                animation: _confettiController,
                builder: (context, _) {
                  for (final p in _particles) {
                    p.x += p.dx;
                    p.y += p.dy;
                    p.rotation += p.rotationSpeed;
                  }
                  return CustomPaint(
                    painter: _ConfettiPainter(_particles),
                    size: Size.infinite,
                  );
                },
              ),

            // Main content
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Text(
                      didWin ? '🏆' : '💪',
                      style: const TextStyle(fontSize: 96),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    didWin ? 'Hooray!' : 'Good Try!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      shadows: const [Shadow(blurRadius: 12, color: Colors.black38)],
                    ),
                  ),
                  if (didWin && (args?.coinsEarned ?? 0) > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '+${args!.coinsEarned} coins! 🪙',
                      style: const TextStyle(color: Colors.yellow, fontSize: 24),
                    ),
                  ],
                  const SizedBox(height: 48),

                  // Play Again
                  _BigButton(
                    label: didWin ? 'Play Again! 🚀' : 'Try Again! 💪',
                    color: const Color(0xFFFFD700),
                    textColor: Colors.black87,
                    onTap: () {
                      context.read<GameState>().resetForWorld();
                      Navigator.pushReplacementNamed(context, '/character');
                    },
                  ),

                  const SizedBox(height: 16),

                  // Home
                  _BigButton(
                    label: 'Home 🏠',
                    color: Colors.white.withOpacity(0.2),
                    textColor: Colors.white,
                    onTap: () => Navigator.popUntil(context, ModalRoute.withName('/')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _BigButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor)),
        ),
      ),
    );
  }
}

class _ConfettiParticle {
  double x, y, dx, dy, rotation, rotationSpeed, size;
  Color color;
  _ConfettiParticle({
    required this.x, required this.y, required this.dx, required this.dy,
    required this.color, required this.size,
    required this.rotation, required this.rotationSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      if (p.y > 1.1) continue;
      final paint = Paint()..color = p.color.withOpacity(0.85);
      canvas.save();
      canvas.translate(p.x * size.width, p.y * size.height);
      canvas.rotate(p.rotation);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter _) => true;
}
