import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/transaction_model.dart';
import '../../../theme/app_theme.dart';

class TransactionDetailScreen extends StatefulWidget {
  final int? transactionId;
  const TransactionDetailScreen({super.key, this.transactionId});

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDetails());
  }

  Future<void> _fetchDetails() async {
    final int? txnId = widget.transactionId ?? ModalRoute.of(context)?.settings.arguments as int?;
    
    if (txnId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Invalid transaction ID';
      });
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final txnProv = Provider.of<TransactionProvider>(context, listen: false);

    try {
      final detail = await txnProv.getDetail(auth, txnId);
      if (mounted) {
        setState(() {
          _detail = detail;
          _isLoading = false;
          if (detail == null) _error = 'Transaction details not found';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load details: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Detail', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_detail != null)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Receipt sharing coming soon!'), duration: Duration(seconds: 1)),
                );
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Fetching receipt...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_error != null || _detail == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 64, color: AppTheme.danger.withOpacity(0.5)),
              const SizedBox(height: 16),
              const Text('Oops!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_error ?? 'Unable to find transaction', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _fetchDetails, child: const Text('Try Again')),
            ],
          ),
        ),
      );
    }

    final txn = _detail!;
    final isDebit = txn.direction == 'DEBIT';
    final statusColor = txn.status == 'SUCCESS' ? AppTheme.success : AppTheme.danger;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.95 + (0.05 * value),
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: Column(
          children: [
            // Premium Receipt Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Top Section - Status Icon
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              txn.status == 'SUCCESS' ? Icons.check_circle_rounded : Icons.error_rounded,
                              color: statusColor,
                              size: 52,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            txn.status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Amount Section
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Text(
                          'Amount',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${isDebit ? "-" : "+"} ₹${txn.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(indent: 24, endIndent: 24),

                  // Details Section
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        if (txn.senderName != null)
                          _buildDetailRow('From', txn.senderName!, Theme.of(context)),
                        if (txn.receiverName != null)
                          _buildDetailRow('To', txn.receiverName!, Theme.of(context)),
                        
                        _buildDetailRow('Category', txn.type.replaceAll('_', ' '), Theme.of(context)),
                        _buildDetailRow('Date', DateFormat('MMMM dd, yyyy').format(txn.createdAt.toLocal()), Theme.of(context)),
                        _buildDetailRow('Time', DateFormat('hh:mm a').format(txn.createdAt.toLocal()), Theme.of(context)),
                        _buildDetailRow('Direction', txn.direction, Theme.of(context)),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        
                        // Transaction ID with Copy functionality
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Transaction ID', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: txn.id.toString()));
                                HapticFeedback.lightImpact();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('ID Copied!'), duration: Duration(seconds: 1)),
                                );
                              },
                              child: Row(
                                children: [
                                  Text(
                                    txn.id.toString().length > 12 ? '${txn.id.toString().substring(0, 12)}...' : txn.id.toString(),
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, fontFamily: 'monospace'),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.copy_rounded, size: 14, color: AppTheme.primary.withOpacity(0.6)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Support button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {},
              icon: const Icon(Icons.help_outline_rounded, size: 18),
              label: const Text('Having trouble?'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: theme.textTheme.bodyLarge?.color),
            ),
          ),
        ],
      ),
    );
  }
}
