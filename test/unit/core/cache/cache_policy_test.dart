import 'package:flutter_test/flutter_test.dart';
import 'package:kise/core/cache/cache_policy.dart';

void main() {
  group('CachePolicy', () {
    const policy = CachePolicy(ttl: Duration(minutes: 5));

    // ────────────────────────────────────────────────────
    // isFresh — null lastSyncedAt
    // ────────────────────────────────────────────────────
    group('isFresh — null sync time', () {
      test('returns false when lastSyncedAt is null', () {
        expect(policy.isFresh(null), isFalse);
      });
    });

    // ────────────────────────────────────────────────────
    // isFresh — within TTL
    // ────────────────────────────────────────────────────
    group('isFresh — within TTL', () {
      test('returns true when synced 1 minute ago', () {
        final now = DateTime.now().toUtc();
        final syncedAt = now.subtract(const Duration(minutes: 1));
        expect(policy.isFresh(syncedAt, now: now), isTrue);
      });

      test('returns true when synced exactly at TTL boundary', () {
        final now = DateTime.now().toUtc();
        final syncedAt = now.subtract(const Duration(minutes: 5));
        // Exactly at TTL → difference == ttl → still fresh (<=)
        expect(policy.isFresh(syncedAt, now: now), isTrue);
      });

      test('returns true when synced just now', () {
        final now = DateTime.now().toUtc();
        expect(policy.isFresh(now, now: now), isTrue);
      });
    });

    // ────────────────────────────────────────────────────
    // isFresh — expired
    // ────────────────────────────────────────────────────
    group('isFresh — expired', () {
      test('returns false when synced 6 minutes ago', () {
        final now = DateTime.now().toUtc();
        final syncedAt = now.subtract(const Duration(minutes: 6));
        expect(policy.isFresh(syncedAt, now: now), isFalse);
      });

      test('returns false when synced 1 hour ago', () {
        final now = DateTime.now().toUtc();
        final syncedAt = now.subtract(const Duration(hours: 1));
        expect(policy.isFresh(syncedAt, now: now), isFalse);
      });

      test('returns false when synced yesterday', () {
        final now = DateTime.now().toUtc();
        final syncedAt = now.subtract(const Duration(days: 1));
        expect(policy.isFresh(syncedAt, now: now), isFalse);
      });
    });

    // ────────────────────────────────────────────────────
    // Custom TTL
    // ────────────────────────────────────────────────────
    group('CachePolicy with custom TTL', () {
      test('1-second TTL expires after 2 seconds', () {
        const shortPolicy = CachePolicy(ttl: Duration(seconds: 1));
        final now = DateTime.now().toUtc();
        final syncedAt = now.subtract(const Duration(seconds: 2));
        expect(shortPolicy.isFresh(syncedAt, now: now), isFalse);
      });

      test('1-hour TTL is fresh after 30 minutes', () {
        const longPolicy = CachePolicy(ttl: Duration(hours: 1));
        final now = DateTime.now().toUtc();
        final syncedAt = now.subtract(const Duration(minutes: 30));
        expect(longPolicy.isFresh(syncedAt, now: now), isTrue);
      });
    });

    // ────────────────────────────────────────────────────
    // Default TTL
    // ────────────────────────────────────────────────────
    test('default TTL is 5 minutes', () {
      const defaultPolicy = CachePolicy();
      final now = DateTime.now().toUtc();
      // 4 minutes old → fresh
      expect(
        defaultPolicy.isFresh(now.subtract(const Duration(minutes: 4)), now: now),
        isTrue,
      );
      // 6 minutes old → stale
      expect(
        defaultPolicy.isFresh(now.subtract(const Duration(minutes: 6)), now: now),
        isFalse,
      );
    });
  });
}