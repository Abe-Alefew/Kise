class TransactionModel{
  final String title;
  final String category;
  final double amount;
  final String type;
  final String date;
  final String icon;

  TransactionModel({
    required this.title,
    required this.category,
    required this.amount,
    required this.type,
    required this.date,
    required this.icon,
  });
}