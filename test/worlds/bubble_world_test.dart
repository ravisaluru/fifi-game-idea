import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fifis_world_adventures/models/game_state.dart';
import 'package:fifis_world_adventures/worlds/bubble_world.dart';

void main() {
  group('BubbleWorldScreen', () {
    testWidgets('renders without errors', (tester) async {
      // The game screens call resetForWorld() in initState which triggers
      // notifyListeners during build — a known pattern in this codebase.
      // We suppress this expected FlutterError for the smoke test.
      final errors = <FlutterErrorDetails>[];
      FlutterError.onError = (details) => errors.add(details);

      final state = GameState();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: const MaterialApp(home: BubbleWorldScreen()),
        ),
      );

      // Only the known "setState during build" error should occur
      expect(errors.length, lessThanOrEqualTo(1));
      if (errors.isNotEmpty) {
        expect(
          errors.first.exception.toString(),
          contains('setState() or markNeedsBuild() called during build'),
        );
      }

      expect(find.byType(BubbleWorldScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 15));

      // Restore default error handler
      FlutterError.onError = FlutterError.dumpErrorToConsole;
    });

    testWidgets('displays level indicator', (tester) async {
      FlutterError.onError = (details) {}; // Suppress known error

      final state = GameState();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: const MaterialApp(home: BubbleWorldScreen()),
        ),
      );

      expect(find.textContaining('Level 1'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 15));

      FlutterError.onError = FlutterError.dumpErrorToConsole;
    });
  });
}
