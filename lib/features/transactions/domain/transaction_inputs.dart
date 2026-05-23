class CreateTransactionInput {
  final String type;
  final String title;
  final String category;
  final double amount;
  final String transactionDate;
  final String? accountId;
  final String? note;
  final String? iconKey;

  const CreateTransactionInput({
    required this.type,
    required this.title,
    required this.category,
    required this.amount,
    required this.transactionDate,
    this.accountId,
    this.note,
    this.iconKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'category': category,
      'amount': amount,
      'transactionDate': transactionDate,
      if (accountId != null) 'accountId': accountId,
      if (note != null) 'note': note,
      if (iconKey != null) 'iconKey': iconKey,
    };
  }
}

class UpdateTransactionInput {
  final String type;
  final String title;
  final String category;
  final double amount;
  final String transactionDate;
  final String? note;
  final String? iconKey;

  const UpdateTransactionInput({
    required this.type,
    required this.title,
    required this.category,
    required this.amount,
    required this.transactionDate,
    this.note,
    this.iconKey,
  });

  factory UpdateTransactionInput.fromCreate(CreateTransactionInput input) {
    return UpdateTransactionInput(
      type: input.type,
      title: input.title,
      category: input.category,
      amount: input.amount,
      transactionDate: input.transactionDate,
      note: input.note,
      iconKey: input.iconKey,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'category': category,
      'amount': amount,
      'transactionDate': transactionDate,
      if (note != null) 'note': note,
      if (iconKey != null) 'iconKey': iconKey,
    };
  }
}