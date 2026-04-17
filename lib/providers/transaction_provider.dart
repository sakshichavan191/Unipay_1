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
  
  final int _pageSize = 10;
  
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String get currentType => _currentType ?? 'ALL';

  Future<void> fetchInitial(AuthProvider authProvider, {String? type}) async {
    if (authProvider.token == null || authProvider.refreshToken == null) return;
    
    _isLoading = true;
    _currentPage = 0;
    _hasMore = true;
    _currentType = type;
    notifyListeners();

    try {
      final pageData = await _apiService.getTransactionHistory(
        _currentPage,
        _pageSize,
        _currentType,
        authProvider.token!,
        authProvider.refreshToken!,
        authProvider.updateTokens,
      );
      
      _transactions = pageData.transactions;
      _hasMore = pageData.currentPage < pageData.totalPages - 1;
    } catch (e) {
      debugPrint("Failed to fetch transactions: $e");
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
      final pageData = await _apiService.getTransactionHistory(
        _currentPage,
        _pageSize,
        _currentType,
        authProvider.token!,
        authProvider.refreshToken!,
        authProvider.updateTokens,
      );
      
      _transactions.addAll(pageData.transactions);
      _hasMore = pageData.currentPage < pageData.totalPages - 1;
    } catch (e) {
      _currentPage--; // Revert page count on failure
      debugPrint("Failed to load more transactions: $e");
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void setFilter(AuthProvider authProvider, String type) {
    if (_currentType == type) return;
    fetchInitial(authProvider, type: type);
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
        return null;
     }
  }
}
