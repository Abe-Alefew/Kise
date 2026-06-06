import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/transactions/data/transaction_icon_mapper.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  // ────────────────────────────────────────────────────
  // TransactionIconMapper.defaultIconKeyForCategory
  // ────────────────────────────────────────────────────
  group('TransactionIconMapper.defaultIconKeyForCategory', () {
    final expectedKeys = {
      'Salary': 'briefcase',
      'Business': 'briefcase',
      'Freelance': 'laptop',
      'Investment': 'trendingUp',
      'Allowance': 'gift',
      'Bonus': 'gift',
      'Housing': 'home',
      'Bills': 'home',
      'Food': 'shoppingCart',
      'Transport': 'car',
      'Education': 'graduationCap',
      'Entertainment': 'tv',
      'Shopping': 'shoppingBag',
      'Health': 'heart',
      'Travel': 'plane',
    };

    for (final entry in expectedKeys.entries) {
      test('${entry.key} → "${entry.value}"', () {
        expect(
          TransactionIconMapper.defaultIconKeyForCategory(entry.key),
          entry.value,
        );
      });
    }

    test('unknown category falls back to "circle"', () {
      expect(
        TransactionIconMapper.defaultIconKeyForCategory('Random'),
        'circle',
      );
    });

    test('empty category falls back to "circle"', () {
      expect(
        TransactionIconMapper.defaultIconKeyForCategory(''),
        'circle',
      );
    });
  });

  // ────────────────────────────────────────────────────
  // TransactionIconMapper.resolve
  // ────────────────────────────────────────────────────
  group('TransactionIconMapper.resolve', () {
    test('resolves "briefcase" to LucideIcons.briefcase', () {
      expect(TransactionIconMapper.resolve('briefcase'), LucideIcons.briefcase);
    });

    test('resolves "laptop" to LucideIcons.laptop', () {
      expect(TransactionIconMapper.resolve('laptop'), LucideIcons.laptop);
    });

    test('resolves "shoppingCart" to LucideIcons.shoppingCart', () {
      expect(
        TransactionIconMapper.resolve('shoppingCart'),
        LucideIcons.shoppingCart,
      );
    });

    test('resolves "graduationCap" to LucideIcons.graduationCap', () {
      expect(
        TransactionIconMapper.resolve('graduationCap'),
        LucideIcons.graduationCap,
      );
    });

    test('resolves "gift" to LucideIcons.gift', () {
      expect(TransactionIconMapper.resolve('gift'), LucideIcons.gift);
    });

    test('resolves "car" to LucideIcons.car', () {
      expect(TransactionIconMapper.resolve('car'), LucideIcons.car);
    });

    test('resolves "home" to LucideIcons.home', () {
      expect(TransactionIconMapper.resolve('home'), LucideIcons.home);
    });

    test('resolves "heart" to LucideIcons.heart', () {
      expect(TransactionIconMapper.resolve('heart'), LucideIcons.heart);
    });

    test('resolves "plane" to LucideIcons.plane', () {
      expect(TransactionIconMapper.resolve('plane'), LucideIcons.plane);
    });

    test('resolves "tv" to LucideIcons.tv', () {
      expect(TransactionIconMapper.resolve('tv'), LucideIcons.tv);
    });

    test('falls through to category-based default for unknown key', () {
      // 'unknown_key' → defaultIconForCategory('Food') → resolve('shoppingCart') → known key
      final result = TransactionIconMapper.resolve(
        'unknown_key',
        category: 'Food',
      );
      expect(result, LucideIcons.shoppingCart);
    });

    test('falls back to briefcase for Salary category with unknown key', () {
      final result = TransactionIconMapper.resolve(
        'unknown_key',
        category: 'Salary',
      );
      expect(result, LucideIcons.briefcase);
    });
  });

  // ────────────────────────────────────────────────────
  // TransactionIconMapper.formatDisplayDate
  // ────────────────────────────────────────────────────
  group('TransactionIconMapper.formatDisplayDate', () {
    test('formats June 1st as "Jun 1"', () {
      final date = DateTime(2025, 6, 1);
      expect(TransactionIconMapper.formatDisplayDate(date), 'Jun 1');
    });

    test('formats December 31st as "Dec 31"', () {
      final date = DateTime(2025, 12, 31);
      expect(TransactionIconMapper.formatDisplayDate(date), 'Dec 31');
    });

    test('formats January 1st as "Jan 1"', () {
      final date = DateTime(2025, 1, 1);
      expect(TransactionIconMapper.formatDisplayDate(date), 'Jan 1');
    });

    test('formats a two-digit day correctly', () {
      final date = DateTime(2025, 11, 15);
      expect(TransactionIconMapper.formatDisplayDate(date), 'Nov 15');
    });
  });

  // ────────────────────────────────────────────────────
  // TransactionIconMapper.formatMonthLabel
  // ────────────────────────────────────────────────────
  group('TransactionIconMapper.formatMonthLabel', () {
    final monthExpected = {
      1: 'Jan', 2: 'Feb', 3: 'Mar', 4: 'Apr',
      5: 'May', 6: 'Jun', 7: 'Jul', 8: 'Aug',
      9: 'Sep', 10: 'Oct', 11: 'Nov', 12: 'Dec',
    };

    for (final entry in monthExpected.entries) {
      test('month ${entry.key} → "${entry.value}"', () {
        final date = DateTime(2025, entry.key, 1);
        expect(TransactionIconMapper.formatMonthLabel(date), entry.value);
      });
    }
  });
}
