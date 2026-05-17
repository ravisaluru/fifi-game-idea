import 'dart:async';
import 'package:flutter/material.dart';
import '../models/multiplayer_session.dart';
import '../models/game_state.dart';
import '../services/multiplayer_service.dart';

/// Floating scoreboard overlay shown during multiplayer worlds.
/// Also drives AI tick logic when session is local-AI.
class MultiplayerScoreboard extends StatefulWidget {
  final MultiplayerSession session;
  final WorldId worldId;

  const MultiplayerScoreboard({
    super.key,
    required this.session,
    required this.worldId,
  });

  @override
  State<MultiplayerScoreboard> createState() => _MultiplayerScoreboardState();
}

class _MultiplayerScoreboardState extends State<MultiplayerScoreboard> {
  Timer? _aiTick;
  StreamSubscription? _remoteSub;

  @override
  void initState() {
    super.initState();

    if (widget.session.type == SessionType.localAi) {
      _startAiSimulation();
    } else {
      _watchRemotePlayers();
    }
  }

  void _startAiSimulation() {
    _aiTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      bool changed = false;
      for (final player in widget.session.players) {
        if (!player.isAi) continue;
        final sim = AiSimulator(player.aiDifficulty);
        final scoreTick = sim.scoreTickForWorld(widget.worldId);
        final progressTick = sim.progressTickForWorld(widget.worldId);
        if (scoreTick > 0 || progressTick > 0) {
          player.score += scoreTick;
          player.progress = (player.progress + progressTick).clamp(0.0, 1.0);
          changed = true;
        }
      }
      if (changed) setState(() {});
    });
  }

  void _watchRemotePlayers() {
    final code = widget.session.roomCode;
    _remoteSub = MultiplayerService.instance.watchRoom(code).listen((data) {
      if (!mounted || data.isEmpty) return;
      final rawPlayers = (data['players'] as Map<dynamic, dynamic>?) ?? {};
      for (final e in rawPlayers.entries) {
        final id = e.key as String;
        final vals = e.value as Map<dynamic, dynamic>;
        final score = (vals['score'] as num?)?.toInt() ?? 0;
        final progress = (vals['progress'] as num?)?.toDouble() ?? 0.0;
        widget.session.updateScore(id, score, progress: progress);
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _aiTick?.cancel();
    _remoteSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sorted = widget.session.sortedByScore;

    return Positioned(
      top: 50,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Scores', style: TextStyle(
                color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 4),
            ...sorted.asMap().entries.map((e) {
              final rank = e.key;
              final p = e.value;
              final isLeading = rank == 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p.isAi
                          ? (p.name == 'Robo' ? '🤖' : p.name == 'Ghost' ? '👻' : '🦕')
                          : (p.character?.emoji ?? '🧒'),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${p.score}',
                      style: TextStyle(
                        color: isLeading ? Colors.yellow : Colors.white,
                        fontSize: 14,
                        fontWeight: isLeading ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (p.progress > 0) ...[
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 36,
                        child: LinearProgressIndicator(
                          value: p.progress,
                          minHeight: 4,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation(
                            isLeading ? Colors.yellow : Colors.white54,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
