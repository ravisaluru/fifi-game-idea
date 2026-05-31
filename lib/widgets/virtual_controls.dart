import 'package:flutter/material.dart';

class VirtualControls extends StatefulWidget {
  final void Function(Offset direction) onMove;
  final void Function() onRelease;
  final VoidCallback? onJump;
  final VoidCallback? onAction;
  final bool showJump;
  final bool showAction;

  const VirtualControls({
    super.key,
    required this.onMove,
    required this.onRelease,
    this.onJump,
    this.onAction,
    this.showJump = true,
    this.showAction = false,
  });

  @override
  State<VirtualControls> createState() => _VirtualControlsState();
}

class _VirtualControlsState extends State<VirtualControls> {
  Offset _thumbOffset = Offset.zero;
  bool _jumping = false;
  bool _actioning = false;

  static const double _baseRadius = 55.0;
  static const double _thumbRadius = 25.0;

  void _onPanUpdate(Offset localPos, Offset baseCenter) {
    final pos = localPos - baseCenter;
    final dist = pos.distance;
    final clamped =
        dist > _baseRadius ? pos / dist * _baseRadius : pos;
    setState(() => _thumbOffset = clamped);
    final normalized = clamped / _baseRadius;
    widget.onMove(normalized);
  }

  void _onPanEnd() {
    setState(() => _thumbOffset = Offset.zero);
    widget.onRelease();
  }

  @override
  Widget build(BuildContext context) {
    final baseCenter = Offset(_baseRadius + 12, _baseRadius + 12);

    return Stack(
      children: [
        // Left joystick
        Positioned(
          left: 16,
          bottom: 24,
          child: Listener(
            onPointerDown: (e) => _onPanUpdate(e.localPosition, baseCenter),
            onPointerMove: (e) => _onPanUpdate(e.localPosition, baseCenter),
            onPointerUp: (_) => _onPanEnd(),
            onPointerCancel: (_) => _onPanEnd(),
            child: SizedBox(
              width: (_baseRadius + 12) * 2,
              height: (_baseRadius + 12) * 2,
              child: CustomPaint(
                painter: _JoystickPainter(
                  thumbOffset: _thumbOffset,
                  baseRadius: _baseRadius,
                  thumbRadius: _thumbRadius,
                ),
              ),
            ),
          ),
        ),

        // Right action buttons
        Positioned(
          right: 16,
          bottom: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showJump && widget.onJump != null)
                _ActionButton(
                  label: '⬆️',
                  color: const Color(0xFF4CAF50),
                  isPressed: _jumping,
                  onTapDown: () {
                    setState(() => _jumping = true);
                    widget.onJump!();
                  },
                  onTapUp: () => setState(() => _jumping = false),
                ),
              if (widget.showAction && widget.onAction != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _ActionButton(
                    label: '✅',
                    color: const Color(0xFF2196F3),
                    isPressed: _actioning,
                    onTapDown: () {
                      setState(() => _actioning = true);
                      widget.onAction!();
                    },
                    onTapUp: () => setState(() => _actioning = false),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isPressed;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.isPressed,
    required this.onTapDown,
    required this.onTapUp,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => onTapDown(),
      onPointerUp: (_) => onTapUp(),
      onPointerCancel: (_) => onTapUp(),
      child: AnimatedScale(
        scale: isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.85),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(label, style: const TextStyle(fontSize: 28)),
          ),
        ),
      ),
    );
  }
}

class _JoystickPainter extends CustomPainter {
  final Offset thumbOffset;
  final double baseRadius;
  final double thumbRadius;

  _JoystickPainter({
    required this.thumbOffset,
    required this.baseRadius,
    required this.thumbRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Base circle
    canvas.drawCircle(
      center,
      baseRadius,
      Paint()..color = Colors.white.withValues(alpha: 0.25),
    );
    canvas.drawCircle(
      center,
      baseRadius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Thumb
    canvas.drawCircle(
      center + thumbOffset,
      thumbRadius,
      Paint()..color = Colors.white.withValues(alpha: 0.75),
    );
  }

  @override
  bool shouldRepaint(_JoystickPainter old) => old.thumbOffset != thumbOffset;
}
