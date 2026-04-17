import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/payment_models.dart';
import '../services/student_api.dart';
import 'auth_provider.dart';

class PaymentProvider with ChangeNotifier {
  final StudentApi _apiService = StudentApi();
  final AuthProvider _authProvider;
  late Razorpay _razorpay;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSuccess => _isSuccess;

  PaymentProvider(this._authProvider) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> startPayment(int amount) async {
    if (!_authProvider.isAuthenticated) return;

    _setLoading(true);
    _errorMessage = null;
    _isSuccess = false;

    try {
      // 1. Create order on backend
      final orderResponse = await _apiService.createRechargeOrder(
        amount,
        _authProvider.token!,
        _authProvider.refreshToken!,
        _authProvider.updateTokens,
      );

      if (orderResponse.success && orderResponse.data != null) {
        final orderData = orderResponse.data!;
        
        // 2. Open Razorpay Checkout
        var options = {
          'key': orderData.razorpayKeyId,
          'amount': orderData.amount, // already in paise
          'name': 'UniPay Wallet',
          'order_id': orderData.orderId,
          'description': 'Wallet Recharge',
          'prefill': {
            'contact': _authProvider.user?.phone ?? '',
            'email': _authProvider.user?.email ?? '',
          },
          'external': {
            'wallets': ['paytm']
          }
        };

        _razorpay.open(options);
      } else {
        _errorMessage = "Failed to initiate order";
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    _setLoading(true);
    try {
      // 3. Verify payment on backend
      final verifyRequest = VerifyPaymentRequest(
        razorpayOrderId: response.orderId!,
        razorpayPaymentId: response.paymentId!,
        razorpaySignature: response.signature!,
      );

      await _apiService.verifyPayment(
        verifyRequest,
        _authProvider.token!,
        _authProvider.refreshToken!,
        _authProvider.updateTokens,
      );

      _isSuccess = true;
      // Refresh user profile to show updated balance
      await _authProvider.fetchProfile();
    } catch (e) {
      _errorMessage = "Verification failed: $e";
    } finally {
      _setLoading(false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _errorMessage = "Payment failed: ${response.message}";
    notifyListeners();
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _errorMessage = "External wallet selected: ${response.walletName}";
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
  
  void resetStatus() {
    _isSuccess = false;
    _errorMessage = null;
    notifyListeners();
  }
}
