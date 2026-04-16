import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/card_model.dart';
import '../theme/app_theme.dart';

class BalanceCard extends StatelessWidget {
  final CardModel card;
  const BalanceCard({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('UniPay', style: TextStyle(
                  color: Colors.white70, fontSize: 13, letterSpacing: 2)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: card.isBlocked ? AppTheme.danger : AppTheme.success,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  card.isBlocked ? 'BLOCKED' : 'ACTIVE',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Available Balance',
              style: TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            NumberFormat.currency(locale: 'en_IN', symbol: '₹')
                .format(card.balance),
            style: const TextStyle(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Student Name', style: TextStyle(color: Colors.white54, fontSize: 11)),
                Text(card.studentName,
                    style: const TextStyle(color: Colors.white, fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('Student ID', style: TextStyle(color: Colors.white54, fontSize: 11)),
                Text(card.studentId,
                    style: const TextStyle(color: Colors.white, fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}