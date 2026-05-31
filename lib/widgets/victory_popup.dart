import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class _Spark {
  Offset pos;
  Offset vel;
  Color color;
  double life;
  _Spark({required this.pos, required this.vel, required this.color, this.life = 1.0});
}

class VictoryPopup extends StatefulWidget {
  final bool didWin;
  final String worldName;
  final int coinsEarned;

  const VictoryPopup({
    super.key,
    required this.didWin,
    required this.worldName,
    this.coinsEarned = 0,
  });

  static Future<void> show(BuildContext context, {
    required bool didWin,
    required String worldName,
    int coinsEarned = 0,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => VictoryPopup(
        didWin: didWin,
        worldName: worldName,
        coinsEarned: coinsEarned,
      ),
    );
  }

  @override
  State<VictoryPopup> createState() => _VictoryPopupState();
}

class _VictoryPopupState extends State<VictoryPopup> with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final List<_Spark> _sparks = [];
  final Random _rng = Random();
  DateTime? _lastFrame;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _ticker.addListener(_onTick);
  }

  void _onTick() {
    if (!mounted) return;
    final now = DateTime.now();
    final dt = _lastFrame != null ? now.difference(_lastFrame!).inMilliseconds / 1000.0 : 0.016;
    _lastFrame = now;

    // spawn fireworks occasionally if won
    if (widget.didWin && _rng.nextDouble() < 0.15) {
      final cx = (_rng.nextDouble() - 0.5) * 300;
      final cy = (_rng.nextDouble() - 0.5) * 300 - 100;
      final color = Colors.primaries[_rng.nextInt(Colors.primaries.length)];
      for (int i = 0; i < 40; i++) {
        final angle = _rng.nextDouble() * 2 * pi;
        final speed = 50 + _rng.nextDouble() * 150;
        _sparks.add(_Spark(
          pos: Offset(cx, cy),
          vel: Offset(cos(angle) * speed, sin(angle) * speed),
          color: color,
          life: 1.0 + _rng.nextDouble() * 0.5,
        ));
      }
    }

    // update sparks
    for (int i = _sparks.length - 1; i >= 0; i--) {
      final s = _sparks[i];
      s.pos += s.vel * dt;
      s.vel += const Offset(0, 200) * dt; // gravity
      s.life -= dt * 1.0;
      if (s.life <= 0) _sparks.removeAt(i);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Fireworks background
          if (widget.didWin)
            IgnorePointer(
              child: CustomPaint(
                size: const Size(400, 400),
                painter: _FireworksPainter(_sparks),
              ),
            ),
            
          // Main card
          Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 8)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.didWin ? '🎉 Victory! 🎉' : 'Ouch! 🤕',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: widget.didWin ? Colors.green[600] : Colors.red[600],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.worldName,
                  style: const TextStyle(fontSize: 20, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                if (widget.didWin && widget.coinsEarned > 0) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 8),
                        Text(
                          '+${widget.coinsEarned}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacementNamed(context, '/world-select');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B1FA2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: const Text('Back to Worlds', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FireworksPainter extends CustomPainter {
  final List<_Spark> sparks;
  _FireworksPainter(this.sparks);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    final paint = Paint()..strokeCap = StrokeCap.round;
    for (final s in sparks) {
      paint.color = s.color.withValues(alpha: s.life.clamp(0.0, 1.0));
      paint.strokeWidth = 3.0 + s.life * 2;
      canvas.drawPoints(PointMode.points, [s.pos], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter old) => true;
}
