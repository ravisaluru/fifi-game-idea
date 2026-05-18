import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../screens/victory_screen.dart';
import '../widgets/animated_world_background.dart';
import '../widgets/lives_hud.dart';
import '../widgets/virtual_controls.dart';
import '../widgets/multiplayer_scoreboard.dart';

enum _TigerState { lookingAway, turningAround, lookingAtYou, turningAway }

class TigerWorldScreen extends StatefulWidget {
  const TigerWorldScreen({super.key});

  @override
  State<TigerWorldScreen> createState() => _TigerWorldScreenState();
}

class _TigerWorldScreenState extends State<TigerWorldScreen>
    with TickerProviderStateMixin {
  _TigerState _tigerState = _TigerState.lookingAway;
  bool get _isWatching =>
      _tigerState == _TigerState.lookingAtYou ||
      _tigerState == _TigerState.turningAround;

  double _playerProgress = 0.0; // 0.0 (start) to 1.0 (goal)
  static const double _stepSize = 0.08;

  Timer? _stateTimer;
  bool _wasCaught = false;
  final Random _rng = Random();

  late AnimationController _tigerBlinkController;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    context.read<GameState>().resetForWorld();

    _tigerBlinkController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _shakeController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);

    _scheduleNextStateChange();
  }

  @override
  void dispose() {
    _stateTimer?.cancel();
    _tigerBlinkController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _scheduleNextStateChange() {
    final ms = switch (_tigerState) {
      _TigerState.lookingAway    => 1500 + _rng.nextInt(1500),
      _TigerState.turningAround  => 400,
      _TigerState.lookingAtYou   => 1000 + _rng.nextInt(1500),
      _TigerState.turningAway    => 400,
    };
    _stateTimer?.cancel();
    _stateTimer = Timer(Duration(milliseconds: ms), _advanceState);
  }

  void _advanceState() {
    if (!mounted) return;
    setState(() {
      _tigerState = switch (_tigerState) {
        _TigerState.lookingAway   => _TigerState.turningAround,
        _TigerState.turningAround => _TigerState.lookingAtYou,
        _TigerState.lookingAtYou  => _TigerState.turningAway,
        _TigerState.turningAway   => _TigerState.lookingAway,
      };
    });
    _scheduleNextStateChange();
  }

  void _onMoveInput() {
    if (_isWatching || _wasCaught) return;
    setState(() => _playerProgress = (_playerProgress + _stepSize).clamp(0, 1));
    if (_playerProgress >= 1.0) _onWin();
  }

  void _onTap() {
    if (_isWatching && !_wasCaught) _onCaught();
    else if (!_isWatching) _onMoveInput();
  }

  void _onCaught() async {
    if (_wasCaught) return;
    _wasCaught = true;
    await _shakeController.forward(from: 0);
    _shakeController.reset();

    final state = context.read<GameState>();
    state.loseLife();
    setState(() {
      _playerProgress = max(0, _playerProgress - _stepSize * 2);
      _wasCaught = false;
    });

    if (state.lives <= 0) {
      Future.delayed(const Duration(milliseconds: 600), _onLose);
    }
  }

  void _onWin() {
    context.read<GameState>().completeWorld(WorldId.tiger);
    context.read<GameState>().addCoins(5);
    Navigator.pushReplacementNamed(context, '/victory',
        arguments: const VictoryArgs(didWin: true, coinsEarned: 5, worldName: 'Tiger Plains'));
  }

  void _onLose() {
    Navigator.pushReplacementNamed(context, '/victory',
        arguments: const VictoryArgs(didWin: false, worldName: 'Tiger Plains'));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final size = MediaQuery.of(context).size;

    final tigerEmoji = switch (_tigerState) {
      _TigerState.lookingAway    => '🐯',
      _TigerState.turningAround  => '🔄',
      _TigerState.lookingAtYou   => '👁️',
      _TigerState.turningAway    => '🔄',
    };

    return Scaffold(
      body: GestureDetector(
        onTap: _onTap,
        child: AnimatedWorldBackground(
          theme: BackgroundTheme.grassland,
          child: SafeArea(
            child: Stack(
              children: [
                // HUD
                Positioned(top: 12, left: 16, child: LivesHud(lives: state.lives)),

                // Tiger state label
                Positioned(
                  top: 56, left: 0, right: 0,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        key: ValueKey(_tigerState),
                        _isWatching ? '🛑 STOP!' : '🟢 GO!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _isWatching ? Colors.red : Colors.green,
                          shadows: const [Shadow(blurRadius: 8, color: Colors.black38)],
                        ),
                      ),
                    ),
                  ),
                ),

                // Tiger
                Positioned(
                  right: 32,
                  top: size.height * 0.28,
                  child: AnimatedBuilder(
                    animation: _tigerBlinkController,
                    builder: (context, _) => Text(
                      tigerEmoji,
                      style: TextStyle(
                        fontSize: 64 + _tigerBlinkController.value * 4,
                      ),
                    ),
                  ),
                ),

                // Goal line
                Positioned(
                  right: 24, top: size.height * 0.24,
                  child: Container(
                    width: 4, height: 80,
                    color: Colors.yellow.withValues(alpha: 0.7),
                  ),
                ),

                // Player
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (context, _) {
                    final playerX = 40 + _playerProgress * (size.width - 130);
                    return Positioned(
                      left: playerX + _shakeAnim.value - 24,
                      top: size.height * 0.30,
                      child: Text(
                        _wasCaught ? '😱' : '🏃',
                        style: const TextStyle(fontSize: 48),
                      ),
                    );
                  },
                ),

                // Progress bar
                Positioned(
                  bottom: 120, left: 16, right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Progress',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _playerProgress,
                          minHeight: 12,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF76FF03)),
                        ),
                      ),
                    ],
                  ),
                ),

                // Multiplayer scoreboard
                if (state.isMultiplayer)
                  MultiplayerScoreboard(
                    session: state.multiplayerSession!,
                    worldId: WorldId.tiger,
                  ),

                // Virtual controls
                VirtualControls(
                  onMove: (dir) { if (dir.dx > 0.3) _onMoveInput(); },
                  onRelease: () {},
                  showJump: false,
                ),

                // Hint
                Positioned(
                  bottom: 160, left: 0, right: 0,
                  child: Center(
                    child: Text(
                      'Tap or use joystick to move →',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
