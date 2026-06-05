import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/debt/domain/debt_filters.dart';

void main() {
  // ────────────────────────────────────────────────────
  // apiValue
  // ────────────────────────────────────────────────────
  group('DebtListFilter.apiValue', () {
    test('all → "all"', () => expect(DebtListFilter.all.apiValue, 'all'));
    test('active → "active"', () => expect(DebtListFilter.active.apiValue, 'active'));
    test('lent → "lent"', () => expect(DebtListFilter.lent.apiValue, 'lent'));
    test('borrowed → "borrowed"',
        () => expect(DebtListFilter.borrowed.apiValue, 'borrowed'));
    test('settled → "settled"',
        () => expect(DebtListFilter.settled.apiValue, 'settled'));
  });

  // ────────────────────────────────────────────────────
  // uiLabel
  // ────────────────────────────────────────────────────
  group('DebtListFilter.uiLabel', () {
    test('all → "All"', () => expect(DebtListFilter.all.uiLabel, 'All'));
    test('active → "Active"', () => expect(DebtListFilter.active.uiLabel, 'Active'));
    test('lent → "Lent"', () => expect(DebtListFilter.lent.uiLabel, 'Lent'));
    test('borrowed → "Borrowed"',
        () => expect(DebtListFilter.borrowed.uiLabel, 'Borrowed'));
    test('settled → "Settled"',
        () => expect(DebtListFilter.settled.uiLabel, 'Settled'));
  });

  // ────────────────────────────────────────────────────
  // toQueryParameters
  // ────────────────────────────────────────────────────
  group('DebtListFilter.toQueryParameters', () {
    test('all returns empty map (no filter param)', () {
      expect(DebtListFilter.all.toQueryParameters(), isEmpty);
    });

    test('lent returns {filter: lent}', () {
      expect(DebtListFilter.lent.toQueryParameters(), {'filter': 'lent'});
    });

    test('borrowed returns {filter: borrowed}', () {
      expect(
        DebtListFilter.borrowed.toQueryParameters(),
        {'filter': 'borrowed'},
      );
    });

    test('settled returns {filter: settled}', () {
      expect(DebtListFilter.settled.toQueryParameters(), {'filter': 'settled'});
    });

    test('active returns {filter: active}', () {
      expect(DebtListFilter.active.toQueryParameters(), {'filter': 'active'});
    });
  });

  // ────────────────────────────────────────────────────
  // fromApiValue
  // ────────────────────────────────────────────────────
  group('DebtListFilterX.fromApiValue', () {
    test('"all" → DebtListFilter.all', () {
      expect(DebtListFilterX.fromApiValue('all'), DebtListFilter.all);
    });

    test('"active" → DebtListFilter.active', () {
      expect(DebtListFilterX.fromApiValue('active'), DebtListFilter.active);
    });

    test('"lent" → DebtListFilter.lent', () {
      expect(DebtListFilterX.fromApiValue('lent'), DebtListFilter.lent);
    });

    test('"borrowed" → DebtListFilter.borrowed', () {
      expect(DebtListFilterX.fromApiValue('borrowed'), DebtListFilter.borrowed);
    });

    test('"settled" → DebtListFilter.settled', () {
      expect(DebtListFilterX.fromApiValue('settled'), DebtListFilter.settled);
    });

    test('unknown value defaults to DebtListFilter.all', () {
      expect(DebtListFilterX.fromApiValue('unknown'), DebtListFilter.all);
    });

    test('case-insensitive: "LENT" → DebtListFilter.lent', () {
      expect(DebtListFilterX.fromApiValue('LENT'), DebtListFilter.lent);
    });

    test('empty string defaults to all', () {
      expect(DebtListFilterX.fromApiValue(''), DebtListFilter.all);
    });
  });

  // ────────────────────────────────────────────────────
  // fromUiLabel
  // ────────────────────────────────────────────────────
  group('DebtListFilterX.fromUiLabel', () {
    test('"All" → DebtListFilter.all', () {
      expect(DebtListFilterX.fromUiLabel('All'), DebtListFilter.all);
    });

    test('"Active" → DebtListFilter.active', () {
      expect(DebtListFilterX.fromUiLabel('Active'), DebtListFilter.active);
    });

    test('"Lent" → DebtListFilter.lent', () {
      expect(DebtListFilterX.fromUiLabel('Lent'), DebtListFilter.lent);
    });

    test('"Borrowed" → DebtListFilter.borrowed', () {
      expect(DebtListFilterX.fromUiLabel('Borrowed'), DebtListFilter.borrowed);
    });

    test('"Settled" → DebtListFilter.settled', () {
      expect(DebtListFilterX.fromUiLabel('Settled'), DebtListFilter.settled);
    });

    test('unknown label defaults to all', () {
      expect(DebtListFilterX.fromUiLabel('Nonsense'), DebtListFilter.all);
    });

    test('trims whitespace: " Lent " → lent', () {
      expect(DebtListFilterX.fromUiLabel(' Lent '), DebtListFilter.lent);
    });

    test('empty string defaults to all', () {
      expect(DebtListFilterX.fromUiLabel(''), DebtListFilter.all);
    });
  });

  // ────────────────────────────────────────────────────
  // Round-trip: uiLabel → fromUiLabel
  // ────────────────────────────────────────────────────
  group('DebtListFilter round-trips', () {
    for (final filter in DebtListFilter.values) {
      test('${filter.name} round-trips via uiLabel', () {
        final label = filter.uiLabel;
        expect(DebtListFilterX.fromUiLabel(label), filter);
      });

      test('${filter.name} round-trips via apiValue', () {
        final api = filter.apiValue;
        expect(DebtListFilterX.fromApiValue(api), filter);
      });
    }
  });
}
