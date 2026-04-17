import 'dart:convert';
import '../models/auth_models.dart';
import 'core_api.dart';

class AdminApi extends CoreApi {
  Future<User> registerMerchant(
    Map<String, String> data,
    String accessToken,
    String refreshToken,
    Future<void> Function(String, String) onTokenRefreshed,
  ) async {
    final response = await authenticatedPost(
      '/admin/merchants/register',
      data,
      accessToken,
      refreshToken,
      onTokenRefreshed,
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return User.fromJson(json);
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Failed to register merchant');
    }
  }

  Future<List<User>> getAllMerchants(
    String accessToken,
    String refreshToken,
    Future<void> Function(String, String) onTokenRefreshed,
  ) async {
    final response = await authenticatedGet(
      '/admin/merchants',
      accessToken,
      refreshToken,
      onTokenRefreshed,
    );

    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);
      return json.map((m) => User.fromJson(m)).toList();
    } else {
      throw Exception('Failed to fetch merchants');
    }
  }

  Future<Map<String, dynamic>> getUsers(
    int page,
    int size,
    String? role,
    String accessToken,
    String refreshToken,
    Future<void> Function(String, String) onTokenRefreshed,
  ) async {
    String url = '/admin/users?page=$page&size=$size';
    if (role != null && role != 'ALL') {
      url += '&role=$role';
    }

    final response = await authenticatedGet(
      url,
      accessToken,
      refreshToken,
      onTokenRefreshed,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Failed to fetch users');
    }
  }

  Future<Map<String, dynamic>> getUserDetails(
    int id,
    String accessToken,
    String refreshToken,
    Future<void> Function(String, String) onTokenRefreshed,
  ) async {
    final response = await authenticatedGet(
      '/admin/users/$id',
      accessToken,
      refreshToken,
      onTokenRefreshed,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Failed to fetch user details');
    }
  }

  Future<void> blockUser(
    int id,
    String? reason,
    String accessToken,
    String refreshToken,
    Future<void> Function(String, String) onTokenRefreshed,
  ) async {
    final response = await authenticatedPatch(
      '/admin/users/$id/block',
      reason != null ? {'reason': reason} : {},
      accessToken,
      refreshToken,
      onTokenRefreshed,
    );

    if (response.statusCode != 200) {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Failed to block user');
    }
  }

  Future<void> unblockUser(
    int id,
    String accessToken,
    String refreshToken,
    Future<void> Function(String, String) onTokenRefreshed,
  ) async {
    final response = await authenticatedPatch(
      '/admin/users/$id/unblock',
      {},
      accessToken,
      refreshToken,
      onTokenRefreshed,
    );

    if (response.statusCode != 200) {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Failed to unblock user');
    }
  }

  // --- CARD MANAGEMENT ---

  Future<void> registerCard(
    String cardUid,
    String accessToken,
    String refreshToken,
    Future<void> Function(String, String) onTokenRefreshed,
  ) async {
    final response = await authenticatedPost(
      '/admin/cards',
      {'cardUid': cardUid},
      accessToken,
      refreshToken,
      onTokenRefreshed,
    );

    if (response.statusCode != 201) {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Failed to register card');
    }
  }

  Future<void> linkCard(
    String cardUid,
    int userId,
    String accessToken,
    String refreshToken,
    Future<void> Function(String, String) onTokenRefreshed,
  ) async {
    final response = await authenticatedPost(
      '/admin/cards/link',
      {
        'cardUid': cardUid,
        'userId': userId,
      },
      accessToken,
      refreshToken,
      onTokenRefreshed,
    );

    if (response.statusCode != 200) {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Failed to link card');
    }
  }

  Future<void> unlinkCard(
    String cardUid,
    String accessToken,
    String refreshToken,
    Future<void> Function(String, String) onTokenRefreshed,
  ) async {
    final response = await authenticatedDelete(
      '/admin/cards/$cardUid/unlink',
      accessToken,
      refreshToken,
      onTokenRefreshed,
    );

    if (response.statusCode != 200) {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Failed to unlink card');
    }
  }

  Future<void> setCardStatus(
    String cardUid,
    bool activate,
    String accessToken,
    String refreshToken,
    Future<void> Function(String, String) onTokenRefreshed,
  ) async {
    final action = activate ? 'activate' : 'deactivate';
    final response = await authenticatedPatch(
      '/admin/cards/$cardUid/$action',
      {},
      accessToken,
      refreshToken,
      onTokenRefreshed,
    );

    if (response.statusCode != 200) {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Failed to $action card');
    }
  }
}
