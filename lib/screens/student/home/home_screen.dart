import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/card_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../models/card_model.dart';
import '../../../models/transaction_model.dart';
import '../../../widgets/balance_card.dart';
import '../../../widgets/transaction_tile.dart';
import '../../../widgets/card_manage_bottom_sheet.dart';
import '../../../widgets/wallet_card.dart';
import '../../../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<CardProvider>(context, listen: false).loadCards();
      Provider.of<TransactionProvider>(context, listen: false).fetchInitial(auth);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardProvider = Provider.of<CardProvider>(context);
    final activeCard = cardProvider.activeCard;
    final textColor = Theme.of(context).textTheme.bodyLarge!.color;

    return Scaffold(
      appBar: AppBar(
        title: const Text('UniPay', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: cardProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                await auth.fetchBalance();
                await cardProvider.loadCards();
                await Provider.of<TransactionProvider>(context, listen: false).fetchInitial(auth);
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const WalletCard(),
                    const SizedBox(height: 24),
                    
                    if (activeCard != null)
                      BalanceCard(
                        card: activeCard,
                        onManage: () => _showManageSheet(context, activeCard),
                      )
                    else
                      _buildNoCardState(context),
                      
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        _quickAction(context, Icons.add_rounded, 'Add Money', '/topup', AppTheme.success),
                        const SizedBox(width: 12),
                        _quickAction(
                          context, 
                          activeCard?.isBlocked ?? false ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                          activeCard?.isBlocked ?? false ? 'Unblock' : 'Block Card', 
                          '', 
                          activeCard?.isBlocked ?? false ? AppTheme.success : AppTheme.danger,
                          onTap: activeCard != null ? () => _showManageSheet(context, activeCard) : null,
                        ),
                        const SizedBox(width: 12),
                        _quickAction(context, Icons.receipt_long_outlined, 'History', '/transactions', AppTheme.primary),
                      ],
                    ),

                    const SizedBox(height: 28),

                    Text('Recent Transactions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 14),
                    
                    Consumer<TransactionProvider>(
                      builder: (context, txnProv, child) {
                        if (txnProv.isLoading) {
                          return const Center(child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ));
                        }
                        
                        if (txnProv.transactions.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text('No recent transactions'),
                            ),
                          );
                        }
                        
                        final recentTxns = txnProv.transactions.take(3).toList();
                        return Column(
                          children: recentTxns.map((t) => TransactionTile(txn: t)).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomNav(context, 0),
    );
  }

  Widget _buildNoCardState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBg.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Text('No NFC Card linked to your account.', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showManageSheet(BuildContext context, CardModel card) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CardManageBottomSheet(card: card),
    );
  }

  Widget _quickAction(BuildContext context, IconData icon, String label, String route, Color color, {VoidCallback? onTap}) {
    final textColor = Theme.of(context).textTheme.bodyMedium!.color;

    return Expanded(
      child: GestureDetector(
        onTap: onTap ?? () => Navigator.pushNamed(context, route),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int index) {
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) {
        const routes = ['/home', '/transactions', '/topup', '/profile'];
        Navigator.pushNamed(context, routes[i]);
      },
      destinations: const [
        NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home'),
        NavigationDestination(
            icon: Icon(Icons.receipt_outlined),
            selectedIcon: Icon(Icons.receipt),
            label: 'History'),
        NavigationDestination(
            icon: Icon(Icons.add_card_outlined),
            selectedIcon: Icon(Icons.add_card),
            label: 'Top Up'),
        NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profile'),
      ],
    );
  }
}