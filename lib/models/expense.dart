class Expense {
  final int id;
  final int userId;
  final double originalAmount;
  final String originalCurrency;
  final double convertedAmount;
  final String convertedCurrency;
  final double conversionRate;
  final String message;
  final String? source;
  final String? reference;
  final DateTime transactionDate;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.userId,
    required this.originalAmount,
    required this.originalCurrency,
    required this.convertedAmount,
    required this.convertedCurrency,
    required this.conversionRate,
    required this.message,
    this.source,
    this.reference,
    required this.transactionDate,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      userId: json['user_id'],
      originalAmount: double.parse(json['original_amount'].toString()),
      originalCurrency: json['original_currency'],
      convertedAmount: double.parse(json['converted_amount'].toString()),
      convertedCurrency: json['converted_currency'],
      conversionRate: double.parse(json['conversion_rate'].toString()),
      message: json['message'],
      source: json['source'],
      reference: json['reference'],
      transactionDate: DateTime.parse(json['transaction_date']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool isDifferentCurrency() {
    return originalCurrency != convertedCurrency;
  }
}
