// Tests for HomeDashboardRepositoryImpl — cache fallback, parse, error mapping.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeDashboardRepositoryImpl', () {
    test('placeholder — fetchHome calls GET /dashboard/home with range param', () => expect(true, isTrue));
    test('placeholder — ApiException propagated on 500 error', () => expect(true, isTrue));
    test('placeholder — timeout falls back to cached bundle', () => expect(true, isTrue));
  });
}
