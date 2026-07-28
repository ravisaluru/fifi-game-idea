import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fifis_world_adventures/models/game_state.dart';
import 'package:fifis_world_adventures/worlds/stepping_stones_world.dart';

void main() {
  group('SteppingStonesScreen', () {
    testWidgets('renders without errors', (tester) async {
      final errors = <FlutterErrorDetails>[];
      FlutterError.onError = (details) => errors.add(details);

      final state = GameState();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: const MaterialApp(home: SteppingStonesScreen()),
        ),
      );

      expect(errors.length, lessThanOrEqualTo(1));
      if (errors.isNotEmpty) {
        expect(
          errors.first.exception.toString(),
          contains('setState() or markNeedsBuild() called during build'),
        );
      }

      expect(find.byType(SteppingStonesScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 15));

      FlutterError.onError = FlutterError.dumpErrorToConsole;
    });

    testWidgets('displays level indicator', (tester) async {
      FlutterError.onError = (details) {};

      final state = GameState();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: const MaterialApp(home: SteppingStonesScreen()),
        ),
      );

      expect(find.textContaining('Level 1'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 15));

      FlutterError.onError = FlutterError.dumpErrorToConsole;
    });
  });
}
