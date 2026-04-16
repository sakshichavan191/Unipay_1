import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../widgets/transaction_tile.dart';

class TransactionsScreen extends StatelessWidget {
  TransactionsScreen({super.key});

  final transactions = [
    TransactionModel(id:'1', amount:45, type:'debit', vendor:'Main Canteen', timestamp: DateTime.now().subtract(const Duration(hours: 1))),
    TransactionModel(id:'2', amount:500, type:'credit', vendor:'Wallet Top-up', timestamp: DateTime.now().subtract(const Duration(hours: 5))),
    TransactionModel(id:'3', amount:30, type:'debit', vendor:'Stationery Shop', timestamp: DateTime.now().subtract(const Duration(days: 1))),
    TransactionModel(id:'4', amount:80, type:'debit', vendor:'Library Café', timestamp: DateTime.now().subtract(const Duration(days: 2))),
    TransactionModel(id:'5', amount:1000, type:'credit', vendor:'Wallet Top-up', timestamp: DateTime.now().subtract(const Duration(days: 3))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: transactions.length,
        itemBuilder: (_, i) => TransactionTile(txn: transactions[i]),
      ),
    );
  }
}