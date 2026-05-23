import 'package:kise/core/database/daos/debt_cache_dao.dart';
import 'package:kise/features/debt/domain/debt_entity.dart';
import 'package:kise/features/debt/domain/debt_inputs.dart';

class DebtSummary {
  final double owedToMe;
  final double iOwe;
  final double netPosition;
  final double recoveryRate;
  final Map<String, int> counts;
  final double totalLent;
  final double totalBorrowed;
  final double outstandingOwedToMe;
  final double outstandingIOwe;

  const DebtSummary({
    required this.owedToMe,
    required this.iOwe,
    required this.netPosition,
    required this.recoveryRate,
    required this.counts,
    required this.totalLent,
    required this.totalBorrowed,
    required this.outstandingOwedToMe,
    required this.outstandingIOwe,
  });

  factory DebtSummary.fromJson(Map<String, dynamic> json) {
    final countsJson = json['counts'];
    final counts = <String, int>{};

    if (countsJson is Map<String, dynamic>) {
      countsJson.forEach((key, value) {
        counts[key] = (value as num?)?.toInt() ?? 0;
      });
    }

    final totalsJson = json['totals'];
    var totalLent = 0.0;
    var totalBorrowed = 0.0;
    var outstandingOwedToMe = (json['owedToMe'] as num?)?.toDouble() ?? 0;
    var outstandingIOwe = (json['iOwe'] as num?)?.toDouble() ?? 0;

    if (totalsJson is Map<String, dynamic>) {
      totalLent = (totalsJson['totalLent'] as num?)?.toDouble() ?? 0;
      totalBorrowed = (totalsJson['totalBorrowed'] as num?)?.toDouble() ?? 0;
      outstandingOwedToMe =
          (totalsJson['outstandingOwedToMe'] as num?)?.toDouble() ??
              outstandingOwedToMe;
      outstandingIOwe =
          (totalsJson['outstandingIOwe'] as num?)?.toDouble() ?? outstandingIOwe;
    }

    return DebtSummary(
      owedToMe: (json['owedToMe'] as num?)?.toDouble() ?? outstandingOwedToMe,
      iOwe: (json['iOwe'] as num?)?.toDouble() ?? outstandingIOwe,
      netPosition: (json['netPosition'] as num?)?.toDouble() ??
          (outstandingOwedToMe - outstandingIOwe),
      recoveryRate: (json['recoveryRate'] as num?)?.toDouble() ?? 0,
      counts: counts,
      totalLent: totalLent,
      totalBorrowed: totalBorrowed,
      outstandingOwedToMe: outstandingOwedToMe,
      outstandingIOwe: outstandingIOwe,
    );
  }

  factory DebtSummary.fromLocal(DebtLocalSummary local) {
    return DebtSummary(
      owedToMe: local.owedToMe,
      iOwe: local.iOwe,
      netPosition: local.netPosition,
      recoveryRate: local.recoveryRate,
      counts: {
        'pending': local.pendingCount,
        'partial': local.partialCount,
        'settled': local.settledCount,
      },
      totalLent: local.totalLent,
      totalBorrowed: local.totalBorrowed,
      outstandingOwedToMe: local.owedToMe,
      outstandingIOwe: local.iOwe,
    );
  }
}

class DebtPaymentDto {
  final String id;
  final double amount;
  final String paymentDate;
  final String? notes;
  final String? createdAt;

  const DebtPaymentDto({
    required this.id,
    required this.amount,
    required this.paymentDate,
    this.notes,
    this.createdAt,
  });

  factory DebtPaymentDto.fromJson(Map<String, dynamic> json) {
    return DebtPaymentDto(
      id: json['id']?.toString() ?? '',
      amount: _asDouble(json['amount']),
      paymentDate: json['paymentDate']?.toString() ?? '',
      notes: json['notes']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }

  factory DebtPaymentDto.fromCacheRow(Map<String, dynamic> row) {
    return DebtPaymentDto(
      id: row['id']?.toString() ?? '',
      amount: _asDouble(row['amount']),
      paymentDate: row['payment_date']?.toString() ?? '',
      notes: row['notes']?.toString(),
      createdAt: row['created_at']?.toString(),
    );
  }

  factory DebtPaymentDto.fromLocalRecord({
    required String id,
    required RecordPaymentInput input,
    required DateTime createdAt,
  }) {
    return DebtPaymentDto(
      id: id,
      amount: input.amount,
      paymentDate: input.paymentDate,
      notes: input.notes,
      createdAt: createdAt.toUtc().toIso8601String(),
    );
  }

  PaymentRecord toEntity({bool isDirty = false, String? syncError}) {
    final parsed =
        DebtDateParser.parseIsoDate(paymentDate) ?? DateTime.now();
    return PaymentRecord(
      id: id,
      amount: amount,
      date: parsed,
      notes: notes,
      paymentDate: paymentDate,
      createdAt: createdAt,
      isDirty: isDirty,
      syncError: syncError,
    );
  }

  Map<String, dynamic> toCacheRow({
    required String userId,
    required String debtId,
    required DateTime syncedAt,
    required bool isDirty,
    bool isDeleted = false,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();

    return {
      'id': id,
      'debt_id': debtId,
      'user_id': userId,
      'amount': amount,
      'payment_date': paymentDate,
      'notes': notes,
      'is_dirty': isDirty ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'server_updated_at': createdAt,
      'synced_at': syncedAt.toUtc().toIso8601String(),
      'created_at': createdAt ?? now,
    };
  }

  static double _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class DebtDto {
  final String id;
  final String personName;
  final String? personInitial;
  final String type;
  final double totalAmount;
  final double paidAmount;
  final double remaining;
  final String status;
  final String debtDate;
  final String? notes;
  final List<DebtPaymentDto> payments;
  final String? createdAt;
  final String? updatedAt;

  const DebtDto({
    required this.id,
    required this.personName,
    this.personInitial,
    required this.type,
    required this.totalAmount,
    required this.paidAmount,
    required this.remaining,
    required this.status,
    required this.debtDate,
    this.notes,
    this.payments = const [],
    this.createdAt,
    this.updatedAt,
  });

  static List<DebtDto> listFromEnvelope(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => DebtDto.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final items = map['items'];
      if (items is List) {
        return items
            .whereType<Map>()
            .map((item) => DebtDto.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    }

    return const [];
  }

  factory DebtDto.fromJson(Map<String, dynamic> json) {
    final paymentsJson = json['payments'];
    final payments = paymentsJson is List
        ? paymentsJson
            .whereType<Map>()
            .map(
              (item) => DebtPaymentDto.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : <DebtPaymentDto>[];

    final total = _asDouble(json['totalAmount']);
    final paid = _asDouble(json['paidAmount']);

    return DebtDto(
      id: json['id']?.toString() ?? '',
      personName: json['personName']?.toString() ?? '',
      personInitial: json['personInitial']?.toString(),
      type: json['type']?.toString() ?? 'lent',
      totalAmount: total,
      paidAmount: paid,
      remaining: json['remaining'] != null
          ? _asDouble(json['remaining'])
          : (total - paid).clamp(0.0, double.infinity),
      status: json['status']?.toString() ?? 'pending',
      debtDate: json['debtDate']?.toString() ?? '',
      notes: json['notes']?.toString(),
      payments: payments,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  factory DebtDto.fromCacheRow(
    Map<String, dynamic> row, {
    List<DebtPaymentDto> payments = const [],
  }) {
    return DebtDto(
      id: row['id']?.toString() ?? '',
      personName: row['person_name']?.toString() ?? '',
      personInitial: row['person_initial']?.toString(),
      type: row['type']?.toString() ?? 'lent',
      totalAmount: _asDouble(row['total_amount']),
      paidAmount: _asDouble(row['paid_amount']),
      remaining: _asDouble(row['remaining']),
      status: row['status']?.toString() ?? 'pending',
      debtDate: row['debt_date']?.toString() ?? '',
      notes: row['notes']?.toString(),
      payments: payments,
      createdAt: row['created_at']?.toString(),
      updatedAt: row['updated_at']?.toString(),
    );
  }

  factory DebtDto.fromCreateInput({
    required String id,
    required CreateDebtInput input,
    required DateTime createdAt,
  }) {
    return DebtDto(
      id: id,
      personName: input.personName,
      personInitial: input.personName.isNotEmpty
          ? input.personName[0].toUpperCase()
          : '?',
      type: input.type == DebtType.lent ? 'lent' : 'borrowed',
      totalAmount: input.totalAmount,
      paidAmount: 0,
      remaining: input.totalAmount,
      status: 'pending',
      debtDate: input.debtDate,
      notes: input.notes,
      payments: const [],
      createdAt: createdAt.toUtc().toIso8601String(),
      updatedAt: createdAt.toUtc().toIso8601String(),
    );
  }

  DebtDto applyUpdate(UpdateDebtInput input, {required DateTime updatedAt}) {
    final nextTotal = input.totalAmount ?? totalAmount;
    final nextRemaining = (nextTotal - paidAmount).clamp(0.0, double.infinity);
    final nextStatus = paidAmount >= nextTotal
        ? 'settled'
        : paidAmount > 0
            ? 'partial'
            : 'pending';

    return DebtDto(
      id: id,
      personName: input.personName ?? personName,
      personInitial: personInitial,
      type: input.type != null
          ? (input.type == DebtType.lent ? 'lent' : 'borrowed')
          : type,
      totalAmount: nextTotal,
      paidAmount: paidAmount,
      remaining: nextRemaining,
      status: nextStatus,
      debtDate: input.debtDate ?? debtDate,
      notes: input.notes ?? notes,
      payments: payments,
      createdAt: createdAt,
      updatedAt: updatedAt.toUtc().toIso8601String(),
    );
  }

  DebtDto applyPayment({
    required DebtPaymentDto payment,
    required DateTime updatedAt,
  }) {
    final nextPaid = paidAmount + payment.amount;
    final nextRemaining =
        (totalAmount - nextPaid).clamp(0.0, double.infinity);
    final nextStatus = nextPaid >= totalAmount
        ? 'settled'
        : nextPaid > 0
            ? 'partial'
            : 'pending';

    return DebtDto(
      id: id,
      personName: personName,
      personInitial: personInitial,
      type: type,
      totalAmount: totalAmount,
      paidAmount: nextPaid,
      remaining: nextRemaining,
      status: nextStatus,
      debtDate: debtDate,
      notes: notes,
      payments: [...payments, payment],
      createdAt: createdAt,
      updatedAt: updatedAt.toUtc().toIso8601String(),
    );
  }

  DebtEntity toEntity({bool isDirty = false, String? syncError}) {
    final debtType = type == 'borrowed' ? DebtType.borrowed : DebtType.lent;
    final parsedDate =
        DebtDateParser.parseIsoDate(debtDate) ?? DateTime.now();

    return DebtEntity(
      id: id,
      personName: personName,
      personInitial: personInitial ?? DebtEntity.deriveInitial(personName),
      type: debtType,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      remaining: remaining,
      debtDate: debtDate,
      date: parsedDate,
      notes: notes,
      payments: payments
          .map((payment) => payment.toEntity(isDirty: isDirty))
          .toList(),
      status: DebtEntity.statusFromApi(
        status,
        paidAmount: paidAmount,
        totalAmount: totalAmount,
      ),
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDirty: isDirty,
      syncError: syncError,
    );
  }

  Map<String, dynamic> toDebtCacheRow({
    required String userId,
    required DateTime syncedAt,
    required bool isDirty,
    bool isDeleted = false,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();

    return {
      'id': id,
      'user_id': userId,
      'person_name': personName,
      'person_initial': personInitial,
      'type': type,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'remaining': remaining,
      'status': status,
      'debt_date': debtDate,
      'notes': notes,
      'is_dirty': isDirty ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'server_updated_at': updatedAt,
      'synced_at': syncedAt.toUtc().toIso8601String(),
      'created_at': createdAt ?? now,
      'updated_at': updatedAt ?? now,
    };
  }

  static double _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}