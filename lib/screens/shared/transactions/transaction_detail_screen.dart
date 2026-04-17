import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../models/transaction_model.dart';
import '../../../theme/app_theme.dart';

class TransactionDetailScreen extends StatefulWidget {
  final int transactionId;
  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  TransactionDetailModel? _detail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final txnProv = Provider.of<TransactionProvider>(context, listen: false);

    final result = await txnProv.getDetail(auth, widget.transactionId);
    if (mounted) {
      if (result != null) {
        setState(() {
          _detail = result;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Could not load transaction details.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge!.color;
    final subTextColor = Theme.of(context).textTheme.bodyMedium!.color;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: AppTheme.danger)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildHeaderIcon(),
                            const SizedBox(height: 16),
                            const Text(
                              'Transaction Success', // Or status
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(_detail!.amount),
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 32),
                            const Divider(),
                            const SizedBox(height: 24),
                            
                            _buildDetailRow('Time', DateFormat('MMM dd, yyyy • hh:mm a').format(_detail!.createdAt.toLocal()), subTextColor, textColor),
                            _buildDetailRow('Type', _detail!.type, subTextColor, textColor),
                            _buildDetailRow('Status', _detail!.status, subTextColor, _getStatusColor(_detail!.status)),
                            _buildDetailRow('Sender', _detail!.senderName ?? 'N/A', subTextColor, textColor),
                            _buildDetailRow('Receiver', _detail!.receiverName ?? 'N/A', subTextColor, textColor),
                            if (_detail!.cardUid != null)
                              _buildDetailRow('Card UID', _detail!.cardUid!, subTextColor, textColor),
                              
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 24),
                            
                            _buildDetailRow('Transaction ID', '#${_detail!.id}', subTextColor, textColor),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextButton.icon(
                        onPressed: () {
                          // Action to share receipt or download could go here
                        },
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('Share Receipt'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeaderIcon() {
    final isCredit = _detail!.direction == 'CREDIT';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCredit ? AppTheme.success.withOpacity(0.1) : AppTheme.danger.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
        color: isCredit ? AppTheme.success : AppTheme.danger,
        size: 32,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color? labelColor, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: labelColor, fontSize: 14)),
          Text(value, style: TextStyle(color: valueColor, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'SUCCESS':
        return AppTheme.success;
      case 'PENDING':
        return Colors.orange;
      case 'FAILED':
        return AppTheme.danger;
      default:
        return Colors.grey;
    }
  }
}
