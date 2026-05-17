import 'package:flutter/material.dart';

class LivesHud extends StatelessWidget {
  final int lives;
  final int maxLives;

  const LivesHud({super.key, required this.lives, this.maxLives = 3});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxLives, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedScale(
            scale: i < lives ? 1.0 : 0.7,
            duration: const Duration(milliseconds: 200),
            child: Text(
              i < lives ? '❤️' : '🖤',
              style: const TextStyle(fontSize: 28),
            ),
          ),
        );
      }),
    );
  }
}
