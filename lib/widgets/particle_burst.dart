import 'dart:math';
import 'package:flutter/material.dart';

class ParticleBurst extends StatefulWidget {
  final Color color;
  final int particleCount;

  const ParticleBurst({
    super.key,
    required this.color,
    this.particleCount = 12,
  });

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<ParticleBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _particles = List.generate(widget.particleCount, (_) => _Particle(
      angle: rng.nextDouble() * 2 * pi,
      speed: 40 + rng.nextDouble() * 60,
    ));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
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
      builder: (context, _) {
        final t = _controller.value;
        return Stack(
          clipBehavior: Clip.none,
          children: _particles.map((p) {
            final dx = cos(p.angle) * p.speed * t;
            final dy = sin(p.angle) * p.speed * t;
            return Positioned(
              left: dx,
              top: dy,
              child: Opacity(
                opacity: (1.0 - t).clamp(0.0, 1.0),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  _Particle({required this.angle, required this.speed});
}
