import 'dart:math';
import 'package:flutter/material.dart';

enum WeatherType { sunny, cloudy, lightRain }

enum BackgroundTheme { meadow, forest, night, river, grassland }

class AnimatedWorldBackground extends StatefulWidget {
  final BackgroundTheme theme;
  final Widget child;

  const AnimatedWorldBackground({
    super.key,
    required this.theme,
    required this.child,
  });

  @override
  State<AnimatedWorldBackground> createState() =>
      _AnimatedWorldBackgroundState();
}

class _AnimatedWorldBackgroundState extends State<AnimatedWorldBackground>
    with TickerProviderStateMixin {
  late AnimationController _grassController;
  late AnimationController _cloudController;
  late AnimationController _rainController;
  late WeatherType _weather;
  final Random _rng = Random();
  late List<_CloudData> _clouds;
  late List<_RainDrop> _rainDrops;
  late List<_TreeData> _trees;
  late AnimationController _driftController;
  late List<_DriftBlob> _driftBlobs;
  late List<_RiverParticle> _riverParticles;
  late List<Offset> _starPositions;
  late List<double> _starSizes;

  @override
  void initState() {
    super.initState();

    _weather = WeatherType.values[_rng.nextInt(WeatherType.values.length)];

    _grassController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _rainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (_weather == WeatherType.lightRain) {
      _rainController.repeat();
    }

    _clouds = List.generate(
        4,
        (i) => _CloudData(
              x: _rng.nextDouble(),
              y: 0.05 + _rng.nextDouble() * 0.15,
              scale: 0.6 + _rng.nextDouble() * 0.7,
              speed: 0.01 + _rng.nextDouble() * 0.02,
            ));

    _rainDrops = List.generate(
        40,
        (i) => _RainDrop(
              x: _rng.nextDouble(),
              y: _rng.nextDouble(),
              length: 8 + _rng.nextDouble() * 12,
              speed: 0.015 + _rng.nextDouble() * 0.01,
            ));

    // Cache star positions so _StarsPainter doesn't recreate Random every frame
    final starRng = Random(7);
    _starPositions = List.generate(
        30, (i) => Offset(starRng.nextDouble(), starRng.nextDouble()));
    _starSizes = List.generate(30, (i) => 1.5 + starRng.nextDouble() * 1.5);

    // Move cloud/rain position mutations into animation listeners
    _cloudController.addListener(() {
      for (final c in _clouds) {
        c.x = (c.x + c.speed * _cloudController.value * 0.05) % 1.2;
      }
    });
    _rainController.addListener(() {
      if (_weather == WeatherType.lightRain) {
        for (final r in _rainDrops) {
          r.y = (r.y + r.speed) % 1.1;
        }
      }
    });

    _trees = List.generate(
        6,
        (i) => _TreeData(
              x: 0.05 + i * 0.17 + _rng.nextDouble() * 0.05,
              height: 0.18 + _rng.nextDouble() * 0.12,
              trunkWidth: 10 + _rng.nextDouble() * 6,
              layers: 2 + _rng.nextInt(2),
              color: _treeColorForTheme(widget.theme),
            ));

    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120),
    )..repeat();

    _driftBlobs = [
      _DriftBlob(
          xBase: 0.05, y: 0.06, width: 100, height: 28, phaseOffset: 0.0),
      _DriftBlob(
          xBase: 0.40, y: 0.11, width: 130, height: 32, phaseOffset: 1.1),
      _DriftBlob(xBase: 0.72, y: 0.07, width: 90, height: 24, phaseOffset: 2.2),
    ];

    _riverParticles = List.generate(
        20,
        (i) => _RiverParticle(
              x: _rng.nextDouble(),
              yBase: _rng.nextDouble(),
              phaseOffset: _rng.nextDouble() * 2 * pi,
            ));
  }

  Color _treeColorForTheme(BackgroundTheme t) {
    switch (t) {
      case BackgroundTheme.forest:
        return const Color(0xFF2E7D32);
      case BackgroundTheme.night:
        return const Color(0xFF1B5E20);
      case BackgroundTheme.river:
        return const Color(0xFF388E3C);
      case BackgroundTheme.meadow:
      case BackgroundTheme.grassland:
        return const Color(0xFF43A047);
    }
  }

  List<Color> _skyColors() {
    switch (widget.theme) {
      case BackgroundTheme.night:
        return [const Color(0xFF0D1B4B), const Color(0xFF1A237E)];
      case BackgroundTheme.forest:
        return [const Color(0xFF1B5E20), const Color(0xFF2E7D32)];
      case BackgroundTheme.river:
        return [const Color(0xFF1565C0), const Color(0xFF42A5F5)];
      case BackgroundTheme.meadow:
        return _weather == WeatherType.sunny
            ? [const Color(0xFF29B6F6), const Color(0xFF81D4FA)]
            : [const Color(0xFF78909C), const Color(0xFFB0BEC5)];
      case BackgroundTheme.grassland:
        return _weather == WeatherType.lightRain
            ? [const Color(0xFF546E7A), const Color(0xFF90A4AE)]
            : [const Color(0xFF26C6DA), const Color(0xFFB2EBF2)];
    }
  }

  Color _grassColor() {
    switch (widget.theme) {
      case BackgroundTheme.night:
        return const Color(0xFF1B5E20);
      case BackgroundTheme.forest:
        return const Color(0xFF2E7D32);
      case BackgroundTheme.river:
        return const Color(0xFF1565C0); // river = water
      case BackgroundTheme.meadow:
      case BackgroundTheme.grassland:
        return const Color(0xFF66BB6A);
    }
  }

  @override
  void dispose() {
    _grassController.dispose();
    _cloudController.dispose();
    _rainController.dispose();
    _driftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;

      return AnimatedBuilder(
        animation: Listenable.merge([
          _grassController,
          _cloudController,
          _rainController,
          _driftController,
        ]),
        builder: (context, _) {

          return Stack(
            children: [
              // Sky gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _skyColors(),
                  ),
                ),
              ),

              // Sun rays (sunny only)
              if (_weather == WeatherType.sunny &&
                  widget.theme != BackgroundTheme.night)
                Positioned(
                  top: -30,
                  right: 30,
                  child: CustomPaint(
                    size: Size(w * 0.4, w * 0.4),
                    painter: _SunPainter(
                      pulse: _grassController.value,
                    ),
                  ),
                ),

              // Clouds
              ..._clouds.map((c) => Positioned(
                    left: c.x * w - 40,
                    top: c.y * h,
                    child: Opacity(
                      opacity: _weather == WeatherType.cloudy ? 0.85 : 0.5,
                      child: CustomPaint(
                        size: Size(90 * c.scale, 45 * c.scale),
                        painter: _CloudPainter(),
                      ),
                    ),
                  )),

              // Trees
              ...(_trees.map((t) => Positioned(
                    left: t.x * w - 20,
                    bottom: h * 0.22,
                    child: CustomPaint(
                      size: Size(50, h * t.height),
                      painter: _TreePainter(
                        layers: t.layers,
                        trunkWidth: t.trunkWidth,
                        color: t.color,
                        sway: _grassController.value,
                      ),
                    ),
                  ))),

              // Ground / grass strip
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: CustomPaint(
                  size: Size(w, h * 0.25),
                  painter: _GrassPainter(
                    color: _grassColor(),
                    swayValue: _grassController.value,
                    isRiver: widget.theme == BackgroundTheme.river,
                  ),
                ),
              ),

              // Rain
              if (_weather == WeatherType.lightRain)
                CustomPaint(
                  size: Size(w, h),
                  painter: _RainPainter(_rainDrops),
                ),

              // Night stars
              if (widget.theme == BackgroundTheme.night)
                CustomPaint(
                  size: Size(w, h * 0.6),
                  painter: _StarsPainter(
                    pulse: _grassController.value,
                    positions: _starPositions,
                    sizes: _starSizes,
                  ),
                ),

              // Drifting cloud blobs (meadow / grassland only)
              if (widget.theme == BackgroundTheme.meadow ||
                  widget.theme == BackgroundTheme.grassland)
                ..._driftBlobs.map((b) {
                  final t = _driftController.value;
                  final sineOffset = sin(t * 2 * pi + b.phaseOffset) * 0.06;
                  final x = ((b.xBase + t * 0.25 + sineOffset) % 1.15) - 0.05;
                  return Positioned(
                    left: x * w,
                    top: b.y * h,
                    child: Opacity(
                      opacity: 0.60,
                      child: Container(
                        width: b.width,
                        height: b.height,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(b.height / 2),
                        ),
                      ),
                    ),
                  );
                }),

              // Upward-floating particles (river only)
              if (widget.theme == BackgroundTheme.river)
                ..._riverParticles.map((p) {
                  final t = _driftController.value;
                  final rawY = p.yBase -
                      t * 0.4 +
                      sin(t * 2 * pi * 3 + p.phaseOffset) * 0.03;
                  final y = rawY % 1.0;
                  return Positioned(
                    left: p.x * w,
                    top: y * h,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Colors.white54,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),

              // Game content on top
              RepaintBoundary(child: widget.child),
            ],
          );
        },
      );
    });
  }
}

// --- Painters ---

class _GrassPainter extends CustomPainter {
  final Color color;
  final double swayValue;
  final bool isRiver;

  _GrassPainter(
      {required this.color, required this.swayValue, required this.isRiver});

  @override
  void paint(Canvas canvas, Size size) {
    if (isRiver) {
      // Animated water
      final paint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

      // Wave lines
      final wavePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (int i = 0; i < 3; i++) {
        final path = Path();
        final yBase = size.height * (0.2 + i * 0.25);
        path.moveTo(0, yBase);
        for (double x = 0; x <= size.width; x += 20) {
          path.sinusoidalLineTo(x, yBase + sin((x / 40 + swayValue * pi)) * 4);
        }
        canvas.drawPath(path, wavePaint);
      }
      return;
    }

    // Base grass
    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color,
          color.withGreen(
              ((color.g * 255.0).round().clamp(0, 255) - 20).clamp(0, 255))
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    // Grass blades
    final bladePaint = Paint()
      ..color = color.withGreen(
          ((color.g * 255.0).round().clamp(0, 255) + 30).clamp(0, 255))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final rng = Random(42); // fixed seed for consistent blade positions
    for (int i = 0; i < 30; i++) {
      final x = rng.nextDouble() * size.width;
      final bladeHeight = 8 + rng.nextDouble() * 12;
      final sway = sin(swayValue * pi + i * 0.7) * 3;
      final path = Path()
        ..moveTo(x, 4)
        ..quadraticBezierTo(
            x + sway, 4 + bladeHeight * 0.5, x + sway * 1.5, 4 + bladeHeight);
      canvas.drawPath(path, bladePaint);
    }
  }

  @override
  bool shouldRepaint(_GrassPainter old) => old.swayValue != swayValue;
}

class _TreePainter extends CustomPainter {
  final int layers;
  final double trunkWidth;
  final Color color;
  final double sway;

  _TreePainter({
    required this.layers,
    required this.trunkWidth,
    required this.color,
    required this.sway,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trunkPaint = Paint()..color = const Color(0xFF5D4037);
    final foliagePaint = Paint()..color = color;
    final highlightPaint = Paint()
      ..color = color.withGreen(
          ((color.g * 255.0).round().clamp(0, 255) + 40).clamp(0, 255));

    final swayAngle = sin(sway * pi) * 0.04;
    canvas.save();
    canvas.translate(size.width / 2, size.height);
    canvas.rotate(swayAngle);
    canvas.translate(-size.width / 2, -size.height);

    // Trunk
    final trunkRect = Rect.fromLTWH(
      size.width / 2 - trunkWidth / 2,
      size.height * 0.55,
      trunkWidth,
      size.height * 0.45,
    );
    canvas.drawRRect(
        RRect.fromRectAndRadius(trunkRect, const Radius.circular(3)),
        trunkPaint);

    // Foliage layers (triangles)
    for (int l = 0; l < layers; l++) {
      final layerY = size.height * 0.55 - l * size.height * 0.22;
      final layerWidth = size.width * (0.95 - l * 0.1);
      final layerHeight = size.height * 0.38;

      final path = Path()
        ..moveTo(size.width / 2, layerY - layerHeight)
        ..lineTo(size.width / 2 - layerWidth / 2, layerY)
        ..lineTo(size.width / 2 + layerWidth / 2, layerY)
        ..close();
      canvas.drawPath(path, foliagePaint);

      // Highlight
      final hPath = Path()
        ..moveTo(size.width / 2, layerY - layerHeight)
        ..lineTo(size.width / 2 - layerWidth * 0.15, layerY - layerHeight * 0.4)
        ..lineTo(size.width / 2 + layerWidth * 0.1, layerY - layerHeight * 0.6)
        ..close();
      canvas.drawPath(hPath, highlightPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_TreePainter old) => old.sway != sway;
}

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    canvas.drawOval(
        Rect.fromLTWH(size.width * 0.1, size.height * 0.3, size.width * 0.5,
            size.height * 0.6),
        paint);
    canvas.drawOval(
        Rect.fromLTWH(size.width * 0.35, size.height * 0.1, size.width * 0.4,
            size.height * 0.55),
        paint);
    canvas.drawOval(
        Rect.fromLTWH(size.width * 0.55, size.height * 0.25, size.width * 0.4,
            size.height * 0.55),
        paint);
  }

  @override
  bool shouldRepaint(_CloudPainter _) => false;
}

class _SunPainter extends CustomPainter {
  final double pulse;
  _SunPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.8, size.height * 0.2);
    final radius = size.width * 0.15 + pulse * 4;

    // Rays
    final rayPaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.25)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      canvas.drawLine(
        center + Offset(cos(angle) * radius * 1.3, sin(angle) * radius * 1.3),
        center + Offset(cos(angle) * radius * 1.9, sin(angle) * radius * 1.9),
        rayPaint,
      );
    }

    // Sun body
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(_SunPainter old) => old.pulse != pulse;
}

class _RainPainter extends CustomPainter {
  final List<_RainDrop> drops;
  _RainPainter(this.drops);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF90CAF9).withValues(alpha: 0.55)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (final d in drops) {
      final x = d.x * size.width;
      final y = d.y * size.height;
      canvas.drawLine(Offset(x, y), Offset(x + 2, y + d.length), paint);
    }
  }

  @override
  bool shouldRepaint(_RainPainter _) => true;
}

class _StarsPainter extends CustomPainter {
  final double pulse;
  final List<Offset> positions;
  final List<double> sizes;
  _StarsPainter({required this.pulse, required this.positions, required this.sizes});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < positions.length; i++) {
      final x = positions[i].dx * size.width;
      final y = positions[i].dy * size.height;
      final opacity = 0.4 + sin(pulse * pi + i) * 0.3;
      canvas.drawCircle(
        Offset(x, y),
        sizes[i],
        Paint()
          ..color = Colors.white.withValues(alpha: opacity.clamp(0.1, 0.9)),
      );
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) => old.pulse != pulse;
}

// Data classes
class _CloudData {
  double x, y, scale, speed;
  _CloudData(
      {required this.x,
      required this.y,
      required this.scale,
      required this.speed});
}

class _RainDrop {
  double x, y, length, speed;
  _RainDrop(
      {required this.x,
      required this.y,
      required this.length,
      required this.speed});
}

class _TreeData {
  double x, height, trunkWidth;
  int layers;
  Color color;
  _TreeData({
    required this.x,
    required this.height,
    required this.trunkWidth,
    required this.layers,
    required this.color,
  });
}

class _DriftBlob {
  final double xBase;
  final double y;
  final double width;
  final double height;
  final double phaseOffset;
  _DriftBlob({
    required this.xBase,
    required this.y,
    required this.width,
    required this.height,
    required this.phaseOffset,
  });
}

class _RiverParticle {
  final double x;
  double yBase;
  final double phaseOffset;
  _RiverParticle(
      {required this.x, required this.yBase, required this.phaseOffset});
}

// Extension for Path sinusoidal lines
extension on Path {
  void sinusoidalLineTo(double x, double y) {
    lineTo(x, y);
  }
}
