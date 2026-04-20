import 'dart:convert';
import 'package:http/http.dart' as http;
import 'core_api.dart';
import '../models/auth_models.dart';

class AuthApi extends CoreApi {

  Future<AuthResponse> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${CoreApi.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return AuthResponse.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to login');
    }
  }

  Future<AuthResponse> register(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${CoreApi.baseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return AuthResponse.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to register');
    }
  }

  Future<void> logout(String accessToken, String refreshToken, Future<void> Function(String, String) onTokenRefreshed) async {
    await authenticatedPost(
      '/auth/logout',
      {},
      accessToken,
      refreshToken,
      onTokenRefreshed,
    );
  }

  Future<User> getProfile(String accessToken, String refreshToken, Future<void> Function(String, String) onTokenRefreshed) async {
    final response = await authenticatedGet(
      '/user/profile', // Using the dedicated profile endpoint instead of /auth/me
      accessToken,
      refreshToken,
      onTokenRefreshed,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      // Profile endpoint returns a UserProfileResponse with a 'data' block
      return User.fromJson(json['data'] ?? json); 
    } else {
      throw Exception('Failed to load profile');
    }
  }

  Future<void> updateProfile(String name, String phone, String accessToken, String refreshToken, Future<void> Function(String, String) onTokenRefreshed) async {
    final response = await authenticatedPut(
      '/user/profile',
      {'fullName': name, 'phone': phone},
      accessToken,
      refreshToken,
      onTokenRefreshed,
    );

    if (response.statusCode != 200) {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Failed to update profile');
    }
  }

  Future<double> getWalletBalance(String accessToken, String refreshToken, Future<void> Function(String, String) onTokenRefreshed) async {
    final response = await authenticatedGet(
      '/wallet/balance',
      accessToken,
      refreshToken,
      onTokenRefreshed,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (json['balance'] as num).toDouble();
    } else {
      throw Exception('Failed to fetch wallet balance');
    }
  }

  // ─── Merchant-specific APIs ──────────────────────────────────────────

  /// GET /api/merchant/profile
  /// Returns { success, data: { businessName, totalReceived, isActive } }
  Future<Map<String, dynamic>> getMerchantProfile(String accessToken, String refreshToken, Future<void> Function(String, String) onTokenRefreshed) async {
    final response = await authenticatedGet(
      '/merchant/profile',
      accessToken,
      refreshToken,
      onTokenRefreshed,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'] as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch merchant profile');
    }
  }

  /// GET /api/merchant/balance
  /// Returns { success, message, balance }
  Future<double> getMerchantBalance(String accessToken, String refreshToken, Future<void> Function(String, String) onTokenRefreshed) async {
    final response = await authenticatedGet(
      '/merchant/balance',
      accessToken,
      refreshToken,
      onTokenRefreshed,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (json['balance'] as num).toDouble();
    } else {
      throw Exception('Failed to fetch merchant balance');
    }
  }
}
