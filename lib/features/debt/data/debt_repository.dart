import 'dart:async';

import 'package:dio/dio.dart';
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
import 'package:uuid/uuid.dart';

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
    Uuid? uuid,
  })  : _dioClient = dioClient,
        _appDatabaseFuture = appDatabase,
        _currentUserId = currentUserId,
        _cachePolicy = cachePolicy ?? const CachePolicy(),
        _uuid = uuid ?? const Uuid();

  final DioClient _dioClient;
  final Future<AppDatabase> _appDatabaseFuture;
  final String? Function() _currentUserId;
  final CachePolicy _cachePolicy;
  final Uuid _uuid;

  Future<DebtCacheDao> _dao() async {
    final db = await _appDatabaseFuture;
    await DebtCacheDao.ensureSchema(db.database);
    return DebtCacheDao(db.database);
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
    final dao = await _dao();

    final cachedRows = await dao.queryDebts(
      userId: userId,
      filter: filter.apiValue,
    );

    final lastSyncAt = await dao.getLastSyncAt();
    final cacheIsFresh = !forceRefresh &&
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

      final envelopeData = ApiEnvelopeParser.parseSuccessData(response);
      final serverDebts = DebtDto.listFromEnvelope(envelopeData);
      final syncedAt = DateTime.now().toUtc();

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
      await dao.setLastSyncAt(syncedAt);

      final dirtyRows = await dao.getDirtyDebts(userId);
      final dirtyEntities = await _mapDebtRows(dao, userId, dirtyRows);

      return DebtListResult(
        items: _mergeServerAndDirty(
          serverItems: serverDebts.map((dto) => dto.toEntity()).toList(),
          dirtyItems: dirtyEntities,
        ),
        fromCache: false,
        isStale: false,
      );
    } on DioException catch (error) {
      if (cachedRows.isNotEmpty) {
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
      if (cachedRows.isNotEmpty) {
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
    final dao = await _dao();

    try {
      final response = await _dioClient.get<Map<String, dynamic>>(
        ApiEndpoints.debtsSummary,
      );

      if (response.statusCode != 200) {
        throw _unexpectedStatus(response);
      }

      final data = ApiEnvelopeParser.parseSuccessData(response);
      return DebtSummary.fromJson(data);
    } on DioException {
      final local = await dao.computeLocalSummary(userId);
      return DebtSummary.fromLocal(local);
    } on ApiException {
      final local = await dao.computeLocalSummary(userId);
      return DebtSummary.fromLocal(local);
    } catch (_) {
      final local = await dao.computeLocalSummary(userId);
      return DebtSummary.fromLocal(local);
    }
  }

  @override
  Future<DebtEntity> createDebt(CreateDebtInput input) async {
    final userId = _requireUserId();
    final dao = await _dao();
    final localId = _uuid.v4();
    final now = DateTime.now().toUtc();

    final localDto = DebtDto.fromCreateInput(
      id: localId,
      input: input,
      createdAt: now,
    );

    await dao.upsertDebt(
      localDto.toDebtCacheRow(
        userId: userId,
        syncedAt: now,
        isDirty: true,
      ),
    );

    final optimistic = localDto.toEntity(isDirty: true);
    unawaited(_syncCreateDebt(userId: userId, localId: localId, input: input));
    return optimistic;
  }

  @override
  Future<DebtEntity> updateDebt(String debtId, UpdateDebtInput input) async {
    if (input.isEmpty) {
      throw const ApiException(
        message: 'No fields provided to update',
        code: 'VALIDATION_ERROR',
        statusCode: 400,
      );
    }

    final userId = _requireUserId();
    final dao = await _dao();

    final existingRow = await dao.findDebtById(userId, debtId);
    if (existingRow == null) {
      throw const ApiException(
        message: 'Debt not found locally',
        code: 'NOT_FOUND',
        statusCode: 404,
      );
    }

    final now = DateTime.now().toUtc();
    final paymentRows = await dao.queryPaymentsForDebt(
      userId: userId,
      debtId: debtId,
    );
    final payments =
        paymentRows.map(DebtPaymentDto.fromCacheRow).toList(growable: true);

    final patched = DebtDto.fromCacheRow(existingRow, payments: payments)
        .applyUpdate(input, updatedAt: now);

    await dao.upsertDebt(
      patched.toDebtCacheRow(
        userId: userId,
        syncedAt: now,
        isDirty: true,
      ),
    );

    final optimistic = patched.toEntity(isDirty: true);
    unawaited(_syncUpdateDebt(userId: userId, debtId: debtId, input: input));
    return optimistic;
  }

  @override
  Future<void> deleteDebt(String debtId) async {
    final userId = _requireUserId();
    final dao = await _dao();
    await dao.softDeleteDebtById(userId, debtId);
    unawaited(_syncDeleteDebt(userId: userId, debtId: debtId));
  }

  @override
  Future<DebtEntity> recordPayment(
    String debtId,
    RecordPaymentInput input,
  ) async {
    final userId = _requireUserId();
    final dao = await _dao();

    final debtRow = await dao.findDebtById(userId, debtId);
    if (debtRow == null) {
      throw const ApiException(
        message: 'Debt not found locally',
        code: 'NOT_FOUND',
        statusCode: 404,
      );
    }

    final localPaymentId = _uuid.v4();
    final now = DateTime.now().toUtc();

    final paymentRows = await dao.queryPaymentsForDebt(
      userId: userId,
      debtId: debtId,
    );
    final existingPayments =
        paymentRows.map(DebtPaymentDto.fromCacheRow).toList(growable: true);

    final localPaymentDto = DebtPaymentDto.fromLocalRecord(
      id: localPaymentId,
      input: input,
      createdAt: now,
    );

    final updatedDebt = DebtDto.fromCacheRow(
      debtRow,
      payments: existingPayments,
    ).applyPayment(payment: localPaymentDto, updatedAt: now);

    await dao.upsertDebt(
      updatedDebt.toDebtCacheRow(
        userId: userId,
        syncedAt: now,
        isDirty: true,
      ),
    );

    await dao.upsertPayment(
      localPaymentDto.toCacheRow(
        userId: userId,
        debtId: debtId,
        syncedAt: now,
        isDirty: true,
      ),
    );

    final optimistic = updatedDebt.toEntity(isDirty: true);

    unawaited(
      _syncRecordPayment(
        userId: userId,
        debtId: debtId,
        localPaymentId: localPaymentId,
        input: input,
      ),
    );

    return optimistic;
  }

  Future<void> _syncCreateDebt({
    required String userId,
    required String localId,
    required CreateDebtInput input,
  }) async {
    final dao = await _dao();

    try {
      final response = await _dioClient.post<Map<String, dynamic>>(
        ApiEndpoints.debts,
        data: input.toJson(),
      );

      if (response.statusCode != 201) {
        throw _unexpectedStatus(response);
      }

      final data = ApiEnvelopeParser.parseSuccessData(response);
      final serverDto = DebtDto.fromJson(data);
      final syncedAt = DateTime.now().toUtc();

      await dao.deleteDebtById(userId, localId);
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
    } catch (_) {}
  }

  Future<void> _syncUpdateDebt({
    required String userId,
    required String debtId,
    required UpdateDebtInput input,
  }) async {
    final dao = await _dao();

    try {
      final response = await _dioClient.patch<Map<String, dynamic>>(
        '${ApiEndpoints.debts}/$debtId',
        data: input.toJson(),
      );

      if (response.statusCode != 200) {
        throw _unexpectedStatus(response);
      }

      final data = ApiEnvelopeParser.parseSuccessData(response);
      final serverDto = DebtDto.fromJson(data);
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
        debtId,
        serverDto.payments
            .map(
              (payment) => payment.toCacheRow(
                userId: userId,
                debtId: debtId,
                syncedAt: syncedAt,
                isDirty: false,
              ),
            )
            .toList(),
      );
    } catch (_) {}
  }

  Future<void> _syncDeleteDebt({
    required String userId,
    required String debtId,
  }) async {
    final dao = await _dao();

    try {
      final response = await _dioClient.delete<Map<String, dynamic>>(
        '${ApiEndpoints.debts}/$debtId',
      );

      if (response.statusCode != 200) {
        throw _unexpectedStatus(response);
      }

      await dao.deleteDebtById(userId, debtId);
    } catch (_) {}
  }

  Future<void> _syncRecordPayment({
    required String userId,
    required String debtId,
    required String localPaymentId,
    required RecordPaymentInput input,
  }) async {
    final dao = await _dao();

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

      if (debtJson is! Map<String, dynamic>) {
        throw const ApiException(
          message: 'Invalid payment response payload',
          code: 'INVALID_RESPONSE',
        );
      }

      final serverDebt = DebtDto.fromJson(debtJson);
      final syncedAt = DateTime.now().toUtc();

      await dao.upsertDebt(
        serverDebt.toDebtCacheRow(
          userId: userId,
          syncedAt: syncedAt,
          isDirty: false,
        ),
      );

      await dao.deletePaymentById(userId, localPaymentId);
      await dao.replacePaymentsForDebt(
        userId,
        debtId,
        serverDebt.payments
            .map(
              (payment) => payment.toCacheRow(
                userId: userId,
                debtId: debtId,
                syncedAt: syncedAt,
                isDirty: false,
              ),
            )
            .toList(),
      );
    } catch (_) {}
  }

  List<DebtEntity> _mergeServerAndDirty({
    required List<DebtEntity> serverItems,
    required List<DebtEntity> dirtyItems,
  }) {
    final dirtyIds = dirtyItems.map((debt) => debt.id).toSet();

    return [
      ...dirtyItems,
      ...serverItems.where((debt) => !dirtyIds.contains(debt.id)),
    ];
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

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  return DebtRepositoryImpl(
    dioClient: ref.watch(dioClientProvider),
    appDatabase: ref.watch(appDatabaseProvider.future),
    currentUserId: () => ref.watch(authStateProvider)?.user?.id,
  );
});