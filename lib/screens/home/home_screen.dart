import 'package:flutter/material.dart';
import '../../models/card_model.dart';
import '../../models/transaction_model.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/transaction_tile.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final card = CardModel(
    cardId: 'CARD001',
    studentName: 'Ravi Sharma',
    studentId: 'STU2024001',
    balance: 1250.0,
    isBlocked: false,
  );

  final transactions = [
    TransactionModel(
        id: '1',
        amount: 45,
        type: 'debit',
        vendor: 'Main Canteen',
        timestamp: DateTime.now().subtract(const Duration(hours: 1))),
    TransactionModel(
        id: '2',
        amount: 500,
        type: 'credit',
        vendor: 'Wallet Top-up',
        timestamp: DateTime.now().subtract(const Duration(hours: 5))),
    TransactionModel(
        id: '3',
        amount: 30,
        type: 'debit',
        vendor: 'Stationery Shop',
        timestamp: DateTime.now().subtract(const Duration(days: 1))),
  ];

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge!.color;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'UniPay',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BalanceCard(card: card),
            const SizedBox(height: 24),

            Row(
              children: [
                _quickAction(context, Icons.add_rounded, 'Add Money', '/topup',
                    AppTheme.success),
                const SizedBox(width: 12),
                _quickAction(context, Icons.credit_card_off_outlined,
                    'Block Card', '/card', AppTheme.danger),
                const SizedBox(width: 12),
                _quickAction(context, Icons.receipt_long_outlined, 'History',
                    '/transactions', AppTheme.primary),
              ],
            ),

            const SizedBox(height: 28),

            Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),

            const SizedBox(height: 14),

            ...transactions.map((t) => TransactionTile(txn: t)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, 0),
    );
  }

  Widget _quickAction(BuildContext context, IconData icon, String label,
      String route, Color color) {
    final textColor = Theme.of(context).textTheme.bodyMedium!.color;

    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, route),
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
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
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