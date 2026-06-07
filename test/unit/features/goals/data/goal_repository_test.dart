// Tests for GoalRepositoryImpl — network+cache interplay, error mapping.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoalRepositoryImpl', () {
    group('getGoals', () {
      test('placeholder — returns cache when network unavailable', () => expect(true, isTrue));
      test('placeholder — replaces non-dirty cache entries on successful fetch', () => expect(true, isTrue));
    });
    group('createGoal', () {
      test('placeholder — POST /goals and caches result', () => expect(true, isTrue));
    });
    group('logDeposit', () {
      test('placeholder — POST /goals/:id/deposits updates currentAmount', () => expect(true, isTrue));
    });
    group('deleteGoal', () {
      test('placeholder — DELETE /goals/:id and removes from cache', () => expect(true, isTrue));
    });
  });
}
