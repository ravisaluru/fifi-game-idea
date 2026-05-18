import 'package:flutter/material.dart';

class BouncingEmoji extends StatefulWidget {
  final String emoji;
  final double fontSize;

  const BouncingEmoji({super.key, required this.emoji, this.fontSize = 36});

  @override
  State<BouncingEmoji> createState() => _BouncingEmojiState();
}

class _BouncingEmojiState extends State<BouncingEmoji>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _bounce = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (context, _) => Transform.translate(
        offset: Offset(0, _bounce.value),
        child: Text(widget.emoji, style: TextStyle(fontSize: widget.fontSize)),
      ),
    );
  }
}
