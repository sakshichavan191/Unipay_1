import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/shared_api.dart';
import 'auth_provider.dart';

class TransactionProvider with ChangeNotifier {
  final SharedApi _apiService = SharedApi();
  
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  String? _currentType; // 'ALL', 'NFC_PAYMENT', 'RECHARGE'
  DateTime? _lastFetchTime;
  
  final int _pageSize = 10;
  static const _cacheDuration = Duration(seconds: 15);
  
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String get currentType => _currentType ?? 'ALL';

  /// Routes to the correct endpoint based on role
  Future<TransactionPageData> _fetchPage(AuthProvider authProvider, int page) {
    final isMerchant = authProvider.user?.role == 'MERCHANT';
    if (isMerchant) {
      return _apiService.getMerchantTransactionHistory(
        page,
        _pageSize,
        _currentType,
        authProvider.token!,
        authProvider.refreshToken!,
        authProvider.updateTokens,
      );
    } else {
      return _apiService.getTransactionHistory(
        page,
        _pageSize,
        _currentType,
        authProvider.token!,
        authProvider.refreshToken!,
        authProvider.updateTokens,
      );
    }
  }

  Future<void> fetchInitial(AuthProvider authProvider, {String? type, bool forceRefresh = false}) async {
    if (authProvider.token == null || authProvider.refreshToken == null) return;

    // Skip if same filter and recently fetched
    if (!forceRefresh && type == _currentType && _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration &&
        _transactions.isNotEmpty) {
      return;
    }
    
    _isLoading = true;
    _currentPage = 0;
    _hasMore = true;
    _currentType = type;
    notifyListeners();

    try {
      final pageData = await _fetchPage(authProvider, _currentPage);
      
      _transactions = pageData.transactions;
      _hasMore = pageData.currentPage < pageData.totalPages - 1;
      _lastFetchTime = DateTime.now();
    } catch (e) {
      debugPrint("Failed to fetch transactions: $e");
      if (e.toString().contains('Session expired')) {
        authProvider.logout();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMore(AuthProvider authProvider) async {
    if (!hasMore || isLoading || isLoadingMore) return;
    if (authProvider.token == null || authProvider.refreshToken == null) return;

    _isLoadingMore = true;
    _currentPage++;
    notifyListeners();

    try {
      final pageData = await _fetchPage(authProvider, _currentPage);
      
      _transactions.addAll(pageData.transactions);
      _hasMore = pageData.currentPage < pageData.totalPages - 1;
    } catch (e) {
      _currentPage--;
      debugPrint("Failed to load more transactions: $e");
      if (e.toString().contains('Session expired')) {
        authProvider.logout();
      }
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void setFilter(AuthProvider authProvider, String type) {
    if (_currentType == type) return;
    fetchInitial(authProvider, type: type, forceRefresh: true);
  }

  Future<TransactionDetailModel?> getDetail(AuthProvider authProvider, int id) async {
     if (authProvider.token == null || authProvider.refreshToken == null) return null;
     
     try {
        return await _apiService.getTransactionDetail(
          id,
          authProvider.token!,
          authProvider.refreshToken!,
          authProvider.updateTokens,
        );
     } catch (e) {
        debugPrint("Detail fail: $e");
        if (e.toString().contains('Session expired')) {
          authProvider.logout();
        }
        return null;
     }
  }
}
