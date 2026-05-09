import '../domain/transaction_entity.dart';

class TransactionModel extends TransactionEntity {

  const TransactionModel({
    required super.title,
    required super.category,
    required super.amount,
    required super.type,
    required super.date,
    required super.icon,
  });
}