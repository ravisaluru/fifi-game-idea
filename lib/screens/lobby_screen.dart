import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/game_state.dart';
import '../models/character.dart';
import '../services/multiplayer_service.dart';
import '../widgets/animated_world_background.dart';

enum _LobbyMode { choose, create, join }

class LobbyScreen extends StatefulWidget {
  final bool firebaseAvailable;
  const LobbyScreen({super.key, this.firebaseAvailable = false});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  _LobbyMode _mode = _LobbyMode.choose;
  final TextEditingController _codeController = TextEditingController();
  String? _myRoomCode;
  String? _error;
  bool _loading = false;
  StreamSubscription? _roomSub;
  List<Map<String, dynamic>> _waitingPlayers = [];
  bool _gameStarted = false;

  final String _myPlayerId = const Uuid().v4();

  @override
  void dispose() {
    _codeController.dispose();
    _roomSub?.cancel();
    super.dispose();
  }

  Future<void> _createRoom() async {
    final state = context.read<GameState>();
    final char = state.selectedCharacter ?? availableCharacters[0];
    final player = SessionPlayer(
      id: _myPlayerId,
      name: char.displayName,
      character: char,
      isLocal: true,
    );

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final worldId = state.lastWorld ?? WorldId.tiger;
      final code =
          await MultiplayerService.instance.createRoom(player, worldId);
      setState(() {
        _myRoomCode = code;
        _loading = false;
      });
      _watchRoom(code);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 4) {
      setState(() => _error = 'Enter a 4-letter room code');
      return;
    }

    final state = context.read<GameState>();
    final char = state.selectedCharacter ?? availableCharacters[0];
    final player = SessionPlayer(
      id: _myPlayerId,
      name: char.displayName,
      character: char,
      isLocal: true,
    );

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await MultiplayerService.instance.joinRoom(code, player);
      setState(() {
        _myRoomCode = code;
        _loading = false;
      });
      _watchRoom(code);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _watchRoom(String code) {
    _roomSub?.cancel();
    _roomSub = MultiplayerService.instance.watchRoom(code).listen((data) {
      if (!mounted || data.isEmpty) return;
      final rawPlayers = (data['players'] as Map<dynamic, dynamic>?) ?? {};
      setState(() {
        _waitingPlayers = rawPlayers.entries
            .map((e) => Map<String, dynamic>.from(e.value as Map))
            .toList();
      });

      if (data['status'] == 'playing' && !_gameStarted) {
        _gameStarted = true;
        _enterGame(data, code);
      }
    });
  }

  void _enterGame(Map<String, dynamic> data, String code) {
    final session = sessionFromSnapshot(data, code, _myPlayerId);
    final state = context.read<GameState>();
    state.setMultiplayerSession(session);
    Navigator.pushReplacementNamed(
        context, '/world/${session.worldId?.name ?? 'tiger'}');
  }

  Future<void> _startGame() async {
    if (_myRoomCode == null) return;
    // Host picks the next world and starts
    final worldId = context.read<GameState>().pickNextWorld();
    await MultiplayerService.instance
        .roomRef(_myRoomCode!)
        .update({'worldId': worldId.name});
    await MultiplayerService.instance.startGame(_myRoomCode!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedWorldBackground(
        theme: BackgroundTheme.night,
        child: SafeArea(
          child: !widget.firebaseAvailable
              ? _FirebaseNotConfigured(onBack: () => Navigator.pop(context))
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: switch (_mode) {
                    _LobbyMode.choose => _ChooseView(
                        onCreate: () =>
                            setState(() => _mode = _LobbyMode.create),
                        onJoin: () => setState(() => _mode = _LobbyMode.join),
                        onBack: () => Navigator.pop(context),
                      ),
                    _LobbyMode.create => _myRoomCode == null
                        ? _CreateView(
                            loading: _loading,
                            error: _error,
                            onCreate: _createRoom,
                            onBack: () =>
                                setState(() => _mode = _LobbyMode.choose),
                          )
                        : _WaitingRoom(
                            code: _myRoomCode!,
                            players: _waitingPlayers,
                            isHost: true,
                            onStart: _startGame,
                            onLeave: () {
                              _roomSub?.cancel();
                              setState(() {
                                _myRoomCode = null;
                                _mode = _LobbyMode.choose;
                              });
                            },
                          ),
                    _LobbyMode.join => _myRoomCode == null
                        ? _JoinView(
                            controller: _codeController,
                            loading: _loading,
                            error: _error,
                            onJoin: _joinRoom,
                            onBack: () =>
                                setState(() => _mode = _LobbyMode.choose),
                          )
                        : _WaitingRoom(
                            code: _myRoomCode!,
                            players: _waitingPlayers,
                            isHost: false,
                            onLeave: () {
                              _roomSub?.cancel();
                              MultiplayerService.instance
                                  .leaveRoom(_myRoomCode!, _myPlayerId);
                              setState(() {
                                _myRoomCode = null;
                                _mode = _LobbyMode.choose;
                              });
                            },
                          ),
                  },
                ),
        ),
      ),
    );
  }
}

// ── Sub-views ────────────────────────────────────────────────────────────────

class _FirebaseNotConfigured extends StatelessWidget {
  final VoidCallback onBack;
  const _FirebaseNotConfigured({required this.onBack});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔧', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('Online Play Not Set Up',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'To enable online play, add your Firebase config files:\n\n'
              '• Android: android/app/google-services.json\n'
              '• iOS: ios/Runner/GoogleService-Info.plist\n\n'
              'Then run: flutterfire configure',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: onBack,
              child: const Text('← Back',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
            ),
          ],
        ),
      );
}

class _ChooseView extends StatelessWidget {
  final VoidCallback onCreate, onJoin, onBack;
  const _ChooseView(
      {required this.onCreate, required this.onJoin, required this.onBack});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Online Play 🌐',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 48),
          _LobbyButton(
              label: 'Create Room 🏠',
              onTap: onCreate,
              color: const Color(0xFF1565C0)),
          const SizedBox(height: 16),
          _LobbyButton(
              label: 'Join Room 🚪',
              onTap: onJoin,
              color: const Color(0xFF6A1B9A)),
          const SizedBox(height: 32),
          TextButton(
              onPressed: onBack,
              child: const Text('← Back',
                  style: TextStyle(color: Colors.white70, fontSize: 16))),
        ],
      );
}

class _CreateView extends StatelessWidget {
  final bool loading;
  final String? error;
  final VoidCallback onCreate, onBack;
  const _CreateView(
      {required this.loading,
      required this.error,
      required this.onCreate,
      required this.onBack});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Create a Room',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('A code will appear for you to share',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 48),
          if (loading) const CircularProgressIndicator(color: Colors.white),
          if (error != null)
            Padding(
                padding: const EdgeInsets.all(12),
                child: Text(error!,
                    style: const TextStyle(color: Colors.redAccent))),
          if (!loading)
            _LobbyButton(
                label: 'Generate Code 🎲',
                onTap: onCreate,
                color: const Color(0xFF1565C0)),
          const SizedBox(height: 16),
          TextButton(
              onPressed: onBack,
              child: const Text('← Back',
                  style: TextStyle(color: Colors.white70))),
        ],
      );
}

class _JoinView extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final String? error;
  final VoidCallback onJoin, onBack;
  const _JoinView(
      {required this.controller,
      required this.loading,
      required this.error,
      required this.onJoin,
      required this.onBack});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Join a Room',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Ask a friend for their 4-letter code',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 40),
            TextField(
              controller: controller,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              maxLength: 4,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 12),
              decoration: InputDecoration(
                counterText: '',
                hintText: '????',
                hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 36,
                    letterSpacing: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.white38, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.white, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (loading) const CircularProgressIndicator(color: Colors.white),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.redAccent)),
            if (!loading)
              _LobbyButton(
                  label: 'Join! 🚀',
                  onTap: onJoin,
                  color: const Color(0xFF6A1B9A)),
            const SizedBox(height: 16),
            TextButton(
                onPressed: onBack,
                child: const Text('← Back',
                    style: TextStyle(color: Colors.white70))),
          ],
        ),
      );
}

class _WaitingRoom extends StatelessWidget {
  final String code;
  final List<Map<String, dynamic>> players;
  final bool isHost;
  final VoidCallback? onStart;
  final VoidCallback onLeave;

  const _WaitingRoom({
    required this.code,
    required this.players,
    required this.isHost,
    this.onStart,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Waiting Room',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          // Room code display
          GestureDetector(
            onTap: () => Clipboard.setData(ClipboardData(text: code)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white38, width: 2),
              ),
              child: Column(
                children: [
                  const Text('Room Code',
                      style: TextStyle(color: Colors.white60, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(code,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 12)),
                  const Text('Tap to copy',
                      style: TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Players list
          ...players.map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('👤', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(p['name'] as String? ?? 'Player',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              )),

          if (players.length < 2)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text('Waiting for more players...',
                  style: TextStyle(color: Colors.white54, fontSize: 14)),
            ),

          const SizedBox(height: 40),

          if (isHost && players.length >= 2)
            _LobbyButton(
              label: 'Start Game! 🎮',
              onTap: onStart ?? () {},
              color: const Color(0xFF2E7D32),
            ),

          if (!isHost)
            const Text('Waiting for host to start...',
                style: TextStyle(color: Colors.white70, fontSize: 15)),

          const SizedBox(height: 16),
          TextButton(
            onPressed: onLeave,
            child: const Text('Leave Room',
                style: TextStyle(color: Colors.redAccent, fontSize: 15)),
          ),
        ],
      );
}

class _LobbyButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _LobbyButton(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 260,
          height: 58,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(29),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 5))
            ],
          ),
          child: Center(
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      );
}
