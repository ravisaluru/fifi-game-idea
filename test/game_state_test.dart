import 'package:flutter_test/flutter_test.dart';
import 'package:fifis_world_adventures/models/game_state.dart';

void main() {
  group('GameState', () {
    late GameState state;

    setUp(() => state = GameState());

    test('starts with 3 lives', () => expect(state.lives, 3));

    test('loseLife decrements lives', () {
      state.loseLife();
      expect(state.lives, 2);
    });

    test('loseLife does not go below 0', () {
      state.loseLife();
      state.loseLife();
      state.loseLife();
      state.loseLife();
      expect(state.lives, 0);
    });

    test('resetForWorld restores 3 lives', () {
      state.loseLife();
      state.loseLife();
      state.resetForWorld();
      expect(state.lives, 3);
    });

    test('pickNextWorld never returns same world twice in a row', () {
      for (int i = 0; i < 20; i++) {
        final first = state.pickNextWorld();
        final second = state.pickNextWorld();
        expect(first, isNot(equals(second)));
      }
    });

    test('addCoins accumulates', () {
      state.addCoins(3);
      state.addCoins(5);
      expect(state.totalCoins, 8);
    });

    test('completeWorld increments counter', () {
      state.completeWorld(WorldId.tiger);
      state.completeWorld(WorldId.bubble);
      expect(state.worldsCompleted, 2);
    });

    test('completeWorld tracks completed worlds set', () {
      state.completeWorld(WorldId.tiger);
      expect(state.completedWorlds, contains(WorldId.tiger));
      expect(state.completedWorlds, hasLength(1));
    });

    test('completeWorld does not double-count same world', () {
      state.completeWorld(WorldId.tiger);
      state.completeWorld(WorldId.tiger);
      expect(state.worldsCompleted, 1);
      expect(state.completedWorlds, hasLength(1));
    });
  });
}
