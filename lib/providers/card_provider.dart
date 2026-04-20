import 'package:flutter/material.dart';
import '../models/auth_models.dart';
import '../models/card_model.dart';
import '../services/student_api.dart';
import 'auth_provider.dart';

class CardProvider with ChangeNotifier {
  final StudentApi _apiService = StudentApi();
  AuthProvider _authProvider;

  List<CardModel> _cards = [];
  bool _isLoading = false;
  DateTime? _lastFetchTime;

  // Cache duration — skip re-fetch if loaded recently
  static const _cacheDuration = Duration(seconds: 30);

  CardProvider(this._authProvider);

  void updateAuth(AuthProvider newAuth) {
    _authProvider = newAuth;
  }

  List<CardModel> get cards => _cards;
  bool get isLoading => _isLoading;
  bool get hasCards => _cards.isNotEmpty;
  
  // Prioritize active and unblocked cards, fallback to the latest card
  CardModel? get activeCard {
    if (_cards.isEmpty) return null;
    
    try {
      return _cards.firstWhere((c) => c.isActive && !c.isBlocked);
    } catch (_) {
      try {
        return _cards.firstWhere((c) => c.isActive);
      } catch (_) {
        // Find the latest linked card by cardId if none are active
        return _cards.reduce((curr, next) => curr.cardId > next.cardId ? curr : next);
      }
    }
  }

  Future<void> loadCards({bool forceRefresh = false}) async {
    if (!_authProvider.isAuthenticated) return;

    // Skip if recently fetched and not forced
    if (!forceRefresh && _lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration &&
        _cards.isNotEmpty) {
      return;
    }
    
    _setLoading(true);
    try {
      final fetchedCards = await _apiService.fetchMyCards(
        _authProvider.token!,
        _authProvider.refreshToken!,
        _authProvider.user!,
        _authProvider.updateTokens,
      );
      _cards = fetchedCards;
      _lastFetchTime = DateTime.now();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cards: $e');
      if (e.toString().contains('Session expired')) {
        _authProvider.logout();
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleStatus(String cardUid, bool activate, String reason) async {
    if (!_authProvider.isAuthenticated) return;

    _setLoading(true);
    try {
      final action = activate ? 'activate' : 'deactivate';
      await _apiService.toggleCardStatus(
        cardUid,
        action,
        reason,
        _authProvider.token!,
        _authProvider.refreshToken!,
        _authProvider.updateTokens,
      );
      
      // Invalidate cache and reload
      _lastFetchTime = null;
      await loadCards();
    } catch (e) {
      debugPrint('Error toggling card status: $e');
      if (e.toString().contains('Session expired')) {
        _authProvider.logout();
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> blockCard(String cardUid, String? reason) async {
    if (!_authProvider.isAuthenticated) return;

    _setLoading(true);
    try {
      await _apiService.blockCard(
        cardUid,
        reason,
        _authProvider.token!,
        _authProvider.refreshToken!,
        _authProvider.updateTokens,
      );
      
      // Invalidate cache and reload
      _lastFetchTime = null;
      await loadCards();
    } catch (e) {
      debugPrint('Error blocking card: $e');
      if (e.toString().contains('Session expired')) {
        _authProvider.logout();
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> unblockCard(String cardUid) async {
    if (!_authProvider.isAuthenticated) return;

    _setLoading(true);
    try {
      await _apiService.unblockCard(
        cardUid,
        _authProvider.token!,
        _authProvider.refreshToken!,
        _authProvider.updateTokens,
      );
      
      // Invalidate cache and reload
      _lastFetchTime = null;
      await loadCards();
    } catch (e) {
      debugPrint('Error unblocking card: $e');
      if (e.toString().contains('Session expired')) {
        _authProvider.logout();
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
