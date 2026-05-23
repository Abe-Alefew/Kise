import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kise/core/cache/cache_policy.dart';
import 'package:kise/core/database/app_database.dart';
import 'package:kise/core/database/daos/transaction_cache_dao.dart';
import 'package:kise/core/network/api_endpoints.dart';
import 'package:kise/core/network/dio_client.dart';
import 'package:kise/features/auth/presentation/providers/auth_notifier.dart';
import 'package:kise/features/transactions/data/transaction_dto.dart';
import 'package:kise/features/transactions/domain/transaction_entity.dart';
import 'package:kise/features/transactions/domain/transaction_filters.dart';
import 'package:kise/features/transactions/domain/transaction_inputs.dart';
import 'package:uuid/uuid.dart';

class TransactionListResult {
  final List<TransactionEntity> items;
  final bool fromCache;
  final bool isStale;
  final int total;
  final bool hasMore;

  const TransactionListResult({
    required this.items,
    required this.fromCache,
    required this.isStale,
    required this.total,
    required this.hasMore,
  });
}

abstract class TransactionRepository {
  Future<TransactionListResult> getTransactions({
    required TransactionQueryFilter filter,
    bool forceRefresh = false,
  });

  Future<TransactionEntity> createTransaction(CreateTransactionInput input);

  Future<TransactionEntity> updateTransaction(
    String transactionId,
    Map<String, dynamic> updates,
  );

  Future<void> deleteTransaction(String transactionId);

  Future<TransactionSummary> getSummary({
    String? from,
    String? to,
    bool forceRefresh = false,
  });

  Future<TransactionAnalytics> getAnalytics({
    required String range,
    String type,
    bool forceRefresh = false,
  });
}

class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl({
    required DioClient dioClient,
    required Future<AppDatabase> appDatabase,
    required String? Function() currentUserId,
    CachePolicy? cachePolicy,
    Uuid? uuid,
    bool enableLocalCache = true,
  })  : _dioClient = dioClient,
        _appDatabaseFuture = appDatabase,
        _currentUserId = currentUserId,
        _cachePolicy = cachePolicy ?? const CachePolicy(),
        _uuid = uuid ?? const Uuid(),
        _enableLocalCache = enableLocalCache;

  final DioClient _dioClient;
  final Future<AppDatabase> _appDatabaseFuture;
  final String? Function() _currentUserId;
  final CachePolicy _cachePolicy;
  final Uuid _uuid;
  final bool _enableLocalCache;

  Future<TransactionCacheDao?> _tryDao() async {
    if (!_enableLocalCache) {
      return null;
    }

    try {
      final db = await _appDatabaseFuture;
      await TransactionCacheDao.ensureSchema(db.database);
      return TransactionCacheDao(db.database);
    } catch (_) {
      return null;
    }
  }

  String _requireUserId() {
    final userId = _currentUserId();
    if (userId == null || userId.isEmpty) {
      throw const ApiException(
        message: 'You must be signed in to access transactions',
        code: 'UNAUTHORIZED',
        statusCode: 401,
      );
    }
    return userId;
  }

  @override
  Future<TransactionListResult> getTransactions({
    required TransactionQueryFilter filter,
    bool forceRefresh = false,
  }) async {
    final userId = _requireUserId();
    final dao = await _tryDao();

    final cachedRows = dao == null
        ? <Map<String, dynamic>>[]
        : await dao.queryTransactions(
      userId: userId,
      type: filter.type,
      category: filter.category,
      fromDate: filter.from,
      toDate: filter.to,
      searchQuery: filter.searchQuery,
      sort: filter.sort,
      limit: filter.limit,
      offset: filter.offset,
    );

    final lastSyncAt =
        dao == null ? null : await dao.getLastSyncAt();
    final cacheIsFresh = dao != null &&
        !forceRefresh &&
        _cachePolicy.isFresh(lastSyncAt) &&
        cachedRows.isNotEmpty;

    if (cacheIsFresh) {
      final total = await dao!.countTransactions(
        userId: userId,
        type: filter.type,
        category: filter.category,
        fromDate: filter.from,
        toDate: filter.to,
        searchQuery: filter.searchQuery,
      );

      return TransactionListResult(
        items: cachedRows.map(TransactionDto.fromCacheRow).map((e) => e.toEntity()).toList(),
        fromCache: true,
        isStale: false,
        total: total,
        hasMore: filter.offset + cachedRows.length < total,
      );
    }

    try {
      final response = await _dioClient.get<Map<String, dynamic>>(
        ApiEndpoints.transactions,
        queryParameters: filter.toQueryParameters(),
      );

      if (response.statusCode != 200) {
        throw _unexpectedStatus(response);
      }

      final data = ApiEnvelopeParser.parseSuccessData(response);
      final parsed = TransactionListPageDto.fromJson(data);
      final now = DateTime.now().toUtc();

      final cacheMaps = parsed.items
          .map(
            (item) => item.toCacheRow(
              userId: userId,
              syncedAt: now,
              isDirty: false,
            ),
          )
          .toList();

      if (dao != null) {
        await dao.replaceAllForUser(userId, cacheMaps);
        await dao.setLastSyncAt(now);
      }

      final dirtyRows = dao == null
          ? <Map<String, dynamic>>[]
          : await dao.getDirtyTransactions(userId);
      final dirtyEntities =
          dirtyRows.map(TransactionDto.fromCacheRow).map((e) => e.toEntity()).toList();

      final merged = _mergeServerAndDirty(
        serverItems: parsed.items.map((e) => e.toEntity()).toList(),
        dirtyItems: dirtyEntities,
        filter: filter,
      );

      return TransactionListResult(
        items: merged,
        fromCache: false,
        isStale: false,
        total: parsed.total,
        hasMore: parsed.hasMore,
      );
    } on DioException catch (error) {
      final apiError = ApiEnvelopeParser.parseDioError(error);

      if (dao != null && cachedRows.isNotEmpty) {
        final total = await dao.countTransactions(
          userId: userId,
          type: filter.type,
          category: filter.category,
          fromDate: filter.from,
          toDate: filter.to,
          searchQuery: filter.searchQuery,
        );

        return TransactionListResult(
          items: cachedRows.map(TransactionDto.fromCacheRow).map((e) => e.toEntity()).toList(),
          fromCache: true,
          isStale: true,
          total: total,
          hasMore: filter.offset + cachedRows.length < total,
        );
      }

      throw apiError;
    } on ApiException {
      rethrow;
    } catch (error) {
      if (dao != null && cachedRows.isNotEmpty) {
        final total = await dao.countTransactions(
          userId: userId,
          type: filter.type,
          category: filter.category,
          fromDate: filter.from,
          toDate: filter.to,
          searchQuery: filter.searchQuery,
        );

        return TransactionListResult(
          items: cachedRows.map(TransactionDto.fromCacheRow).map((e) => e.toEntity()).toList(),
          fromCache: true,
          isStale: true,
          total: total,
          hasMore: filter.offset + cachedRows.length < total,
        );
      }

      throw ApiException(
        message: error.toString(),
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  @override
  Future<TransactionEntity> createTransaction(CreateTransactionInput input) async {
    final userId = _requireUserId();
    final dao = await _tryDao();

    final localId = _uuid.v4();
    final now = DateTime.now().toUtc();

    if (dao != null) {
      final dto = TransactionDto.fromCreateInput(
        id: localId,
        userId: userId,
        input: input,
        createdAt: now,
        isDirty: true,
      );

      await dao.upsertOne(
        dto.toCacheRow(
          userId: userId,
          syncedAt: now,
          isDirty: true,
        ),
      );
    }

    try {
      final response = await _dioClient.post<Map<String, dynamic>>(
        ApiEndpoints.transactions,
        data: input.toJson(),
      );

      if (response.statusCode != 201) {
        throw _unexpectedStatus(response);
      }

      final data = ApiEnvelopeParser.parseSuccessData(response);
      final serverDto = TransactionDto.fromJson(data);
      final syncedAt = DateTime.now().toUtc();

      if (dao != null) {
        await dao.deleteById(userId, localId);
        await dao.upsertOne(
          serverDto.toCacheRow(
            userId: userId,
            syncedAt: syncedAt,
            isDirty: false,
          ),
        );
        await dao.setLastSyncAt(syncedAt);
      }

      return serverDto.toEntity().copyWith(isDirty: false);
    } on DioException catch (error) {
      if (dao != null) {
        await dao.deleteById(userId, localId);
      }
      throw ApiEnvelopeParser.parseDioError(error);
    } on ApiException {
      if (dao != null) {
        await dao.deleteById(userId, localId);
      }
      rethrow;
    }
  }

  @override
  Future<TransactionEntity> updateTransaction(
    String transactionId,
    Map<String, dynamic> updates,
  ) async {
    _requireUserId();

    try {
      final response = await _dioClient.patch<Map<String, dynamic>>(
        '${ApiEndpoints.transactions}/$transactionId',
        data: updates,
      );

      if (response.statusCode != 200) {
        throw _unexpectedStatus(response);
      }

      final data = ApiEnvelopeParser.parseSuccessData(response);
      final serverDto = TransactionDto.fromJson(data);
      final userId = _requireUserId();
      final dao = await _tryDao();
      final syncedAt = DateTime.now().toUtc();

      if (dao != null) {
        await dao.upsertOne(
          serverDto.toCacheRow(
            userId: userId,
            syncedAt: syncedAt,
            isDirty: false,
          ),
        );
      }

      return serverDto.toEntity();
    } on DioException catch (error) {
      throw ApiEnvelopeParser.parseDioError(error);
    }
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    final userId = _requireUserId();
    final dao = await _tryDao();

    try {
      final response = await _dioClient.delete<Map<String, dynamic>>(
        '${ApiEndpoints.transactions}/$transactionId',
      );

      if (response.statusCode != 200) {
        throw _unexpectedStatus(response);
      }

      await dao?.deleteById(userId, transactionId);
    } on DioException catch (error) {
      throw ApiEnvelopeParser.parseDioError(error);
    }
  }

  @override
  Future<TransactionSummary> getSummary({
    String? from,
    String? to,
    bool forceRefresh = false,
  }) async {
    try {
      final response = await _dioClient.get<Map<String, dynamic>>(
        ApiEndpoints.transactionsSummary,
        queryParameters: {
          if (from != null) 'from': from,
          if (to != null) 'to': to,
        },
      );

      if (response.statusCode != 200) {
        throw _unexpectedStatus(response);
      }

      final data = ApiEnvelopeParser.parseSuccessData(response);
      return TransactionSummary.fromJson(data);
    } on DioException catch (error) {
      throw ApiEnvelopeParser.parseDioError(error);
    }
  }

  @override
  Future<TransactionAnalytics> getAnalytics({
    required String range,
    String type = 'all',
    bool forceRefresh = false,
  }) async {
    try {
      final response = await _dioClient.get<Map<String, dynamic>>(
        ApiEndpoints.transactionsAnalytics,
        queryParameters: {
          'range': range,
          'type': type,
        },
      );

      if (response.statusCode != 200) {
        throw _unexpectedStatus(response);
      }

      final data = ApiEnvelopeParser.parseSuccessData(response);
      return TransactionAnalytics.fromJson(data);
    } on DioException catch (error) {
      throw ApiEnvelopeParser.parseDioError(error);
    }
  }

  List<TransactionEntity> _mergeServerAndDirty({
    required List<TransactionEntity> serverItems,
    required List<TransactionEntity> dirtyItems,
    required TransactionQueryFilter filter,
  }) {
    final dirtyIds = dirtyItems.map((e) => e.id).toSet();
    final merged = <TransactionEntity>[
      ...dirtyItems,
      ...serverItems.where((item) => !dirtyIds.contains(item.id)),
    ];

    merged.sort((a, b) {
      final aDate = DateTime.tryParse(a.transactionDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = DateTime.tryParse(b.transactionDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    Iterable<TransactionEntity> filtered = merged;

    if (filter.type != null && filter.type!.isNotEmpty && filter.type != 'All') {
      filtered = filtered.where((item) => item.type == filter.type);
    }

    if (filter.category != null && filter.category!.isNotEmpty) {
      filtered = filtered.where((item) => item.category == filter.category);
    }

    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final q = filter.searchQuery!.toLowerCase();
      filtered = filtered.where(
        (item) =>
            item.title.toLowerCase().contains(q) ||
            item.category.toLowerCase().contains(q) ||
            (item.note ?? '').toLowerCase().contains(q),
      );
    }

    var list = filtered.toList();

    if (filter.limit != null) {
      final start = filter.offset;
      final end = start + filter.limit!;
      if (start < list.length) {
        list = list.sublist(start, end > list.length ? list.length : end);
      } else {
        list = [];
      }
    }

    return list;
  }

  ApiException _unexpectedStatus(Response<dynamic> response) {
    if (response.data is Map<String, dynamic>) {
      return ApiEnvelopeParser.parseErrorFromMap(
        response.data as Map<String, dynamic>,
        response.statusCode,
      );
    }

    return ApiException(
      message: 'Request failed with status ${response.statusCode}',
      code: 'REQUEST_ERROR',
      statusCode: response.statusCode,
    );
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl(
    dioClient: ref.watch(dioClientProvider),
    appDatabase: ref.watch(appDatabaseProvider.future),
    currentUserId: () => ref.watch(authStateProvider)?.user?.id,
    enableLocalCache: !kIsWeb,
  );
});