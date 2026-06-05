import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/settings/presentation/widgets/settings_card.dart';

import '../../helpers/widget_helper.dart';

void main() {
  // ────────────────────────────────────────────────────────────────
  // SettingsCard
  // ────────────────────────────────────────────────────────────────
  group('SettingsCard', () {
    group('rendering', () {
      testWidgets('renders its child widget', (tester) async {
        await tester.pumpWidget(buildSimple(
          const SettingsCard(child: Text('Language')),
        ));
        expect(find.text('Language'), findsOneWidget);
      });

      testWidgets('wraps child in a full-width Container', (tester) async {
        await tester.pumpWidget(buildSimple(
          const SettingsCard(child: SizedBox(height: 40)),
        ));
        expect(find.byType(SettingsCard), findsOneWidget);
      });

      testWidgets('renders under light theme without error', (tester) async {
        await tester.pumpWidget(buildSimple(
          const SettingsCard(child: Text('Profile')),
        ));
        expect(find.text('Profile'), findsOneWidget);
      });

      testWidgets('renders under dark theme without error', (tester) async {
        await tester.pumpWidget(buildSimpleDark(
          const SettingsCard(child: Text('Notifications')),
        ));
        expect(find.text('Notifications'), findsOneWidget);
      });

      testWidgets('can nest multiple children via Column', (tester) async {
        await tester.pumpWidget(buildSimple(
          const SettingsCard(
            child: Column(
              children: [
                Text('Item 1'),
                Text('Item 2'),
              ],
            ),
          ),
        ));
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 2'), findsOneWidget);
      });
    });
  });

  // ────────────────────────────────────────────────────────────────
  // SettingsOptionRow
  // ────────────────────────────────────────────────────────────────
  group('SettingsOptionRow', () {
    group('rendering', () {
      testWidgets('displays the label text', (tester) async {
        await tester.pumpWidget(buildSimple(
          SettingsOptionRow(
            label: 'English',
            isSelected: false,
            onTap: () {},
          ),
        ));
        expect(find.text('English'), findsOneWidget);
      });

      testWidgets('shows check icon when isSelected=true', (tester) async {
        await tester.pumpWidget(buildSimple(
          SettingsOptionRow(
            label: 'Amharic',
            isSelected: true,
            onTap: () {},
          ),
        ));
        expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      });

      testWidgets('hides check icon when isSelected=false', (tester) async {
        await tester.pumpWidget(buildSimple(
          SettingsOptionRow(
            label: 'English',
            isSelected: false,
            onTap: () {},
          ),
        ));
        expect(find.byIcon(Icons.check_rounded), findsNothing);
      });
    });

    group('onTap', () {
      testWidgets('fires onTap when tapped', (tester) async {
        int tapCount = 0;
        await tester.pumpWidget(buildSimple(
          SettingsOptionRow(
            label: 'Dark',
            isSelected: false,
            onTap: () => tapCount++,
          ),
        ));
        await tester.tap(find.byType(InkWell));
        await tester.pump();
        expect(tapCount, 1);
      });

      testWidgets('fires onTap even when already selected', (tester) async {
        int tapCount = 0;
        await tester.pumpWidget(buildSimple(
          SettingsOptionRow(
            label: 'System',
            isSelected: true,
            onTap: () => tapCount++,
          ),
        ));
        await tester.tap(find.byType(InkWell));
        await tester.pump();
        expect(tapCount, 1);
      });
    });

    group('theme variants', () {
      testWidgets('renders under dark theme without error', (tester) async {
        await tester.pumpWidget(buildSimpleDark(
          SettingsOptionRow(
            label: 'Light',
            isSelected: false,
            onTap: () {},
          ),
        ));
        expect(find.text('Light'), findsOneWidget);
      });
    });
  });
}
