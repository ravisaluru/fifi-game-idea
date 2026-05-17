import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'models/game_state.dart';
import 'screens/home_screen.dart';
import 'screens/character_select_screen.dart';
import 'screens/victory_screen.dart';
import 'worlds/tiger_world.dart';
import 'worlds/firefly_world.dart';
import 'worlds/bubble_world.dart';
import 'worlds/stepping_stones_world.dart';
import 'worlds/star_catcher_world.dart';
import 'worlds/snake_chase_world.dart';
import 'worlds/treasure_hunt_world.dart';

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
  runApp(const FifiApp());
}

class FifiApp extends StatelessWidget {
  const FifiApp({super.key});

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
        initialRoute: '/',
        routes: {
          '/':          (_) => const HomeScreen(),
          '/character': (_) => const CharacterSelectScreen(),
          '/victory':   (_) => const VictoryScreen(),
          '/world/tiger':   (_) => const TigerWorldScreen(),
          '/world/firefly': (_) => const FireflyWorldScreen(),
          '/world/bubble':  (_) => const BubbleWorldScreen(),
          '/world/stones':  (_) => const SteppingStonesScreen(),
          '/world/star':    (_) => const StarCatcherScreen(),
          '/world/snake':   (_) => const SnakeChaseScreen(),
          '/world/treasure':(_) => const TreasureHuntScreen(),
        },
      ),
    );
  }
}
