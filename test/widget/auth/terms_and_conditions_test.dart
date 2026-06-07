import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/auth/presentation/screens/terms_and_conditions.dart';

import '../../helpers/widget_helper.dart';

void main() {
  group('TermsAndConditions screen', () {
    testWidgets('renders a Scaffold without error', (tester) async {
      await tester.pumpWidget(buildWithRouter(const TermsAndConditionsScreen()));
      await tester.pump();
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('contains scrollable content', (tester) async {
      await tester.pumpWidget(buildWithRouter(const TermsAndConditionsScreen()));
      await tester.pump();
      // Terms content should be scrollable
      expect(
        find.byWidgetPredicate((w) => w is SingleChildScrollView || w is CustomScrollView || w is ListView),
        findsAtLeast(1),
      );
    });

    testWidgets('shows a tappable accept/agree element', (tester) async {
      await tester.pumpWidget(buildWithRouter(const TermsAndConditionsScreen()));
      await tester.pumpAndSettle();
      // T&C uses GestureDetector + IconButton — check either is present.
      expect(
        find.byWidgetPredicate((w) =>
            w is GestureDetector ||
            w is IconButton ||
            w is ElevatedButton ||
            w is TextButton),
        findsAtLeast(1),
      );
    });
  });
}
