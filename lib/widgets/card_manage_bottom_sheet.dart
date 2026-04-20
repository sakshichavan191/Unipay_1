import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card_model.dart';
import '../providers/card_provider.dart';
import '../theme/app_theme.dart';

class CardManageBottomSheet extends StatefulWidget {
  final CardModel card;
  const CardManageBottomSheet({super.key, required this.card});

  @override
  State<CardManageBottomSheet> createState() => _CardManageBottomSheetState();
}

class _CardManageBottomSheetState extends State<CardManageBottomSheet> {
  String? selectedReason;
  final TextEditingController _customReasonController = TextEditingController();
  final List<String> blockReasons = [
    'Card Misplaced',
    'Suspected Fraud',
    'Card Lost or Stolen',
    'Damaged Card',
    'Temporary Protection',
  ];

  final List<String> unblockReasons = [
    'Card Found',
    'Re-activating',
    'Verified Security',
  ];

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool currentlyBlocked = widget.card.isBlocked;
    final reasons = currentlyBlocked ? unblockReasons : blockReasons;
    final theme = Theme.of(context);
    final cardProvider = Provider.of<CardProvider>(context, listen: false);

    return Container(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (currentlyBlocked ? AppTheme.success : AppTheme.danger).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  currentlyBlocked ? Icons.lock_open_rounded : Icons.lock_person_rounded,
                  color: currentlyBlocked ? AppTheme.success : AppTheme.danger,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentlyBlocked ? 'Activate Card' : 'Deactivate Card',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'UID: ${widget.card.cardUid}',
                    style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Choose Reason', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: reasons.map((r) => ChoiceChip(
              label: Text(r),
              selected: selectedReason == r,
              onSelected: (val) {
                setState(() => selectedReason = val ? r : null);
              },
            )).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _customReasonController,
            decoration: InputDecoration(
              hintText: 'Add a custom note (Optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: currentlyBlocked ? AppTheme.success : AppTheme.danger,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                final finalReason = (selectedReason ?? '') + 
                    (_customReasonController.text.isNotEmpty ? ' - ${_customReasonController.text}' : '');
                
                if (finalReason.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select or enter a reason')),
                  );
                  return;
                }

                Navigator.pop(context);
                try {
                  if (currentlyBlocked) {
                    await cardProvider.unblockCard(widget.card.cardUid);
                  } else {
                    await cardProvider.blockCard(widget.card.cardUid, finalReason);
                  }
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(currentlyBlocked ? 'Card unblocked' : 'Card blocked'),
                        backgroundColor: currentlyBlocked ? AppTheme.success : AppTheme.danger,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e'), backgroundColor: AppTheme.danger),
                    );
                  }
                }
              },
              child: Text(
                currentlyBlocked ? 'Confirm Unblock' : 'Confirm Block',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
