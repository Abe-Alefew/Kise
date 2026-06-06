import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:kise/features/debt/data/dtos/debt_dto.dart';
import 'package:kise/features/debt/data/repositories/debt_repository.dart';
import 'package:kise/features/debt/domain/debt_entity.dart';
import 'package:kise/features/debt/domain/debt_filters.dart';
import 'package:kise/features/debt/domain/debt_inputs.dart';
import 'package:kise/features/debt/presentation/state/debts_notifier.dart';

import '../../helpers/provider_helper.dart';
import '../../helpers/test_data/debt_fixtures.dart';



class MockDebtRepository extends Mock implements DebtRepository {}



DebtSummary _emptySummary() => const DebtSummary(
      owedToMe: 0,
      iOwe: 0,
      netPosition: 0,
      recoveryRate: 0,
      counts: {},
      totalLent: 0,
      totalBorrowed: 0,
      outstandingOwedToMe: 0,
      outstandingIOwe: 0,
    );

DebtListResult _result(List<DebtEntity> items) => DebtListResult(
      items: items,
      fromCache: false,
      isStale: false,
    );

ProviderContainer _makeContainer(MockDebtRepository mockRepo) {
  return createContainer(
    overrides: [
      debtRepositoryProvider.overrideWithValue(mockRepo),
    ],
  );
}



void _stubEmpty(MockDebtRepository repo) {
  when(() => repo.getDebts(
        filter: any(named: 'filter'),
        forceRefresh: any(named: 'forceRefresh'),
      )).thenAnswer((_) async => _result([]));
  when(() => repo.getSummary(forceRefresh: any(named: 'forceRefresh')))
      .thenAnswer((_) async => _emptySummary());
}

void _stubWithDebts(MockDebtRepository repo, List<DebtEntity> debts) {
  when(() => repo.getDebts(
        filter: any(named: 'filter'),
        forceRefresh: any(named: 'forceRefresh'),
      )).thenAnswer((_) async => _result(debts));
  when(() => repo.getSummary(forceRefresh: any(named: 'forceRefresh')))
      .thenAnswer((_) async => _emptySummary());
}



void main() {
  late MockDebtRepository mockRepo;

  setUp(() {
    mockRepo = MockDebtRepository();
    registerFallbackValue(const CreateDebtInput(
      personName: 'Test',
      type: DebtType.lent,
      totalAmount: 100,
      debtDate: '2025-01-01',
    ));
    
    registerFallbackValue(DebtListFilter.all);
  });

  
  
  
  group('initial load', () {
    test('state is loading then resolves to data', () async {
      _stubEmpty(mockRepo);
      final container = _makeContainer(mockRepo);
      expect(container.read(debtsNotifierProvider), isA<AsyncLoading>());
      await container.read(debtsNotifierProvider.future);
      expect(container.read(debtsNotifierProvider), isA<AsyncData>());
    });

    test('state contains loaded debts', () async {
      _stubWithDebts(mockRepo, [pendingLentDebt, partialBorrowedDebt]);
      final container = _makeContainer(mockRepo);
      final debts = await container.read(debtsNotifierProvider.future);
      expect(debts, hasLength(2));
    });

    test('empty list when repo returns no debts', () async {
      _stubEmpty(mockRepo);
      final container = _makeContainer(mockRepo);
      final debts = await container.read(debtsNotifierProvider.future);
      expect(debts, isEmpty);
    });

    test('publishes meta via debtsMetaProvider after load', () async {
      _stubWithDebts(mockRepo, [pendingLentDebt]);
      final container = _makeContainer(mockRepo);
      await container.read(debtsNotifierProvider.future);
      final meta = container.read(debtsMetaProvider);
      expect(meta, isNotNull);
      expect(meta!.items, hasLength(1));
    });
  });

  
  
  
  group('filteredItems — all filter', () {
    test('returns all debts regardless of type or status', () async {
      _stubWithDebts(
        mockRepo,
        [pendingLentDebt, partialBorrowedDebt, settledLentDebt],
      );
      final container = _makeContainer(mockRepo);
      await container.read(debtsNotifierProvider.future);
      final filtered =
          container.read(debtsNotifierProvider.notifier).filteredItems;
      expect(filtered, hasLength(3));
    });
  });

  
  
  
  group('filteredItems — lent filter', () {
    test('returns only lent debts', () async {
      _stubWithDebts(
        mockRepo,
        [pendingLentDebt, partialBorrowedDebt, settledLentDebt],
      );
      final container = _makeContainer(mockRepo);
      await container.read(debtsNotifierProvider.future);

      await container
          .read(debtsNotifierProvider.notifier)
          .applyUiFilter('Lent');

      final filtered =
          container.read(debtsNotifierProvider.notifier).filteredItems;
      expect(filtered.every((d) => d.type == DebtType.lent), isTrue);
      expect(filtered, hasLength(2)); 
    });
  });

  
  
  
  group('filteredItems — borrowed filter', () {
    test('returns only borrowed debts', () async {
      _stubWithDebts(
        mockRepo,
        [pendingLentDebt, partialBorrowedDebt],
      );
      final container = _makeContainer(mockRepo);
      await container.read(debtsNotifierProvider.future);

      await container
          .read(debtsNotifierProvider.notifier)
          .applyUiFilter('Borrowed');

      final filtered =
          container.read(debtsNotifierProvider.notifier).filteredItems;
      expect(filtered.every((d) => d.type == DebtType.borrowed), isTrue);
      expect(filtered, hasLength(1));
    });
  });

  
  
  
  group('filteredItems — settled filter', () {
    test('returns only settled debts', () async {
      _stubWithDebts(
        mockRepo,
        [pendingLentDebt, partialBorrowedDebt, settledLentDebt],
      );
      final container = _makeContainer(mockRepo);
      await container.read(debtsNotifierProvider.future);

      await container
          .read(debtsNotifierProvider.notifier)
          .applyUiFilter('Settled');

      final filtered =
          container.read(debtsNotifierProvider.notifier).filteredItems;
      expect(
        filtered.every((d) => d.status == DebtStatus.settled),
        isTrue,
      );
      expect(filtered, hasLength(1));
    });
  });

  
  
  
  group('filteredItems — active filter', () {
    test('excludes settled debts', () async {
      _stubWithDebts(
        mockRepo,
        [pendingLentDebt, partialBorrowedDebt, settledLentDebt],
      );
      final container = _makeContainer(mockRepo);
      await container.read(debtsNotifierProvider.future);

      await container
          .read(debtsNotifierProvider.notifier)
          .applyUiFilter('Active');

      final filtered =
          container.read(debtsNotifierProvider.notifier).filteredItems;
      expect(
        filtered.every((d) => d.status != DebtStatus.settled),
        isTrue,
      );
      expect(filtered, hasLength(2)); 
    });
  });

  
  
  
  group('applyUiFilter()', () {
    test('changes internal filter to lent', () async {
      _stubEmpty(mockRepo);
      final container = _makeContainer(mockRepo);
      await container.read(debtsNotifierProvider.future);

      await container
          .read(debtsNotifierProvider.notifier)
          .applyUiFilter('Lent');

      expect(
        container.read(debtsNotifierProvider.notifier).filter,
        DebtListFilter.lent,
      );
    });

    test('resets to all after switching back', () async {
      _stubEmpty(mockRepo);
      final container = _makeContainer(mockRepo);
      await container.read(debtsNotifierProvider.future);

      await container
          .read(debtsNotifierProvider.notifier)
          .applyUiFilter('Lent');
      await container
          .read(debtsNotifierProvider.notifier)
          .applyUiFilter('All');

      expect(
        container.read(debtsNotifierProvider.notifier).filter,
        DebtListFilter.all,
      );
    });
  });

  
  
  
  group('refresh()', () {
    test('state goes back to loading then resolves', () async {
      _stubEmpty(mockRepo);
      final container = _makeContainer(mockRepo);
      await container.read(debtsNotifierProvider.future);

      final refreshFuture =
          container.read(debtsNotifierProvider.notifier).refresh();
      expect(container.read(debtsNotifierProvider), isA<AsyncLoading>());
      await refreshFuture;
      expect(container.read(debtsNotifierProvider), isA<AsyncData>());
    });

    test('forceRefresh=true is passed to repository on refresh', () async {
      _stubEmpty(mockRepo);
      final container = _makeContainer(mockRepo);
      await container.read(debtsNotifierProvider.future);

      await container.read(debtsNotifierProvider.notifier).refresh();

      verify(() => mockRepo.getDebts(
            filter: any(named: 'filter'),
            forceRefresh: true,
          )).called(1);
    });
  });

  
  
  
  group('isPendingSyncDebtId', () {
    test('recognises optimistic- prefix', () {
      expect(isPendingSyncDebtId('optimistic-123'), isTrue);
    });
    test('returns false for real server id', () {
      expect(isPendingSyncDebtId('server-abc'), isFalse);
    });
  });
}
























































































































































































































































































































































































































































































































































































































































































































