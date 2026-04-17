class TransactionPageData {
  final List<TransactionModel> transactions;
  final int totalPages;
  final int totalElements;
  final int currentPage;

  TransactionPageData({
    required this.transactions,
    required this.totalPages,
    required this.totalElements,
    required this.currentPage,
  });

  factory TransactionPageData.fromJson(Map<String, dynamic> json) {
    return TransactionPageData(
      transactions: (json['transactions'] as List?)
              ?.map((e) => TransactionModel.fromJson(e))
              .toList() ??
          [],
      totalPages: json['totalPages'] ?? 0,
      totalElements: json['totalElements'] ?? 0,
      currentPage: json['currentPage'] ?? 0,
    );
  }
}

class TransactionModel {
  final int id;
  final String type; // "NFC_PAYMENT" or "RECHARGE"
  final double amount;
  final String status;
  final String direction; // "DEBIT" or "CREDIT"
  final String? counterparty;
  final String? cardUid;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    required this.direction,
    this.counterparty,
    this.cardUid,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      type: json['type'] ?? 'UNKNOWN',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'UNKNOWN',
      direction: json['direction'] ?? 'UNKNOWN',
      counterparty: json['counterparty'],
      cardUid: json['cardUid'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }
}

class TransactionDetailModel {
  final int id;
  final String type;
  final double amount;
  final String status;
  final String direction;
  final String? senderName;
  final String? receiverName;
  final String? cardUid;
  final int? merchantId;
  final DateTime createdAt;

  TransactionDetailModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    required this.direction,
    this.senderName,
    this.receiverName,
    this.cardUid,
    this.merchantId,
    required this.createdAt,
  });

  factory TransactionDetailModel.fromJson(Map<String, dynamic> json) {
    return TransactionDetailModel(
      id: json['id'],
      type: json['type'] ?? 'UNKNOWN',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'UNKNOWN',
      direction: json['direction'] ?? 'UNKNOWN',
      senderName: json['senderName'],
      receiverName: json['receiverName'],
      cardUid: json['cardUid'],
      merchantId: json['merchantId'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }
}