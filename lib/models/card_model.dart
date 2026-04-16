class CardModel {
  final String cardId;
  final String studentName;
  final String studentId;
  final double balance;
  final bool isBlocked;

  CardModel({
    required this.cardId,
    required this.studentName,
    required this.studentId,
    required this.balance,
    required this.isBlocked,
  });
}