import '../domain/transaction_entity.dart';
import 'transaction_datasource.dart';

class TransactionRepository {

  List<TransactionEntity> getTransactions() {

    return TransactionDatasource.transactions;
  }
}