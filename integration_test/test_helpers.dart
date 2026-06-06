import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kise/core/providers/theme_provider.dart';
import 'package:kise/main.dart';

/// Pumps [KiseApp] inside a [ProviderScope] and waits for it to settle.
///
/// Installs a [FlutterError.onError] filter that silently drops google_fonts
/// font-loading errors for the duration of the pump. Those errors are benign
/// in tests: the font just falls back to the system default because
/// [GoogleFonts.config.allowRuntimeFetching] is false and the font is not
/// bundled in assets.
///
/// The filter is installed AFTER [LiveTestWidgetsFlutterBinding.runTest]
/// replaces the handler (that replacement happens before the test body runs),
/// so this is the only reliable place to intercept font errors.
Future<void> pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  Duration settle = const Duration(seconds: 3),
}) async {
  final saved = FlutterError.onError;
  FlutterError.onError = (details) {
    if (_isFontError(details)) return;
    saved?.call(details);
  };
  try {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        initialThemeModeProvider.overrideWithValue(ThemeMode.system),
      ],
      child: const KiseApp(),
    ));
    await tester.pumpAndSettle(settle);
  } finally {
    FlutterError.onError = saved;
  }
}

bool _isFontError(FlutterErrorDetails details) {
  final msg = details.exception.toString();
  return msg.contains('google_fonts') || msg.contains('GoogleFonts');
}
