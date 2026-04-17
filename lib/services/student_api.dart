import 'dart:convert';
import 'core_api.dart';
import '../models/auth_models.dart';
import '../models/card_model.dart';
import '../models/payment_models.dart';

class StudentApi extends CoreApi {
  
  Future<List<CardModel>> fetchMyCards(String accessToken, String refreshToken, User user, Future<void> Function(String, String) onTokenRefreshed) async {
    final response = await authenticatedGet(
      '/cards/my-cards',
      accessToken,
      refreshToken,
      onTokenRefreshed,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final cardsResponse = MyCardsResponse.fromJson(
        json, 
        studentName: user.name, 
        studentId: user.studentId ?? 'STU001', 
        balance: user.walletBalance ?? 0.0
      );
      return cardsResponse.cards;
    } else {
      throw Exception('Failed to fetch cards');
    }
  }

  Future<void> toggleCardStatus(String cardUid, String action, String reason, String accessToken, String refreshToken, Future<void> Function(String, String) onTokenRefreshed) async {
    final response = await authenticatedPatch(
      '/cards/$cardUid',
      {
        'action': action,
        'reason': reason,
      },
      accessToken,
      refreshToken,
      onTokenRefreshed,
    );

    if (response.statusCode != 200) {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Failed to update card status');
    }
  }

  Future<RechargeOrderResponse> createRechargeOrder(int amount, String accessToken, String refreshToken, Future<void> Function(String, String) onTokenRefreshed) async {
    final response = await authenticatedPost(
      '/wallet/create-recharge-order',
      {'amount': amount},
      accessToken,
      refreshToken,
      onTokenRefreshed,
    );

    if (response.statusCode == 200) {
      return RechargeOrderResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create recharge order');
    }
  }

  Future<void> verifyPayment(VerifyPaymentRequest request, String accessToken, String refreshToken, Future<void> Function(String, String) onTokenRefreshed) async {
    final response = await authenticatedPost(
      '/wallet/verify-payment',
      request.toJson(),
      accessToken,
      refreshToken,
      onTokenRefreshed,
    );

    if (response.statusCode != 200) {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Payment verification failed');
    }
  }
}
