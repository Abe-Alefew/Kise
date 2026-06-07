import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kise/core/widgets/kise_form_system/kise_text_field.dart';

Widget _wrap(KiseTextField field) => MaterialApp(
      theme: ThemeData.light(),
      home: Scaffold(
        body: Form(child: field),
      ),
    );

void main() {
  group('KiseTextField', () {
    // ── Rendering ──────────────────────────────────────────────────
    group('rendering', () {
      testWidgets('renders a TextFormField', (tester) async {
        final ctrl = TextEditingController();
        await tester.pumpWidget(_wrap(KiseTextField(label: 'Email', controller: ctrl)));
        expect(find.byType(TextFormField), findsOneWidget);
      });

      testWidgets('shows label text', (tester) async {
        final ctrl = TextEditingController();
        await tester.pumpWidget(_wrap(KiseTextField(label: 'Password', controller: ctrl)));
        expect(find.text('Password'), findsOneWidget);
      });

      testWidgets('stores hint on widget property', (tester) async {
        final ctrl = TextEditingController();
        await tester.pumpWidget(_wrap(KiseTextField(
          label: 'Email',
          controller: ctrl,
          hint: 'Enter your email',
        )));
        final widget =
            tester.widget<KiseTextField>(find.byType(KiseTextField));
        expect(widget.hint, 'Enter your email');
      });

      testWidgets('shows prefix icon when provided', (tester) async {
        final ctrl = TextEditingController();
        await tester.pumpWidget(_wrap(KiseTextField(
          label: 'Search',
          controller: ctrl,
          icon: Icons.search,
        )));
        expect(find.byIcon(Icons.search), findsOneWidget);
      });

      testWidgets('no prefix icon when icon is null', (tester) async {
        final ctrl = TextEditingController();
        await tester.pumpWidget(_wrap(KiseTextField(label: 'Name', controller: ctrl)));
        expect(find.byType(Icon), findsNothing);
      });
    });

    // ── Password / obscure ─────────────────────────────────────────
    group('password mode', () {
      testWidgets('isPassword=true stores on widget property', (tester) async {
        final ctrl = TextEditingController();
        await tester.pumpWidget(_wrap(KiseTextField(
          label: 'Password',
          controller: ctrl,
          isPassword: true,
        )));
        final w = tester.widget<KiseTextField>(find.byType(KiseTextField));
        expect(w.isPassword, isTrue);
      });

      testWidgets('isPassword defaults to false', (tester) async {
        final ctrl = TextEditingController();
        await tester.pumpWidget(_wrap(KiseTextField(label: 'Name', controller: ctrl)));
        final w = tester.widget<KiseTextField>(find.byType(KiseTextField));
        expect(w.isPassword, isFalse);
      });

      testWidgets('isPassword=true causes underlying EditableText to obscure text',
          (tester) async {
        final ctrl = TextEditingController();
        await tester.pumpWidget(_wrap(KiseTextField(
          label: 'Password',
          controller: ctrl,
          isPassword: true,
        )));
        final editable =
            tester.widget<EditableText>(find.byType(EditableText));
        expect(editable.obscureText, isTrue);
      });
    });

    // ── Keyboard type ──────────────────────────────────────────────
    group('keyboardType', () {
      testWidgets('defaults to TextInputType.text', (tester) async {
        final ctrl = TextEditingController();
        await tester.pumpWidget(_wrap(KiseTextField(label: 'x', controller: ctrl)));
        final w = tester.widget<KiseTextField>(find.byType(KiseTextField));
        expect(w.keyboardType, TextInputType.text);
      });

      testWidgets('stores emailAddress keyboard type on widget', (tester) async {
        final ctrl = TextEditingController();
        await tester.pumpWidget(_wrap(KiseTextField(
          label: 'Email',
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
        )));
        final w = tester.widget<KiseTextField>(find.byType(KiseTextField));
        expect(w.keyboardType, TextInputType.emailAddress);
      });

      testWidgets('emailAddress type is reflected in EditableText', (tester) async {
        final ctrl = TextEditingController();
        await tester.pumpWidget(_wrap(KiseTextField(
          label: 'Email',
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
        )));
        final editable =
            tester.widget<EditableText>(find.byType(EditableText));
        expect(editable.keyboardType, TextInputType.emailAddress);
      });
    });

    // ── Text input ─────────────────────────────────────────────────
    group('text input', () {
      testWidgets('updates controller value when text is entered', (tester) async {
        final ctrl = TextEditingController();
        await tester.pumpWidget(_wrap(KiseTextField(label: 'Name', controller: ctrl)));
        await tester.enterText(find.byType(TextFormField), 'Abel');
        expect(ctrl.text, 'Abel');
      });
    });

    // ── Validation ─────────────────────────────────────────────────
    group('validator', () {
      testWidgets('calls validator and shows error text on failure',
          (tester) async {
        final formKey = GlobalKey<FormState>();
        final ctrl = TextEditingController();
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Form(
              key: formKey,
              child: KiseTextField(
                label: 'Email',
                controller: ctrl,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ),
          ),
        ));

        formKey.currentState?.validate();
        await tester.pump();
        expect(find.text('Required'), findsOneWidget);
      });

      testWidgets('no error text when validator passes', (tester) async {
        final formKey = GlobalKey<FormState>();
        final ctrl = TextEditingController(text: 'hello');
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Form(
              key: formKey,
              child: KiseTextField(
                label: 'Name',
                controller: ctrl,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ),
          ),
        ));

        formKey.currentState?.validate();
        await tester.pump();
        expect(find.text('Required'), findsNothing);
      });
    });

    // ── Dark theme ─────────────────────────────────────────────────
    testWidgets('renders under dark theme without error', (tester) async {
      final ctrl = TextEditingController();
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Form(
            child: KiseTextField(label: 'Field', controller: ctrl),
          ),
        ),
      ));
      expect(find.byType(KiseTextField), findsOneWidget);
    });
  });
}
