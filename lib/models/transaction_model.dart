class TransactionModel {
  final String id;
  final double amount;
  final String type;   // 'debit' or 'credit'
  final String vendor;
  final DateTime timestamp;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.vendor,
    required this.timestamp,
  });
}