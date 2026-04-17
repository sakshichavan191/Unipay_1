import 'package:flutter/material.dart';
import '../models/auth_models.dart';
import '../models/card_model.dart';
import '../services/student_api.dart';
import 'auth_provider.dart';

class CardProvider with ChangeNotifier {
  final StudentApi _apiService = StudentApi();
  final AuthProvider _authProvider;

  List<CardModel> _cards = [];
  bool _isLoading = false;

  CardProvider(this._authProvider);

  List<CardModel> get cards => _cards;
  bool get isLoading => _isLoading;
  
  // As requested, we primarily deal with a single card for now
  CardModel? get activeCard => _cards.isNotEmpty ? _cards.first : null;

  Future<void> loadCards() async {
    if (!_authProvider.isAuthenticated) return;
    
    _setLoading(true);
    try {
      final fetchedCards = await _apiService.fetchMyCards(
        _authProvider.token!,
        _authProvider.refreshToken!,
        _authProvider.user!,
        _authProvider.updateTokens,
      );
      _cards = fetchedCards;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cards: $e');
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
      
      // Reload cards to get updated status
      await loadCards();
    } catch (e) {
      debugPrint('Error toggling card status: $e');
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
