class CardModel {
  final int cardId;
  final String cardUid;
  final bool isBlocked;
  final String? blockedReason;
  final String? linkedAt;
  final String? lastUsedAt;
  
  // These stay for UI compatibility or are derived
  final String studentName;
  final String studentId;
  final double balance;

  CardModel({
    required this.cardId,
    required this.cardUid,
    required this.isBlocked,
    this.blockedReason,
    this.linkedAt,
    this.lastUsedAt,
    required this.studentName,
    required this.studentId,
    required this.balance,
  });

  factory CardModel.fromJson(Map<String, dynamic> json, {required String studentName, required String studentId, required double balance}) {
    return CardModel(
      cardId: json['cardId'],
      cardUid: json['cardUid'],
      isBlocked: json['isBlocked'] ?? false,
      blockedReason: json['blockedReason'],
      linkedAt: json['linkedAt'],
      lastUsedAt: json['lastUsedAt'],
      studentName: studentName,
      studentId: studentId,
      balance: balance,
    );
  }
}

class MyCardsResponse {
  final bool success;
  final List<CardModel> cards;

  MyCardsResponse({required this.success, required this.cards});

  factory MyCardsResponse.fromJson(Map<String, dynamic> json, {required String studentName, required String studentId, required double balance}) {
    return MyCardsResponse(
      success: json['success'] ?? false,
      cards: (json['data'] as List)
          .map((c) => CardModel.fromJson(c, studentName: studentName, studentId: studentId, balance: balance))
          .toList(),
    );
  }
}