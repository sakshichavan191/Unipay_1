import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class TopupScreen extends StatefulWidget {
  const TopupScreen({super.key});
  @override
  State<TopupScreen> createState() => _TopupScreenState();
}

class _TopupScreenState extends State<TopupScreen> {
  final _ctrl = TextEditingController();
  int selected = 0;
  final amounts = [100, 200, 500, 1000];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Balance')),
      body: Padding(
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
                filled: true, fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Quick Select', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: List.generate(amounts.length, (i) => Expanded(
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
                        color: selected == i
                            ? AppTheme.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: selected == i
                                ? AppTheme.primary
                                : Colors.grey.shade200),
                      ),
                      child: Text('₹${amounts[i]}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: selected == i ? Colors.white : Colors.black87)),
                    ),
                  ),
                ),
              )),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment gateway will open here')),
                ),
                icon: const Icon(Icons.payment),
                label: const Text('Proceed to Pay'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}