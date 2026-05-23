import 'package:flutter/foundation.dart';
import 'package:kise/features/debt/domain/debt_inputs.dart';

enum DebtStatus { pending, partial, settled }

bool isPendingSyncDebtId(String debtId) => debtId.startsWith('optimistic-');

enum DebtType { lent, borrowed }

@immutable
class PaymentRecord {
  final String id;
  final double amount;
  final DateTime date;
  final String? notes;
  final String? paymentDate;
  final String? createdAt;
  final bool isDirty;
  final String? syncError;

  const PaymentRecord({
    required this.id,
    required this.amount,
    required this.date,
    this.notes,
    this.paymentDate,
    this.createdAt,
    this.isDirty = false,
    this.syncError,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    final isoDate = json['paymentDate']?.toString() ?? '';
    final parsedDate = DateTime.tryParse('${isoDate}T00:00:00.000Z') ??
        DateTime.tryParse(isoDate) ??
        DateTime.now();

    return PaymentRecord(
      id: json['id']?.toString() ?? '',
      amount: _readDouble(json['amount']),
      date: parsedDate.toLocal(),
      notes: json['notes']?.toString(),
      paymentDate: isoDate.isNotEmpty ? isoDate : null,
      createdAt: json['createdAt']?.toString(),
      isDirty: json['isDirty'] == true,
      syncError: json['syncError']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'paymentDate': paymentDate ?? _toIsoDate(date),
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'createdAt': createdAt,
      'isDirty': isDirty,
      if (syncError != null) 'syncError': syncError,
    };
  }

  PaymentRecord copyWith({
    String? id,
    double? amount,
    DateTime? date,
    String? notes,
    String? paymentDate,
    String? createdAt,
    bool? isDirty,
    String? syncError,
    bool clearSyncError = false,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      paymentDate: paymentDate ?? this.paymentDate,
      createdAt: createdAt ?? this.createdAt,
      isDirty: isDirty ?? this.isDirty,
      syncError: clearSyncError ? null : (syncError ?? this.syncError),
    );
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _toIsoDate(DateTime value) {
    return DebtDateParser.toIsoDate(value);
  }
}

@immutable
class DebtEntity {
  final String id;
  final String personName;

  /// Single-character avatar label; never null (UI reads this directly).
  final String personInitial;

  final DebtType type;
  final double totalAmount;
  final double paidAmount;
  final double remaining;
  final String debtDate;
  final DateTime date;
  final String? notes;
  final List<PaymentRecord> payments;
  final DebtStatus status;
  final String? createdAt;
  final String? updatedAt;
  final bool isDirty;
  final String? syncError;

  DebtEntity({
    required this.id,
    required this.personName,
    String? personInitial,
    required this.type,
    required this.totalAmount,
    this.paidAmount = 0,
    double? remaining,
    String? debtDate,
    required this.date,
    this.notes,
    this.payments = const [],
    DebtStatus? status,
    this.createdAt,
    this.updatedAt,
    this.isDirty = false,
    this.syncError,
  })  : personInitial = personInitial ?? deriveInitial(personName),
        remaining = remaining ?? deriveRemaining(totalAmount, paidAmount),
        debtDate = debtDate ?? DebtDateParser.toIsoDate(date),
        status = status ?? deriveStatus(paidAmount: paidAmount, totalAmount: totalAmount);

  double get computedRemaining => deriveRemaining(totalAmount, paidAmount);

  DebtStatus resolveStatus() => deriveStatus(
        paidAmount: paidAmount,
        totalAmount: totalAmount,
        apiStatus: DebtEntity.statusToApi(status),
      );

  factory DebtEntity.fromJson(Map<String, dynamic> json) {
    final paymentsJson = json['payments'];
    final payments = paymentsJson is List
        ? paymentsJson
            .whereType<Map<String, dynamic>>()
            .map(PaymentRecord.fromJson)
            .toList()
        : <PaymentRecord>[];

    final typeString = json['type']?.toString() ?? 'lent';
    final debtType =
        typeString == 'borrowed' ? DebtType.borrowed : DebtType.lent;

    final total = PaymentRecord._readDouble(json['totalAmount']);
    final paid = PaymentRecord._readDouble(json['paidAmount']);
    final remaining = json['remaining'] != null
        ? PaymentRecord._readDouble(json['remaining'])
        : deriveRemaining(total, paid);

    final debtDateIso = json['debtDate']?.toString() ?? '';
    final parsedDate = DebtDateParser.parseIsoDate(debtDateIso) ?? DateTime.now();

    return DebtEntity(
      id: json['id']?.toString() ?? '',
      personName: json['personName']?.toString() ?? '',
      personInitial: json['personInitial']?.toString(),
      type: debtType,
      totalAmount: total,
      paidAmount: paid,
      remaining: remaining,
      debtDate: debtDateIso.isNotEmpty
          ? debtDateIso
          : DebtDateParser.toIsoDate(parsedDate),
      date: parsedDate,
      notes: json['notes']?.toString(),
      payments: payments,
      status: statusFromApi(
        json['status']?.toString(),
        paidAmount: paid,
        totalAmount: total,
      ),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      isDirty: json['isDirty'] == true,
      syncError: json['syncError']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'personName': personName,
      'personInitial': personInitial,
      'type': type == DebtType.lent ? 'lent' : 'borrowed',
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'remaining': remaining,
      'status': statusToApi(status),
      'debtDate': debtDate,
      if (notes != null) 'notes': notes,
      'payments': payments.map((payment) => payment.toJson()).toList(),
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
      'isDirty': isDirty,
      if (syncError != null) 'syncError': syncError,
    };
  }

  DebtEntity copyWith({
    String? id,
    String? personName,
    String? personInitial,
    DebtType? type,
    double? totalAmount,
    double? paidAmount,
    double? remaining,
    String? debtDate,
    DateTime? date,
    String? notes,
    List<PaymentRecord>? payments,
    DebtStatus? status,
    String? createdAt,
    String? updatedAt,
    bool? isDirty,
    String? syncError,
    bool clearSyncError = false,
  }) {
    final nextPersonName = personName ?? this.personName;
    final nextTotal = totalAmount ?? this.totalAmount;
    final nextPaid = paidAmount ?? this.paidAmount;
    final nextDate = date ?? this.date;

    return DebtEntity(
      id: id ?? this.id,
      personName: nextPersonName,
      personInitial: personInitial ?? this.personInitial,
      type: type ?? this.type,
      totalAmount: nextTotal,
      paidAmount: nextPaid,
      remaining: remaining ?? deriveRemaining(nextTotal, nextPaid),
      debtDate: debtDate ?? this.debtDate,
      date: nextDate,
      notes: notes ?? this.notes,
      payments: payments ?? this.payments,
      status: status ??
          deriveStatus(
            paidAmount: nextPaid,
            totalAmount: nextTotal,
            apiStatus: DebtEntity.statusToApi(this.status),
          ),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDirty: isDirty ?? this.isDirty,
      syncError: clearSyncError ? null : (syncError ?? this.syncError),
    );
  }

  /// Maps API/cache status strings to [DebtStatus] (shared with DTO layer).
  static DebtStatus statusFromApi(
    String? apiStatus, {
    required double paidAmount,
    required double totalAmount,
  }) {
    switch (apiStatus) {
      case 'settled':
        return DebtStatus.settled;
      case 'partial':
        return DebtStatus.partial;
      case 'pending':
        return DebtStatus.pending;
      default:
        return deriveStatus(
          paidAmount: paidAmount,
          totalAmount: totalAmount,
        );
    }
  }

  static String statusToApi(DebtStatus value) {
    switch (value) {
      case DebtStatus.settled:
        return 'settled';
      case DebtStatus.partial:
        return 'partial';
      case DebtStatus.pending:
        return 'pending';
    }
  }

  static String deriveInitial(String personName) {
    final trimmed = personName.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    return trimmed[0].toUpperCase();
  }

  static double deriveRemaining(double totalAmount, double paidAmount) {
    return (totalAmount - paidAmount).clamp(0.0, double.infinity);
  }

  static DebtStatus deriveStatus({
    required double paidAmount,
    required double totalAmount,
    String? apiStatus,
  }) {
    if (apiStatus != null && apiStatus.isNotEmpty) {
      return statusFromApi(
        apiStatus,
        paidAmount: paidAmount,
        totalAmount: totalAmount,
      );
    }
    if (paidAmount >= totalAmount && totalAmount > 0) {
      return DebtStatus.settled;
    }
    if (paidAmount > 0) {
      return DebtStatus.partial;
    }
    return DebtStatus.pending;
  }
}










































































































































































