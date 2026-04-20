import 'dart:convert';
import 'core_api.dart';
import '../models/transaction_model.dart';

class SharedApi extends CoreApi {

  Future<TransactionPageData> getTransactionHistory(
    int page,
    int size,
    String? type,
    String accessToken,
    String refreshToken,
    Future<void> Function(String, String) onTokenRefreshed,
  ) async {
    String query = '?page=$page&size=$size';
    if (type != null && type.isNotEmpty && type != 'ALL') {
      query += '&type=$type';
    }

    final response = await authenticatedGet(
      '/transactions/history$query',
      accessToken,
      refreshToken,
      onTokenRefreshed,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return TransactionPageData.fromJson(json['data']);
    } else {
      throw Exception('Failed to fetch transaction history');
    }
  }

  Future<TransactionDetailModel> getTransactionDetail(
    int id,
    String accessToken,
    String refreshToken,
    Future<void> Function(String, String) onTokenRefreshed,
  ) async {
    final response = await authenticatedGet(
      '/transactions/$id',
      accessToken,
      refreshToken,
      onTokenRefreshed,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return TransactionDetailModel.fromJson(json['data']);
    } else {
      throw Exception('Failed to fetch transaction detail');
    }
  }

  /// GET /api/merchant/transactions — merchant-specific transaction history
  Future<TransactionPageData> getMerchantTransactionHistory(
    int page,
    int size,
    String? type,
    String accessToken,
    String refreshToken,
    Future<void> Function(String, String) onTokenRefreshed,
  ) async {
    String query = '?page=$page&size=$size';
    if (type != null && type.isNotEmpty && type != 'ALL') {
      query += '&type=$type';
    }

    final response = await authenticatedGet(
      '/merchant/transactions$query',
      accessToken,
      refreshToken,
      onTokenRefreshed,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return TransactionPageData.fromJson(json['data']);
    } else {
      throw Exception('Failed to fetch merchant transactions');
    }
  }
}
