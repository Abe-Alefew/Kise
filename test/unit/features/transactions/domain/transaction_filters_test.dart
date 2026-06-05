import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/transactions/domain/transaction_filters.dart';

void main() {
  // ────────────────────────────────────────────────────
  // Defaults
  // ────────────────────────────────────────────────────
  group('TransactionQueryFilter defaults', () {
    const filter = TransactionQueryFilter();

    test('type is null by default', () => expect(filter.type, isNull));
    test('category is null', () => expect(filter.category, isNull));
    test('from is null', () => expect(filter.from, isNull));
    test('to is null', () => expect(filter.to, isNull));
    test('searchQuery is null', () => expect(filter.searchQuery, isNull));
    test('sort defaults to date_desc', () => expect(filter.sort, 'date_desc'));
    test('page defaults to 1', () => expect(filter.page, 1));
    test('limit defaults to 50', () => expect(filter.limit, 50));
    test('offset defaults to 0', () => expect(filter.offset, 0));
  });

  // ────────────────────────────────────────────────────
  // copyWith sentinel pattern
  // ────────────────────────────────────────────────────
  group('TransactionQueryFilter.copyWith sentinel pattern', () {
    const base = TransactionQueryFilter(type: 'income', category: 'Salary');

    test('copyWith with no args preserves all fields', () {
      final copy = base.copyWith();
      expect(copy.type, 'income');
      expect(copy.category, 'Salary');
    });

    test('copyWith can change type while keeping category', () {
      final copy = base.copyWith(type: 'expense');
      expect(copy.type, 'expense');
      expect(copy.category, 'Salary');
    });

    test('copyWith can explicitly null out type', () {
      final copy = base.copyWith(type: null);
      expect(copy.type, isNull);
      expect(copy.category, 'Salary');
    });

    test('copyWith can explicitly null out category', () {
      final copy = base.copyWith(category: null);
      expect(copy.category, isNull);
      expect(copy.type, 'income');
    });

    test('copyWith can update sort and page together', () {
      const f = TransactionQueryFilter();
      final copy = f.copyWith(sort: 'date_asc', page: 2);
      expect(copy.sort, 'date_asc');
      expect(copy.page, 2);
    });

    test('copyWith can set searchQuery', () {
      const f = TransactionQueryFilter();
      final copy = f.copyWith(searchQuery: 'coffee');
      expect(copy.searchQuery, 'coffee');
    });

    test('copyWith can null out searchQuery', () {
      const f = TransactionQueryFilter(searchQuery: 'coffee');
      final copy = f.copyWith(searchQuery: null);
      expect(copy.searchQuery, isNull);
    });
  });

  // ────────────────────────────────────────────────────
  // toQueryParameters
  // ────────────────────────────────────────────────────
  group('TransactionQueryFilter.toQueryParameters', () {
    test('default filter includes sort, page, limit', () {
      const f = TransactionQueryFilter();
      final params = f.toQueryParameters();
      expect(params['sort'], 'date_desc');
      expect(params['page'], 1);
      expect(params['limit'], 50);
    });

    test('type=null is NOT included in params', () {
      const f = TransactionQueryFilter();
      expect(f.toQueryParameters().containsKey('type'), isFalse);
    });

    test('type="All" is NOT included in params', () {
      const f = TransactionQueryFilter(type: 'All');
      expect(f.toQueryParameters().containsKey('type'), isFalse);
    });

    test('type="income" IS included in params', () {
      const f = TransactionQueryFilter(type: 'income');
      expect(f.toQueryParameters()['type'], 'income');
    });

    test('category is included when set', () {
      const f = TransactionQueryFilter(category: 'Food');
      expect(f.toQueryParameters()['category'], 'Food');
    });

    test('category is omitted when null', () {
      const f = TransactionQueryFilter();
      expect(f.toQueryParameters().containsKey('category'), isFalse);
    });

    test('searchQuery trims and includes as "q"', () {
      const f = TransactionQueryFilter(searchQuery: '  coffee  ');
      expect(f.toQueryParameters()['q'], 'coffee');
    });

    test('empty searchQuery is omitted', () {
      const f = TransactionQueryFilter(searchQuery: '   ');
      expect(f.toQueryParameters().containsKey('q'), isFalse);
    });

    test('from and to are included when set', () {
      const f =
          TransactionQueryFilter(from: '2025-01-01', to: '2025-06-30');
      final params = f.toQueryParameters();
      expect(params['from'], '2025-01-01');
      expect(params['to'], '2025-06-30');
    });

    test('offset > 0 computes page from offset÷limit', () {
      // offset=50, limit=50 → page = (50÷50)+1 = 2
      const f = TransactionQueryFilter(offset: 50, limit: 50);
      final params = f.toQueryParameters();
      expect(params['page'], 2);
    });

    test('offset=0 uses the page field directly', () {
      const f = TransactionQueryFilter(page: 3, limit: 50);
      final params = f.toQueryParameters();
      expect(params['page'], 3);
    });
  });
}
