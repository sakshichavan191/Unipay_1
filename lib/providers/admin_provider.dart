import 'package:flutter/material.dart';
import '../models/auth_models.dart';
import '../models/admin_models.dart';
import '../services/admin_api.dart';
import 'auth_provider.dart';

class AdminProvider with ChangeNotifier {
  final AdminApi _apiService = AdminApi();
  final AuthProvider _authProvider;

  bool _isLoading = false;
  bool _isMoreLoading = false;
  String? _errorMessage;
  
  List<User> _users = [];
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  String _currentRole = 'ALL';
  final int _pageSize = 10;

  List<User> _merchants = [];
  AdminUserProfileData? _selectedUserDetails;

  AdminProvider(this._authProvider);

  // --- GETTERS ---
  bool get isLoading => _isLoading;
  bool get isMoreLoading => _isMoreLoading;
  String? get errorMessage => _errorMessage;
  List<User> get users => _users;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalElements => _totalElements;
  String get currentRole => _currentRole;
  bool get hasMore => _currentPage < _totalPages - 1;
  List<User> get merchants => _merchants;
  AdminUserProfileData? get selectedUserDetails => _selectedUserDetails;

  // --- USER LISTING & FILTERING ---

  Future<void> fetchUsers({String? role, bool isInitial = true}) async {
    if (!_authProvider.isAuthenticated) return;

    if (isInitial) {
      _isLoading = true;
      _currentPage = 0;
      _users = [];
    } else {
      _isMoreLoading = true;
    }
    
    if (role != null) _currentRole = role;
    
    _errorMessage = null;
    notifyListeners();

    try {
      final json = await _apiService.getUsers(
        _currentPage,
        _pageSize,
        _currentRole,
        _authProvider.token!,
        _authProvider.refreshToken!,
        _authProvider.updateTokens,
      );

      final response = AdminUserListResponse.fromJson(json);
      
      if (isInitial) {
        _users = response.data.users;
      } else {
        _users.addAll(response.data.users);
      }
      
      _totalPages = response.data.totalPages;
      _totalElements = response.data.totalElements;
      _currentPage = response.data.currentPage;
      
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      if (isInitial) {
        _isLoading = false;
      } else {
        _isMoreLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> fetchMoreUsers() async {
    if (!hasMore || _isMoreLoading || _isLoading) return;
    _currentPage++;
    await fetchUsers(isInitial: false);
  }

  Future<void> setRoleFilter(String role) async {
    if (_currentRole == role) return;
    _currentRole = role;
    await fetchUsers(role: role, isInitial: true);
  }

  // --- USER DETAIL & DISCIPLINE ---

  Future<void> fetchUserDetails(int id) async {
    if (!_authProvider.isAuthenticated) return;

    // Only show loading spinner on first load, NOT on refresh after block/unblock
    final isFirstLoad = _selectedUserDetails == null || _selectedUserDetails?.userId != id;
    if (isFirstLoad) {
      _setLoading(true);
      _selectedUserDetails = null;
      notifyListeners();
    }
    _errorMessage = null;

    try {
      final json = await _apiService.getUserDetails(
        id,
        _authProvider.token!,
        _authProvider.refreshToken!,
        _authProvider.updateTokens,
      );
      final response = AdminUserProfileResponse.fromJson(json);
      _selectedUserDetails = response.data;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      if (isFirstLoad) _setLoading(false);
      notifyListeners();
    }
  }

  Future<bool> toggleUserBlock(int id, {bool block = true, String? reason}) async {
    if (!_authProvider.isAuthenticated) return false;

    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      if (block) {
        await _apiService.blockUser(
          id,
          reason,
          _authProvider.token!,
          _authProvider.refreshToken!,
          _authProvider.updateTokens,
        );
      } else {
        await _apiService.unblockUser(
          id,
          _authProvider.token!,
          _authProvider.refreshToken!,
          _authProvider.updateTokens,
        );
      }
      
      // Refresh: do NOT pass isFirstLoad flag — just re-fetch silently
      if (_selectedUserDetails?.userId == id) {
        await fetchUserDetails(id);
      }
      
      // Update entry in the main list if present
      final index = _users.indexWhere((u) => u.id == id);
      if (index != -1) {
        _users[index] = User(
          id: _users[index].id,
          name: _users[index].name,
          email: _users[index].email,
          role: _users[index].role,
          phone: _users[index].phone,
          studentId: _users[index].studentId,
          businessName: _users[index].businessName,
          walletBalance: _users[index].walletBalance,
          isActive: _users[index].isActive,
          isBlocked: block,
          createdAt: _users[index].createdAt,
        );
      }
      
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // --- MERCHANT MANAGEMENT ---

  Future<bool> registerMerchant({
    required String name,
    required String email,
    required String password,
    required String businessName,
  }) async {
    if (!_authProvider.isAuthenticated) return false;

    _setLoading(true);
    _errorMessage = null;

    try {
      await _apiService.registerMerchant(
        {
          'name': name,
          'email': email,
          'password': password,
          'businessName': businessName,
        },
        _authProvider.token!,
        _authProvider.refreshToken!,
        _authProvider.updateTokens,
      );
      
      // Refresh list after success
      await loadMerchants();
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<void> loadMerchants() async {
    if (!_authProvider.isAuthenticated) return;

    _setLoading(true);
    try {
      _merchants = await _apiService.getAllMerchants(
        _authProvider.token!,
        _authProvider.refreshToken!,
        _authProvider.updateTokens,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // --- CARD ACTIONS ---

  Future<bool> registerCard(String cardUid) async {
    if (!_authProvider.isAuthenticated) return false;
    _setLoading(true);
    _errorMessage = null;
    try {
      await _apiService.registerCard(
        cardUid,
        _authProvider.token!,
        _authProvider.refreshToken!,
        _authProvider.updateTokens,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> linkCard(String cardUid, int userId) async {
    if (!_authProvider.isAuthenticated) return false;
    _setLoading(true);
    _errorMessage = null;
    try {
      await _apiService.linkCard(
        cardUid,
        userId,
        _authProvider.token!,
        _authProvider.refreshToken!,
        _authProvider.updateTokens,
      );
      if (userId != -1) await fetchUserDetails(userId); // Refresh count if specific user
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> unlinkCard(String cardUid, int userId) async {
    if (!_authProvider.isAuthenticated) return false;
    _setLoading(true);
    _errorMessage = null;
    try {
      await _apiService.unlinkCard(
        cardUid,
        _authProvider.token!,
        _authProvider.refreshToken!,
        _authProvider.updateTokens,
      );
      if (userId != -1) await fetchUserDetails(userId); // Refresh count if specific user
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // --- LIGHTWEIGHT USER LIST FOR CARD LINKING ---

  List<User> _linkableUsers = [];
  List<User> get linkableUsers => _linkableUsers;

  /// Fetches a lightweight list of STUDENT users for the card-link picker.
  /// Doesn't affect the paginated user management state.
  Future<void> fetchStudentsForLinking() async {
    if (!_authProvider.isAuthenticated) return;
    try {
      final json = await _apiService.getUsers(
        0,
        100, // Fetch a generous batch for the picker
        'STUDENT',
        _authProvider.token!,
        _authProvider.refreshToken!,
        _authProvider.updateTokens,
      );
      final response = AdminUserListResponse.fromJson(json);
      _linkableUsers = response.data.users;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to fetch students for linking: $e');
    }
  }

  // --- UTILS ---

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
