import 'dart:math';
import 'package:flutter/material.dart';

class PortalButton extends StatefulWidget {
  final VoidCallback onTap;

  const PortalButton({super.key, required this.onTap});

  @override
  State<PortalButton> createState() => _PortalButtonState();
}

class _PortalButtonState extends State<PortalButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _pressController;
  late Animation<double> _pulseAnim;
  late Animation<double> _pressAnim;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pressAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _pressController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _pressController.reverse().then((_) => widget.onTap());
  }

  void _onTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnim, _pressAnim, _rotateController]),
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnim.value * _pressAnim.value,
            child: SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Rotating gradient ring
                  Transform.rotate(
                    angle: _rotateController.value * 2 * pi,
                    child: CustomPaint(
                      size: const Size(160, 160),
                      painter: _PortalRingPainter(),
                    ),
                  ),
                  // Inner glow circle
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFFCE93D8), Color(0xFF7B1FA2)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9C27B0).withOpacity(0.6),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🌀', style: TextStyle(fontSize: 48)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PortalRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    final paint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFFF6B6B),
          Color(0xFFFFD93D),
          Color(0xFF6BCB77),
          Color(0xFF4D96FF),
          Color(0xFFFF6B6B),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawOval(rect, paint);
  }

  @override
  bool shouldRepaint(_PortalRingPainter _) => false;
}
