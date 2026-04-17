import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_models.dart';

class CoreApi {
  // Use http://localhost:8080/api for Windows/Web/Desktop
  // Use http://10.0.2.2:8080/api for Android Emulator
  static const String baseUrl = 'http://192.168.0.120:8080/api';

  Future<AuthResponse> refreshToken(String refreshTokenStr) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshTokenStr}),
    );

    if (response.statusCode == 200) {
      return AuthResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Session expired. Please login again.');
    }
  }

  // Generic authenticated POST request with auto-refresh logic
  Future<http.Response> authenticatedPost(
    String path,
    Map<String, dynamic> body,
    String accessToken,
    String refreshTokenStr,
    Future<void> Function(String, String) onTokenRefreshed,
  ) async {
    final url = Uri.parse('$baseUrl$path');
    
    // 1. Try with current access token
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(body),
    );

    // 2. If 401, try to refresh
    if (response.statusCode == 401) {
      try {
        final authResponse = await refreshToken(refreshTokenStr);
        await onTokenRefreshed(authResponse.accessToken, authResponse.refreshToken);
        
        // 3. Retry with new token
        response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${authResponse.accessToken}',
          },
          body: jsonEncode(body),
        );
      } catch (e) {
        rethrow;
      }
    }

    return response;
  }

  // Generic authenticated GET request with auto-refresh logic
  Future<http.Response> authenticatedGet(
    String path,
    String accessToken,
    String refreshTokenStr,
    Future<void> Function(String, String) onTokenRefreshed,
  ) async {
    final url = Uri.parse('$baseUrl$path');
    
    // 1. Try with current access token
    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    // 2. If 401, try to refresh
    if (response.statusCode == 401) {
      try {
        final authResponse = await refreshToken(refreshTokenStr);
        await onTokenRefreshed(authResponse.accessToken, authResponse.refreshToken);
        
        // 3. Retry with new token
        response = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer ${authResponse.accessToken}',
          },
        );
      } catch (e) {
        rethrow;
      }
    }

    return response;
  }

  // Generic authenticated PUT request with auto-refresh logic
  Future<http.Response> authenticatedPut(
    String path,
    Map<String, dynamic> body,
    String accessToken,
    String refreshTokenStr,
    Future<void> Function(String, String) onTokenRefreshed,
  ) async {
    final url = Uri.parse('$baseUrl$path');

    // 1. Try with current access token
    var response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(body),
    );

    // 2. If 401, try to refresh
    if (response.statusCode == 401) {
      try {
        final authResponse = await refreshToken(refreshTokenStr);
        await onTokenRefreshed(authResponse.accessToken, authResponse.refreshToken);

        // 3. Retry with new token
        response = await http.put(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${authResponse.accessToken}',
          },
          body: jsonEncode(body),
        );
      } catch (e) {
        rethrow;
      }
    }

    return response;
  }

  // Generic authenticated PATCH request with auto-refresh logic
  Future<http.Response> authenticatedPatch(
    String path,
    Map<String, dynamic> body,
    String accessToken,
    String refreshTokenStr,
    Future<void> Function(String, String) onTokenRefreshed,
  ) async {
    final url = Uri.parse('$baseUrl$path');

    // 1. Try with current access token
    var response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(body),
    );

    // 2. If 401, try to refresh
    if (response.statusCode == 401) {
      try {
        final authResponse = await refreshToken(refreshTokenStr);
        await onTokenRefreshed(authResponse.accessToken, authResponse.refreshToken);

        // 3. Retry with new token
        response = await http.patch(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${authResponse.accessToken}',
          },
          body: jsonEncode(body),
        );
      } catch (e) {
        rethrow;
      }
    }

    return response;
  }

  // Generic authenticated DELETE request with auto-refresh logic
  Future<http.Response> authenticatedDelete(
    String path,
    String accessToken,
    String refreshTokenStr,
    Future<void> Function(String, String) onTokenRefreshed,
  ) async {
    final url = Uri.parse('$baseUrl$path');

    // 1. Try with current access token
    var response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    // 2. If 401, try to refresh
    if (response.statusCode == 401) {
      try {
        final authResponse = await refreshToken(refreshTokenStr);
        await onTokenRefreshed(authResponse.accessToken, authResponse.refreshToken);

        // 3. Retry with new token
        response = await http.delete(
          url,
          headers: {
            'Authorization': 'Bearer ${authResponse.accessToken}',
          },
        );
      } catch (e) {
        rethrow;
      }
    }

    return response;
  }
}
