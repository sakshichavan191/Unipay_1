import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class CardScreen extends StatefulWidget {
  const CardScreen({super.key});
  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  bool isBlocked = false;

  void _toggleBlock() {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(isBlocked ? 'Activate Card?' : 'Block Card?'),
      content: Text(isBlocked
          ? 'Your card will be re-activated for payments.'
          : 'All payments will be stopped immediately.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: isBlocked ? AppTheme.success : AppTheme.danger),
          onPressed: () {
            setState(() => isBlocked = !isBlocked);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(isBlocked ? 'Card blocked' : 'Card activated'),
              backgroundColor: isBlocked ? AppTheme.danger : AppTheme.success,
            ));
          },
          child: Text(isBlocked ? 'Activate' : 'Block'),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Card Control')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isBlocked
                  ? AppTheme.danger.withOpacity(0.1)
                  : AppTheme.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isBlocked ? AppTheme.danger : AppTheme.success),
            ),
            child: Row(children: [
              Icon(isBlocked ? Icons.credit_card_off : Icons.credit_card,
                  color: isBlocked ? AppTheme.danger : AppTheme.success, size: 32),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Card Status',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                Text(isBlocked ? 'BLOCKED' : 'ACTIVE',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18,
                        color: isBlocked ? AppTheme.danger : AppTheme.success)),
              ]),
            ]),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: isBlocked ? AppTheme.success : AppTheme.danger),
              onPressed: _toggleBlock,
              icon: Icon(isBlocked ? Icons.lock_open : Icons.lock),
              label: Text(isBlocked ? 'Activate Card' : 'Block Card'),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'If you lose your ID card, block it immediately to prevent unauthorized payments.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ]),
      ),
    );
  }
}