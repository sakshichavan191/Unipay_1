import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/payment_provider.dart';

class TopupScreen extends StatefulWidget {
  const TopupScreen({super.key});
  @override
  State<TopupScreen> createState() => _TopupScreenState();
}

class _TopupScreenState extends State<TopupScreen> {
  final _ctrl = TextEditingController();
  int selected = 0;
  final amounts = [100, 200, 500, 1000];
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    _ctrl.text = amounts[0].toString();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
      paymentProvider.resetStatus();
      // Listen to payment status changes
      paymentProvider.addListener(_onPaymentStatusChanged);
    });
  }

  @override
  void dispose() {
    // Remove listener to prevent leaks
    Provider.of<PaymentProvider>(context, listen: false).removeListener(_onPaymentStatusChanged);
    _ctrl.dispose();
    super.dispose();
  }

  /// Handles payment status changes outside of build()
  void _onPaymentStatusChanged() {
    if (!mounted) return;
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);

    if (paymentProvider.isSuccess && !_dialogShown) {
      _dialogShown = true;
      paymentProvider.resetStatus();
      _showSuccessDialog();
    }

    if (paymentProvider.errorMessage != null) {
      final msg = paymentProvider.errorMessage!;
      paymentProvider.resetStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(msg)),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('SocketException') || raw.contains('ClientException')) {
      return 'Cannot reach server. Please check your internet connection.';
    }
    return raw;
  }

  void _handlePayment() {
    final amountStr = _ctrl.text.trim();
    if (amountStr.isEmpty) return;

    final amount = int.tryParse(amountStr);
    if (amount == null || amount < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum recharge amount is ₹10')),
      );
      return;
    }

    _dialogShown = false;
    Provider.of<PaymentProvider>(context, listen: false).startPayment(amount);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<PaymentProvider, bool>((p) => p.isLoading);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Balance')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Enter Amount', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                TextField(
                  controller: _ctrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Quick Select', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(
                      amounts.length,
                      (i) => Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: i < 3 ? 8.0 : 0),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => selected = i);
                                  _ctrl.text = amounts[i].toString();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: selected == i ? AppTheme.primary : Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: selected == i ? AppTheme.primary : Colors.grey.withOpacity(0.2)),
                                  ),
                                  child: Text('₹${amounts[i]}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: selected == i ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color)),
                                ),
                              ),
                            ),
                          )),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _handlePayment,
                    icon: const Icon(Icons.payment),
                    label: const Text('Proceed to Pay'),
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Recharge Successful!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Your wallet has been credited successfully.', textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to home
            },
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }
}