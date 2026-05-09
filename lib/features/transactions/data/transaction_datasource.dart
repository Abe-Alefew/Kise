import 'transaction_model.dart';

class TransactionDatasource {

  static List<TransactionModel> transactions = [

    TransactionModel(
      title: "Education",
      category: "Learning",
      amount: 20000,
      type: "Expense",
      date: "Apr 15",
      icon: "📚",
    ),

    TransactionModel(
      title: "Investment",
      category: "Stocks",
      amount: 1300,
      type: "Income",
      date: "Apr 14",
      icon: "📈",
    ),

    TransactionModel(
      title: "Salary",
      category: "Work",
      amount: 15000,
      type: "Income",
      date: "Apr 10",
      icon: "💼",
    ),

    TransactionModel(
      title: "Transport",
      category: "Travel",
      amount: 300,
      type: "Expense",
      date: "Apr 08",
      icon: "🚌",
    ),

    TransactionModel(
      title: "Netflix",
      category: "Entertainment",
      amount: 500,
      type: "Expense",
      date: "Apr 05",
      icon: "🎬",
    ),

    TransactionModel(
      title: "Freelance",
      category: "Work",
      amount: 4000,
      type: "Income",
      date: "Apr 01",
      icon: "💻",
    ),
  ];
}