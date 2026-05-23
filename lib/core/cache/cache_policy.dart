class CachePolicy {
  final Duration ttl;

  const CachePolicy({
    this.ttl = const Duration(minutes: 5),
  });

  bool isFresh(DateTime? lastSyncedAt, {DateTime? now}) {
    if (lastSyncedAt == null) {
      return false;
    }

    final reference = now ?? DateTime.now().toUtc();
    return reference.difference(lastSyncedAt.toUtc()) <= ttl;
  }
}