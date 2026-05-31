import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../widgets/animated_world_background.dart';
import '../widgets/back_to_menu_button.dart';
import '../widgets/victory_popup.dart';
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

  double _playerProgress = 0.0;
  static const double _stepSize = 0.03;
  bool _moveCooldown = false;

  Timer? _stateTimer;
  bool _wasCaught = false;
  final Random _rng = Random();

  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;
  late AnimationController _tigerScaleController;
  late Animation<double> _tigerScaleAnim;
  late AnimationController _bobController;
  late AnimationController _flashController;
  late Animation<double> _flashAnim;

  @override
  void initState() {
    super.initState();
    context.read<GameState>().resetForWorld();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);

    _tigerScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _tigerScaleAnim = Tween<double>(begin: 64, end: 70).animate(
      CurvedAnimation(parent: _tigerScaleController, curve: Curves.easeInOut),
    );

    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
    _flashAnim = Tween<double>(begin: 0.3, end: 0).animate(_flashController);

    _scheduleNextStateChange();
  }

  @override
  void dispose() {
    _stateTimer?.cancel();
    _shakeController.dispose();
    _tigerScaleController.dispose();
    _bobController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  void _scheduleNextStateChange() {
    final ms = switch (_tigerState) {
      _TigerState.lookingAway => 1500 + _rng.nextInt(1500),
      _TigerState.turningAround => 400,
      _TigerState.lookingAtYou => 1000 + _rng.nextInt(1500),
      _TigerState.turningAway => 400,
    };
    _stateTimer?.cancel();
    _stateTimer = Timer(Duration(milliseconds: ms), _advanceState);
  }

  void _advanceState() {
    if (!mounted) return;
    setState(() {
      _tigerState = switch (_tigerState) {
        _TigerState.lookingAway => _TigerState.turningAround,
        _TigerState.turningAround => _TigerState.lookingAtYou,
        _TigerState.lookingAtYou => _TigerState.turningAway,
        _TigerState.turningAway => _TigerState.lookingAway,
      };
    });
    if (_tigerState == _TigerState.turningAround) {
      _tigerScaleController.forward(from: 0);
    } else if (_tigerState == _TigerState.turningAway) {
      _tigerScaleController.reverse();
    }
    _scheduleNextStateChange();
  }

  void _onMoveInput() {
    if (_isWatching || _wasCaught || _moveCooldown) return;
    _moveCooldown = true;
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _moveCooldown = false);
    });
    setState(() => _playerProgress = (_playerProgress + _stepSize).clamp(0, 1));
    _bobController.forward(from: 0);
    if (_playerProgress >= 1.0) {
      _onWin();
    }
  }

  void _onTap() {
    if (_isWatching && !_wasCaught) {
      _onCaught();
    } else if (!_isWatching) {
      _onMoveInput();
    }
  }

  void _onCaught() async {
    if (_wasCaught) return;
    _wasCaught = true;

    _flashController.value = 0.0;
    await _flashController.forward();

    await _shakeController.forward(from: 0);
    _shakeController.reset();

    if (!mounted) return;
    final state =
        context.read<GameState>(); // ignore: use_build_context_synchronously
    state.loseLife();
    setState(() {
      _playerProgress = max(0, _playerProgress - _stepSize * 3);
      _wasCaught = false;
    });

    if (state.lives <= 0) {
      Future.delayed(const Duration(milliseconds: 600), _onLose);
    }
  }

  void _onWin() {
    _stateTimer?.cancel();
    context.read<GameState>().completeWorld(WorldId.tiger);
    context.read<GameState>().addCoins(10);
    VictoryPopup.show(context, didWin: true, coinsEarned: 10, worldName: 'Tiger Forest');
  }

  void _onLose() {
    _stateTimer?.cancel();
    VictoryPopup.show(context, didWin: false, worldName: 'Tiger Forest');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final size = MediaQuery.of(context).size;

    final tigerEmoji = switch (_tigerState) {
      _TigerState.lookingAway => '🐯',
      _TigerState.turningAround => '😤',
      _TigerState.lookingAtYou => '😤',
      _TigerState.turningAway => '😌',
    };

    return Scaffold(
      body: GestureDetector(
        onTap: _onTap,
        child: AnimatedWorldBackground(
          theme: BackgroundTheme.grassland,
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                    top: 12, left: 16, child: LivesHud(lives: state.lives)),
                const BackToMenuButton(),
                Positioned(
                  top: 56,
                  left: 0,
                  right: 0,
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
                          shadows: const [
                            Shadow(blurRadius: 8, color: Colors.black38)
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 32,
                  top: size.height * 0.28,
                  child: AnimatedBuilder(
                    animation: _tigerScaleAnim,
                    builder: (context, _) {
                      final fontSize = _tigerScaleAnim.value;
                      final showGlow = _tigerState == _TigerState.lookingAtYou;
                      return Container(
                        decoration: showGlow
                            ? BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.7),
                                    blurRadius: 20,
                                    spreadRadius: 6,
                                  )
                                ],
                              )
                            : null,
                        child: Text(tigerEmoji,
                            style: TextStyle(fontSize: fontSize)),
                      );
                    },
                  ),
                ),
                Positioned(
                  right: 24,
                  top: size.height * 0.24,
                  child: Container(
                    width: 4,
                    height: 80,
                    color: Colors.yellow.withValues(alpha: 0.7),
                  ),
                ),
                AnimatedBuilder(
                  animation: Listenable.merge([_shakeAnim, _bobController]),
                  builder: (context, _) {
                    final playerX = 40 + _playerProgress * (size.width - 130);
                    final bob = sin(_bobController.value * 8) * 6;
                    return Positioned(
                      left: playerX + _shakeAnim.value - 24,
                      top: size.height * 0.30 + bob,
                      child: Text(
                        _wasCaught ? '😱' : context.read<GameState>().selectedCharacter?.emoji ?? '🏃',
                        style: const TextStyle(fontSize: 48),
                      ),
                    );
                  },
                ),
                Positioned(
                  bottom: 120,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Progress',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _playerProgress,
                          minHeight: 12,
                          backgroundColor: Colors.white24,
                          valueColor:
                              const AlwaysStoppedAnimation(Color(0xFF76FF03)),
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.isMultiplayer)
                  MultiplayerScoreboard(
                    session: state.multiplayerSession!,
                    worldId: WorldId.tiger,
                  ),
                VirtualControls(
                  onMove: (dir) {
                    if (dir.dx > 0.3) {
                      _onMoveInput();
                    }
                  },
                  onRelease: () {},
                  showJump: false,
                ),
                Positioned(
                  bottom: 160,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'Tap or use joystick to move →',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _flashAnim,
                  builder: (context, _) => _flashAnim.value > 0
                      ? Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              color: Colors.red
                                  .withValues(alpha: _flashAnim.value),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
