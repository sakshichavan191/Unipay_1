import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_models.dart';
import '../services/auth_api.dart';
import '../core/globals.dart';

class AuthProvider with ChangeNotifier {
  final AuthApi _apiService = AuthApi();
  final _storage = const FlutterSecureStorage();
  
  User? _user;
  String? _token;
  String? _refreshToken;
  bool _isLoading = false;

  User? get user => _user;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  Future<void> init() async {
    _token = await _storage.read(key: 'access_token');
    _refreshToken = await _storage.read(key: 'refresh_token');
    String? userJson = await _storage.read(key: 'user_profile');
    if (userJson != null) {
      _user = User.fromJson(jsonDecode(userJson));
      // Refresh rich profile in background if we have a token
      fetchProfile(); 
    }
    notifyListeners();
  }

  Future<void> fetchProfile() async {
    if (_token == null || _refreshToken == null) return;
    try {
      final currentRole = _user?.role;
      
      if (currentRole == 'MERCHANT') {
        // Use merchant-specific profile endpoint
        await _fetchMerchantProfile();
      } else {
        // Students and admins use the generic user profile endpoint
        final updatedUser = await _apiService.getProfile(
          _token!,
          _refreshToken!,
          updateTokens,
        );
        
        final currentBalance = _user?.walletBalance ?? 0.0;
        
        _user = User(
          id: updatedUser.id,
          name: updatedUser.name,
          email: updatedUser.email,
          role: updatedUser.role,
          phone: updatedUser.phone,
          studentId: updatedUser.studentId,
          businessName: updatedUser.businessName,
          walletBalance: currentBalance,
          isActive: updatedUser.isActive,
          createdAt: updatedUser.createdAt,
        );
        
        await _storage.write(key: 'user_profile', value: jsonEncode(_user!.toJson()));
        notifyListeners();
      }
      
      // Fetch the real balance from role-appropriate endpoint
      await fetchBalance();
    } catch (e) {
      debugPrint("Profile fetch failed: $e");
      if (e.toString().contains('Session expired')) {
        await logout();
      }
    }
  }

  Future<void> _fetchMerchantProfile() async {
    try {
      final data = await _apiService.getMerchantProfile(
        _token!,
        _refreshToken!,
        updateTokens,
      );
      
      // Merge merchant-specific fields into our User model
      _user = User(
        id: _user!.id,
        name: _user!.name,
        email: _user!.email,
        role: _user!.role,
        phone: _user!.phone,
        studentId: _user!.studentId,
        businessName: data['businessName'] ?? _user!.businessName,
        walletBalance: (data['totalReceived'] as num?)?.toDouble() ?? _user!.walletBalance,
        isActive: data['isActive'] ?? data['active'] ?? _user!.isActive,
        createdAt: _user!.createdAt,
      );
      
      await _storage.write(key: 'user_profile', value: jsonEncode(_user!.toJson()));
      notifyListeners();
    } catch (e) {
      debugPrint("Merchant profile fetch failed: $e");
    }
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      final response = await _apiService.login(email, password);
      await _saveSession(response);
      await fetchProfile(); // Get rich data (balance, etc.) immediately after login
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register(String name, String email, String password, String studentId) async {
    _setLoading(true);
    try {
      final response = await _apiService.register({
        'name': name,
        'email': email,
        'password': password,
        'studentId': studentId,
      });
      await _saveSession(response);
      await fetchProfile();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTokens(String access, String refresh) async {
    _token = access;
    _refreshToken = refresh;
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      if (_token != null && _refreshToken != null) {
        await _apiService.logout(_token!, _refreshToken!, updateTokens);
      }
    } catch (e) {
      debugPrint('Backend logout failed: $e');
    } finally {
      _user = null;
      _token = null;
      _refreshToken = null;
      await _storage.deleteAll();
      notifyListeners();
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Future<void> _saveSession(AuthResponse response) async {
    _user = response.user;
    _token = response.accessToken;
    _refreshToken = response.refreshToken;
    
    await _storage.write(key: 'access_token', value: _token);
    await _storage.write(key: 'refresh_token', value: _refreshToken);
    await _storage.write(key: 'user_profile', value: jsonEncode(_user!.toJson()));
    
    notifyListeners();
  }

  Future<void> updateUserInfo(String name, String phone) async {
    if (_token == null || _refreshToken == null) return;
    
    _setLoading(true);
    try {
      await _apiService.updateProfile(
        name,
        phone,
        _token!,
        _refreshToken!,
        updateTokens,
      );
      
      // Update local state by merging changes
      _user = User(
        id: _user!.id,
        name: name,
        email: _user!.email,
        role: _user!.role,
        phone: phone,
        studentId: _user!.studentId,
        businessName: _user!.businessName,
        walletBalance: _user!.walletBalance,
        isActive: _user!.isActive,
        createdAt: _user!.createdAt,
      );
      
      await _storage.write(key: 'user_profile', value: jsonEncode(_user!.toJson()));
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchBalance() async {
    if (_token == null || _refreshToken == null || _user == null) return;
    try {
      double balance;
      
      if (_user!.role == 'MERCHANT') {
        // Hit merchant-specific balance endpoint
        balance = await _apiService.getMerchantBalance(
          _token!,
          _refreshToken!,
          updateTokens,
        );
      } else {
        // Students use the wallet balance endpoint
        balance = await _apiService.getWalletBalance(
          _token!,
          _refreshToken!,
          updateTokens,
        );
      }
      
      _user = User(
        id: _user!.id,
        name: _user!.name,
        email: _user!.email,
        role: _user!.role,
        phone: _user!.phone,
        studentId: _user!.studentId,
        businessName: _user!.businessName,
        walletBalance: balance,
        isActive: _user!.isActive,
        createdAt: _user!.createdAt,
      );
      
      await _storage.write(key: 'user_profile', value: jsonEncode(_user!.toJson()));
      notifyListeners();
    } catch (e) {
      debugPrint("Balance fetch failed: $e");
      if (e.toString().contains('Session expired')) {
        await logout();
      }
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
