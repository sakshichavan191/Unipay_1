import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../models/transaction_model.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/unipay_refresh_indicator.dart';
import '../../../widgets/transaction_tile.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      // Uses cache — won't re-fetch if HomeScreen already loaded recently
      Provider.of<TransactionProvider>(context, listen: false).fetchInitial(auth);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<TransactionProvider>(context, listen: false).fetchMore(auth);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txnProvider = Provider.of<TransactionProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('All', 'ALL', txnProvider, auth),
                const SizedBox(width: 8),
                _buildFilterChip('Payments', 'NFC_PAYMENT', txnProvider, auth),
                const SizedBox(width: 8),
                _buildFilterChip('Top-ups', 'RECHARGE', txnProvider, auth),
              ],
            ),
          ),
          
          Expanded(
            child: txnProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : txnProvider.transactions.isEmpty
                    ? const Center(child: Text('No transactions found'))
                    : UniPayRefreshIndicator(
                        onRefresh: () => txnProvider.fetchInitial(auth, type: txnProvider.currentType, forceRefresh: true),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: txnProvider.transactions.length + (txnProvider.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == txnProvider.transactions.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            
                            final txn = txnProvider.transactions[index];
                            return _buildTransactionTile(context, txn);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String type, TransactionProvider provider, AuthProvider auth) {
    final isSelected = provider.currentType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) provider.setFilter(auth, type);
      },
      selectedColor: AppTheme.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primary : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, TransactionModel txn) {
    final bool isCredit = txn.direction == 'CREDIT';
    final Color amountColor = isCredit ? AppTheme.success : AppTheme.danger;
    final String sign = isCredit ? '+' : '-';
    
    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final formattedAmount = formatCurrency.format(txn.amount);
    
    final DateFormat formatter = DateFormat('MMM dd, hh:mm a');
    final String formattedDate = formatter.format(txn.createdAt.toLocal());
    
    IconData iconData = Icons.receipt_long_outlined;
    if (txn.type == 'RECHARGE') iconData = Icons.account_balance_wallet_outlined;
    if (txn.type == 'NFC_PAYMENT') iconData = Icons.contactless_outlined;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(context, '/transaction-detail', arguments: txn.id);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      txn.counterparty ?? txn.type,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$sign $formattedAmount',
                    style: TextStyle(
                      color: amountColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    txn.status,
                    style: TextStyle(
                      color: _getStatusColor(txn.status),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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