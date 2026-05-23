import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kise/core/cache/cache_policy.dart';
import 'package:kise/core/database/app_database.dart';
import 'package:kise/core/database/daos/debt_cache_dao.dart';
import 'package:kise/core/network/api_endpoints.dart';
import 'package:kise/core/network/dio_client.dart';
import 'package:kise/features/auth/presentation/providers/auth_notifier.dart';
import 'package:kise/features/debt/data/debt_dto.dart';
import 'package:kise/features/debt/domain/debt_entity.dart';
import 'package:kise/features/debt/domain/debt_filters.dart';
import 'package:kise/features/debt/domain/debt_inputs.dart';

class DebtListResult {
  final List<DebtEntity> items;
  final bool fromCache;
  final bool isStale;

  const DebtListResult({
    required this.items,
    required this.fromCache,
    required this.isStale,
  });
}

abstract class DebtRepository {
  Future<DebtListResult> getDebts({
    required DebtListFilter filter,
    bool forceRefresh = false,
  });

  Future<DebtSummary> getSummary({bool forceRefresh = false});

  Future<DebtEntity> createDebt(CreateDebtInput input);

  Future<DebtEntity> updateDebt(String debtId, UpdateDebtInput input);

  Future<void> deleteDebt(String debtId);

  Future<DebtEntity> recordPayment(
    String debtId,
    RecordPaymentInput input,
  );
}

class DebtRepositoryImpl implements DebtRepository {
  DebtRepositoryImpl({
    required DioClient dioClient,
    required Future<AppDatabase> appDatabase,
    required String? Function() currentUserId,
    CachePolicy? cachePolicy,
    bool enableLocalCache = true,
  })  : _dioClient = dioClient,
        _appDatabaseFuture = appDatabase,
        _currentUserId = currentUserId,
        _cachePolicy = cachePolicy ?? const CachePolicy(),
        _enableLocalCache = enableLocalCache;

  final DioClient _dioClient;
  final Future<AppDatabase> _appDatabaseFuture;
  final String? Function() _currentUserId;
  final CachePolicy _cachePolicy;
  final bool _enableLocalCache;

  Future<DebtCacheDao?> _tryDao() async {
    if (!_enableLocalCache) {
      return null;
    }

    try {
      final db = await _appDatabaseFuture;
      await DebtCacheDao.ensureSchema(db.database);
      return DebtCacheDao(db.database);
    } catch (_) {
      return null;
    }
  }

  String _requireUserId() {
    final userId = _currentUserId();
    if (userId == null || userId.isEmpty) {
      throw const ApiException(
        message: 'You must be signed in to access debts',
        code: 'UNAUTHORIZED',
        statusCode: 401,
      );
    }
    return userId;
  }

  void _rejectPendingSyncId(String debtId) {
    if (isPendingSyncDebtId(debtId)) {
      throw const ApiException(
        message: 'Debt is still syncing. Please try again in a moment.',
        code: 'PENDING_SYNC',
        statusCode: 409,
      );
    }
  }

  Future<List<DebtEntity>> _mapDebtRows(
    DebtCacheDao dao,
    String userId,
    List<Map<String, dynamic>> debtRows,
  ) async {
    final entities = <DebtEntity>[];

    for (final row in debtRows) {
      final debtId = row['id']?.toString() ?? '';
      final paymentRows = await dao.queryPaymentsForDebt(
        userId: userId,
        debtId: debtId,
      );
      final payments =
          paymentRows.map(DebtPaymentDto.fromCacheRow).toList(growable: true);

      entities.add(
        DebtDto.fromCacheRow(row, payments: payments).toEntity(
          isDirty: (row['is_dirty'] as int? ?? 0) == 1,
        ),
      );
    }

    return entities;
  }

  @override
  Future<DebtListResult> getDebts({
    required DebtListFilter filter,
    bool forceRefresh = false,
  }) async {
    final userId = _requireUserId();
    final dao = await _tryDao();

    final cachedRows = dao == null
        ? <Map<String, dynamic>>[]
        : await dao.queryDebts(
            userId: userId,
            filter: filter.apiValue,
          );

    final lastSyncAt = dao == null ? null : await dao.getLastSyncAt();
    final cacheIsFresh = dao != null &&
        !forceRefresh &&
        _cachePolicy.isFresh(lastSyncAt) &&
        cachedRows.isNotEmpty;

    if (cacheIsFresh) {
      return DebtListResult(
        items: await _mapDebtRows(dao, userId, cachedRows),
        fromCache: true,
        isStale: false,
      );
    }

    try {
      final response = await _dioClient.get<Map<String, dynamic>>(
        ApiEndpoints.debts,
        queryParameters: filter.toQueryParameters(),
      );

      if (response.statusCode != 200) {
        throw _unexpectedStatus(response);
      }

      final payload = ApiEnvelopeParser.parseSuccessPayload(response);
      final serverDebts = DebtDto.listFromEnvelope(payload);
      final syncedAt = DateTime.now().toUtc();

      if (dao != null) {
        final debtMaps = <Map<String, dynamic>>[];
        final paymentMaps = <Map<String, dynamic>>[];

        for (final debt in serverDebts) {
          debtMaps.add(
            debt.toDebtCacheRow(
              userId: userId,
              syncedAt: syncedAt,
              isDirty: false,
            ),
          );

          for (final payment in debt.payments) {
            paymentMaps.add(
              payment.toCacheRow(
                userId: userId,
                debtId: debt.id,
                syncedAt: syncedAt,
                isDirty: false,
              ),
            );
          }
        }

        await dao.replaceAllDebtsForUser(userId, debtMaps, paymentMaps);
        await dao.clearDirtyEntriesForUser(userId);
        await dao.setLastSyncAt(syncedAt);
      }

      return DebtListResult(
        items: serverDebts.map((dto) => dto.toEntity()).toList(),
        fromCache: false,
        isStale: false,
      );
    } on DioException catch (error) {
      if (dao != null && cachedRows.isNotEmpty) {
        return DebtListResult(
          items: await _mapDebtRows(dao, userId, cachedRows),
          fromCache: true,
          isStale: true,
        );
      }
      throw ApiEnvelopeParser.parseDioError(error);
    } on ApiException {
      rethrow;
    } catch (error) {
      if (dao != null && cachedRows.isNotEmpty) {
        return DebtListResult(
          items: await _mapDebtRows(dao, userId, cachedRows),
          fromCache: true,
          isStale: true,
        );
      }
      throw ApiException(
        message: error.toString(),
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  @override
  Future<DebtSummary> getSummary({bool forceRefresh = false}) async {
    final userId = _requireUserId();
    final dao = await _tryDao();

    try {
      final response = await _dioClient.get<Map<String, dynamic>>(
        ApiEndpoints.debtsSummary,
      );

      if (response.statusCode != 200) {
        throw _unexpectedStatus(response);
      }

      final data = ApiEnvelopeParser.parseSuccessData(response);
      return DebtSummary.fromJson(data);
    } on DioException catch (error) {
      if (dao == null) {
        throw ApiEnvelopeParser.parseDioError(error);
      }
      final local = await dao.computeLocalSummary(userId);
      return DebtSummary.fromLocal(local);
    } on ApiException {
      if (dao == null) rethrow;
      final local = await dao.computeLocalSummary(userId);
      return DebtSummary.fromLocal(local);
    } catch (_) {
      if (dao == null) {
        throw const ApiException(
          message: 'Could not load debt summary',
          code: 'UNKNOWN_ERROR',
        );
      }
      final local = await dao.computeLocalSummary(userId);
      return DebtSummary.fromLocal(local);
    }
  }

  Future<void> _persistServerDebt({
    required DebtCacheDao? dao,
    required String userId,
    required DebtDto serverDto,
  }) async {
    if (dao == null) {
      return;
    }

    final syncedAt = DateTime.now().toUtc();

    await dao.upsertDebt(
      serverDto.toDebtCacheRow(
        userId: userId,
        syncedAt: syncedAt,
        isDirty: false,
      ),
    );

    await dao.replacePaymentsForDebt(
      userId,
      serverDto.id,
      serverDto.payments
          .map(
            (payment) => payment.toCacheRow(
              userId: userId,
              debtId: serverDto.id,
              syncedAt: syncedAt,
              isDirty: false,
            ),
          )
          .toList(),
    );

    await dao.setLastSyncAt(syncedAt);
  }

  DebtDto _debtDtoFromResponseMap(Map<String, dynamic> data) {
    return DebtDto.fromJson(data);
  }

  @override
  Future<DebtEntity> createDebt(CreateDebtInput input) async {
    final userId = _requireUserId();
    final dao = await _tryDao();

    try {
      final response = await _dioClient.post<Map<String, dynamic>>(
        ApiEndpoints.debts,
        data: input.toJson(),
      );

      if (response.statusCode != 201) {
        throw _unexpectedStatus(response);
      }

      final data = ApiEnvelopeParser.parseSuccessData(response);
      final serverDto = _debtDtoFromResponseMap(data);
      await _persistServerDebt(dao: dao, userId: userId, serverDto: serverDto);
      return serverDto.toEntity();
    } on DioException catch (error) {
      throw ApiEnvelopeParser.parseDioError(error);
    }
  }

  @override
  Future<DebtEntity> updateDebt(String debtId, UpdateDebtInput input) async {
    _rejectPendingSyncId(debtId);

    if (input.isEmpty) {
      throw const ApiException(
        message: 'No fields provided to update',
        code: 'VALIDATION_ERROR',
        statusCode: 400,
      );
    }

    final userId = _requireUserId();
    final dao = await _tryDao();

    try {
      final response = await _dioClient.patch<Map<String, dynamic>>(
        '${ApiEndpoints.debts}/$debtId',
        data: input.toJson(),
      );

      if (response.statusCode != 200) {
        throw _unexpectedStatus(response);
      }

      final data = ApiEnvelopeParser.parseSuccessData(response);
      final serverDto = _debtDtoFromResponseMap(data);
      await _persistServerDebt(dao: dao, userId: userId, serverDto: serverDto);
      return serverDto.toEntity();
    } on DioException catch (error) {
      throw ApiEnvelopeParser.parseDioError(error);
    }
  }

  @override
  Future<void> deleteDebt(String debtId) async {
    _rejectPendingSyncId(debtId);

    final userId = _requireUserId();
    final dao = await _tryDao();

    try {
      final response = await _dioClient.delete<Map<String, dynamic>>(
        '${ApiEndpoints.debts}/$debtId',
      );

      if (response.statusCode != 200) {
        throw _unexpectedStatus(response);
      }

      if (dao != null) {
        await dao.deleteDebtById(userId, debtId);
        await dao.setLastSyncAt(DateTime.now().toUtc());
      }
    } on DioException catch (error) {
      throw ApiEnvelopeParser.parseDioError(error);
    }
  }

  @override
  Future<DebtEntity> recordPayment(
    String debtId,
    RecordPaymentInput input,
  ) async {
    _rejectPendingSyncId(debtId);

    final userId = _requireUserId();
    final dao = await _tryDao();

    try {
      final response = await _dioClient.post<Map<String, dynamic>>(
        '${ApiEndpoints.debts}/$debtId/payments',
        data: input.toJson(),
      );

      if (response.statusCode != 200) {
        throw _unexpectedStatus(response);
      }

      final data = ApiEnvelopeParser.parseSuccessData(response);
      final debtJson = data['debt'];
      final Map<String, dynamic> debtMap;
      if (debtJson is Map<String, dynamic>) {
        debtMap = debtJson;
      } else if (debtJson is Map) {
        debtMap = Map<String, dynamic>.from(debtJson);
      } else {
        throw const ApiException(
          message: 'Invalid payment response payload',
          code: 'INVALID_RESPONSE',
        );
      }

      final serverDto = _debtDtoFromResponseMap(debtMap);
      await _persistServerDebt(dao: dao, userId: userId, serverDto: serverDto);
      return serverDto.toEntity();
    } on DioException catch (error) {
      throw ApiEnvelopeParser.parseDioError(error);
    }
  }

  ApiException _unexpectedStatus(Response<dynamic> response) {
    final body = ApiEnvelopeParser.responseBodyMap(response.data);
    if (body != null) {
      return ApiEnvelopeParser.parseErrorFromMap(
        body,
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

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  return DebtRepositoryImpl(
    dioClient: ref.watch(dioClientProvider),
    appDatabase: ref.watch(appDatabaseProvider.future),
    currentUserId: () => ref.watch(authStateProvider)?.user?.id,
    enableLocalCache: !kIsWeb,
  );
});
