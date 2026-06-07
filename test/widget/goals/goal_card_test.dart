import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kise/core/widgets/kise_card_holder.dart';
import 'package:kise/core/widgets/kise_progress_bar.dart';
import 'package:kise/features/goals/domain/goal_entity.dart';
import 'package:kise/features/goals/presentation/widgets/goal_card.dart';

import '../../helpers/test_data/goal_fixtures.dart';
import '../../helpers/widget_helper.dart';

// Dummy callbacks that satisfy the GoalCard API without triggering anything.
Widget _card(GoalEntity goal) => buildSimple(
      GoalCard(
        goal: goal,
        onDelete: () {},
        onLock: () {},
        onDeposit: (amount, source) {},
        onEdit: (title, target, deadline, period) {},
      ),
    );

Widget _cardDark(GoalEntity goal) => buildSimpleDark(
      GoalCard(
        goal: goal,
        onDelete: () {},
        onLock: () {},
        onDeposit: (amount, source) {},
        onEdit: (title, target, deadline, period) {},
      ),
    );

void main() {
  group('GoalCard', () {
    // ── Rendering ──────────────────────────────────────────────────
    group('rendering', () {
      testWidgets('renders a KiseCardHolder', (tester) async {
        await tester.pumpWidget(_card(activeGoal));
        expect(find.byType(KiseCardHolder), findsOneWidget);
      });

      testWidgets('shows goal title', (tester) async {
        await tester.pumpWidget(_card(activeGoal));
        expect(find.text(activeGoal.title), findsOneWidget);
      });

      testWidgets('shows a KiseProgressBar', (tester) async {
        await tester.pumpWidget(_card(activeGoal));
        expect(find.byType(KiseProgressBar), findsOneWidget);
      });

      testWidgets('renders locked goal without error', (tester) async {
        await tester.pumpWidget(_card(lockedGoal));
        expect(find.byType(GoalCard), findsOneWidget);
      });

      testWidgets('renders completed goal without error', (tester) async {
        await tester.pumpWidget(_card(completedGoal));
        expect(find.byType(GoalCard), findsOneWidget);
      });

      testWidgets('renders canceled goal without error', (tester) async {
        await tester.pumpWidget(_card(canceledGoal));
        expect(find.byType(GoalCard), findsOneWidget);
      });
    });

    // ── Expand / collapse ──────────────────────────────────────────
    group('tap to expand', () {
      testWidgets('tapping the card does not crash', (tester) async {
        await tester.pumpWidget(_card(activeGoal));
        await tester.tap(find.byType(InkWell).first);
        await tester.pumpAndSettle();
        expect(find.byType(GoalCard), findsOneWidget);
      });

      testWidgets('second tap collapses without error', (tester) async {
        await tester.pumpWidget(_card(activeGoal));
        await tester.tap(find.byType(InkWell).first);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(InkWell).first);
        await tester.pumpAndSettle();
        expect(find.byType(GoalCard), findsOneWidget);
      });
    });

    // ── Dark theme ─────────────────────────────────────────────────
    testWidgets('renders under dark theme without error', (tester) async {
      await tester.pumpWidget(_cardDark(activeGoal));
      expect(find.byType(GoalCard), findsOneWidget);
    });
  });
}
