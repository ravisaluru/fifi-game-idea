import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'models/game_state.dart';
import 'screens/home_screen.dart';
import 'screens/character_select_screen.dart';
import 'screens/multiplayer_menu_screen.dart';
import 'screens/ai_setup_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/world_select_screen.dart';
import 'worlds/tiger_world.dart';
import 'worlds/firefly_world.dart';
import 'worlds/bubble_world.dart';
import 'worlds/stepping_stones_world.dart';
import 'worlds/star_catcher_world.dart';
import 'worlds/snake_chase_world.dart';
import 'worlds/treasure_hunt_world.dart';

// NOTE: Add your Firebase config files before running:
//   Android: android/app/google-services.json
//   iOS:     ios/Runner/GoogleService-Info.plist
// Then run: flutterfire configure
// See: https://firebase.google.com/docs/flutter/setup

bool _firebaseAvailable = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  try {
    await Firebase.initializeApp();
    _firebaseAvailable = true;
  } catch (_) {
    // Firebase not configured yet — online play will be unavailable,
    // but solo and AI multiplayer work fully without it.
    _firebaseAvailable = false;
  }

  runApp(FifiApp(firebaseAvailable: _firebaseAvailable));
}

class FifiApp extends StatelessWidget {
  final bool firebaseAvailable;
  const FifiApp({super.key, required this.firebaseAvailable});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameState(),
      child: MaterialApp(
        title: "Fifi's World Adventures",
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7B1FA2)),
          fontFamily: 'FifiRounded',
          useMaterial3: true,
        ),
        builder: (context, child) {
          if (child == null) return const SizedBox.shrink();
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            body: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 500) {
                  const targetWidth = 480.0;
                  final targetHeight = constraints.maxHeight - 48.0;
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7B1FA2).withValues(alpha: 0.35),
                              blurRadius: 40,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                            width: 2.0,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: SizedBox(
                            width: targetWidth,
                            height: targetHeight,
                            child: MediaQuery(
                              data: MediaQuery.of(context).copyWith(
                                size: Size(targetWidth, targetHeight),
                              ),
                              child: child,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return child;
              },
            ),
          );
        },
        initialRoute: '/',
        routes: {
          '/': (_) => const HomeScreen(),
          '/character': (_) => const CharacterSelectScreen(),
          '/multiplayer': (_) => const MultiplayerMenuScreen(),
          '/ai-setup': (_) => const AiSetupScreen(),
          '/lobby': (_) => LobbyScreen(firebaseAvailable: firebaseAvailable),
          '/world-select': (_) => const WorldSelectScreen(),
          '/world/tiger': (_) => const TigerWorldScreen(),
          '/world/firefly': (_) => const FireflyWorldScreen(),
          '/world/bubble': (_) => const BubbleWorldScreen(),
          '/world/stones': (_) => const SteppingStonesScreen(),
          '/world/star': (_) => const StarCatcherScreen(),
          '/world/snake': (_) => const SnakeChaseScreen(),
          '/world/treasure': (_) => const TreasureHuntScreen(),
        },
      ),
    );
  }
}
