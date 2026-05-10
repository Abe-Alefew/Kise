import 'transaction_model.dart';

class TransactionDatasource {

  static List<TransactionModel> transactions = [

    /// INCOME
    TransactionModel(
      title: "Salary",
      category: "Salary",
      amount: 30000,
      type: "Income",
      date: "Apr 15",
      icon: "💼",
      month: "Apr",
    ),

    TransactionModel(
      title: "Freelance",
      category: "Freelance",
      amount: 12000,
      type: "Income",
      date: "Apr 10",
      icon: "💻",
      month: "Apr",
    ),

    TransactionModel(
      title: "Investment",
      category: "Investment",
      amount: 8000,
      type: "Income",
      date: "Apr 08",
      icon: "📈",
      month: "Apr",
    ),

    /// EXPENSE
    TransactionModel(
      title: "Education",
      category: "Education",
      amount: 20000,
      type: "Expense",
      date: "Apr 15",
      icon: "🎓",
      month: "Apr",
    ),

    TransactionModel(
      title: "Netflix",
      category: "Entertainment",
      amount: 1000,
      type: "Expense",
      date: "Apr 14",
      icon: "🎬",
      month: "Apr",
    ),

    TransactionModel(
      title: "Transport",
      category: "Transport",
      amount: 3000,
      type: "Expense",
      date: "Apr 12",
      icon: "🚌",
      month: "Apr",
    ),
  ];
}