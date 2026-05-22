import 'package:flutter/foundation.dart';

enum DebtStatus { pending, partial, settled }

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
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

@immutable
class DebtEntity {
  final String id;
  final String personName;
  final String? personInitial;
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

  const DebtEntity({
    required this.id,
    required this.personName,
    this.personInitial,
    required this.type,
    required this.totalAmount,
    required this.paidAmount,
    required this.remaining,
    required this.debtDate,
    required this.date,
    this.notes,
    this.payments = const [],
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.isDirty = false,
    this.syncError,
  });

  double get computedRemaining => totalAmount - paidAmount;

  String get personInitialLabel =>
      personInitial ??
      (personName.isNotEmpty ? personName[0].toUpperCase() : '?');

  DebtStatus resolveStatus() {
    if (paidAmount >= totalAmount) {
      return DebtStatus.settled;
    }
    if (paidAmount > 0) {
      return DebtStatus.partial;
    }
    return DebtStatus.pending;
  }

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
        : (total - paid).clamp(0.0, double.infinity);

    final debtDateIso = json['debtDate']?.toString() ?? '';
    final parsedDate = DateTime.tryParse('${debtDateIso}T00:00:00.000Z') ??
        DateTime.tryParse(debtDateIso) ??
        DateTime.now();

    return DebtEntity(
      id: json['id']?.toString() ?? '',
      personName: json['personName']?.toString() ?? '',
      personInitial: json['personInitial']?.toString(),
      type: debtType,
      totalAmount: total,
      paidAmount: paid,
      remaining: remaining,
      debtDate: debtDateIso,
      date: parsedDate.toLocal(),
      notes: json['notes']?.toString(),
      payments: payments,
      status: _statusFromApi(json['status']?.toString(), paid, total),
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
      if (personInitial != null) 'personInitial': personInitial,
      'type': type == DebtType.lent ? 'lent' : 'borrowed',
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'remaining': remaining,
      'status': _statusToApi(status),
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
    return DebtEntity(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      personInitial: personInitial ?? this.personInitial,
      type: type ?? this.type,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      remaining: remaining ?? this.remaining,
      debtDate: debtDate ?? this.debtDate,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      payments: payments ?? this.payments,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDirty: isDirty ?? this.isDirty,
      syncError: clearSyncError ? null : (syncError ?? this.syncError),
    );
  }

  static DebtStatus _statusFromApi(
    String? apiStatus,
    double paid,
    double total,
  ) {
    switch (apiStatus) {
      case 'settled':
        return DebtStatus.settled;
      case 'partial':
        return DebtStatus.partial;
      case 'pending':
        return DebtStatus.pending;
      default:
        if (paid >= total) {
          return DebtStatus.settled;
        }
        if (paid > 0) {
          return DebtStatus.partial;
        }
        return DebtStatus.pending;
    }
  }

  static String _statusToApi(DebtStatus value) {
    switch (value) {
      case DebtStatus.settled:
        return 'settled';
      case DebtStatus.partial:
        return 'partial';
      case DebtStatus.pending:
        return 'pending';
    }
  }
}