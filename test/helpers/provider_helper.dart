import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Creates a [ProviderContainer] with optional provider overrides and
/// registers automatic disposal via [addTearDown] so tests never leak.
///
/// Usage:
/// ```dart
/// final container = createContainer(overrides: [
///   someProvider.overrideWith(() => FakeNotifier()),
/// ]);
/// ```
///
/// Note: Riverpod 3.x does not export the `Override` sealed class, so the
/// parameter accepts `List<Object>`. Passing results of `.overrideWith()` /
/// `.overrideWithValue()` calls is always safe at runtime.
ProviderContainer createContainer({
  ProviderContainer? parent,
  List<Object> overrides = const [],
}) {
  final container = ProviderContainer(
    parent: parent,
    // ignore: invalid_use_of_internal_member
    overrides: overrides.cast(),
  );
  addTearDown(container.dispose);
  return container;
}
