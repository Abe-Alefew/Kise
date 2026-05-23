import 'package:flutter/material.dart';
import 'package:kise/features/transactions/data/transaction_icon_mapper.dart';
import 'package:kise/features/transactions/domain/transaction_inputs.dart';
import 'package:uuid/uuid.dart';

class TransactionEntity {
  final String id;
  final String title;
  final String category;
  final double amount;
  final String type;
  final String transactionDate;
  final String displayDate;
  final String month;
  final String? accountId;
  final String? accountName;
  final String? note;
  final String iconKey;
  final bool isDirty;
  final String? syncError;

  const TransactionEntity({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.type,
    required this.transactionDate,
    required this.displayDate,
    required this.month,
    this.accountId,
    this.accountName,
    this.note,
    this.iconKey = 'circle',
    this.isDirty = false,
    this.syncError,
  });

  String get date => displayDate;

  IconData get icon =>
      TransactionIconMapper.resolve(iconKey, category: category, type: type);

  factory TransactionEntity.optimisticFromInput(CreateTransactionInput input) {
    final now = DateTime.now().toUtc();
    final parsedDate = DateTime.parse('${input.transactionDate}T00:00:00.000Z');

    return TransactionEntity(
      id: const Uuid().v4(),
      title: input.title,
      category: input.category,
      amount: input.amount,
      type: input.type,
      transactionDate: input.transactionDate,
      displayDate: TransactionIconMapper.formatDisplayDate(parsedDate),
      month: TransactionIconMapper.formatMonthLabel(parsedDate),
      accountId: input.accountId,
      note: input.note,
      iconKey: input.iconKey ?? TransactionIconMapper.defaultIconKeyForCategory(input.category),
      isDirty: true,
    );
  }

  TransactionEntity copyWith({
    String? id,
    String? title,
    String? category,
    double? amount,
    String? type,
    String? transactionDate,
    String? displayDate,
    String? month,
    String? accountId,
    String? accountName,
    String? note,
    String? iconKey,
    bool? isDirty,
    String? syncError,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      transactionDate: transactionDate ?? this.transactionDate,
      displayDate: displayDate ?? this.displayDate,
      month: month ?? this.month,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      note: note ?? this.note,
      iconKey: iconKey ?? this.iconKey,
      isDirty: isDirty ?? this.isDirty,
      syncError: syncError ?? this.syncError,
    );
  }
}