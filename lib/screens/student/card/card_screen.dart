import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/card_provider.dart';
import '../../../models/card_model.dart';

class CardScreen extends StatefulWidget {
  const CardScreen({super.key});

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _slideAnim = Tween<double>(begin: 40, end: 0).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_animController);
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cardProv = Provider.of<CardProvider>(context, listen: false);
      if (!cardProv.hasCards) {
        cardProv.loadCards();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleStatusToggle(CardModel card) {
    final bool isBlocked = card.isBlocked;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (isBlocked ? AppTheme.success : AppTheme.danger).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isBlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
            color: isBlocked ? AppTheme.success : AppTheme.danger,
            size: 32,
          ),
        ),
        title: Text(isBlocked ? 'Unblock Card?' : 'Block Card?'),
        content: Text(
          isBlocked
              ? 'Your card will be restored for all payments.'
              : 'All payments will be stopped immediately.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isBlocked ? AppTheme.success : AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                final provider = Provider.of<CardProvider>(context, listen: false);
                if (isBlocked) {
                  await provider.unblockCard(card.cardUid);
                } else {
                  await provider.blockCard(card.cardUid, 'Blocked by student');
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(isBlocked ? 'Card unblocked successfully' : 'Card blocked successfully'),
                    backgroundColor: isBlocked ? AppTheme.success : AppTheme.danger,
                  ));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: AppTheme.danger,
                  ));
                }
              }
            },
            child: Text(isBlocked ? 'Unblock' : 'Block Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge!.color;

    return Scaffold(
      appBar: AppBar(title: const Text('Card Control')),
      body: Consumer<CardProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final card = provider.activeCard;

          if (card == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.credit_card_off_outlined, size: 48, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 20),
                  Text('No Card Linked', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 8),
                  Text('Visit Admin office to link a physical card.', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          final bool isBlocked = card.isBlocked;

          return AnimatedBuilder(
            animation: _animController,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _slideAnim.value),
              child: Opacity(opacity: _fadeAnim.value, child: child),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Status Card with animated background
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isBlocked
                            ? [AppTheme.danger.withOpacity(0.12), AppTheme.danger.withOpacity(0.04)]
                            : [AppTheme.success.withOpacity(0.12), AppTheme.success.withOpacity(0.04)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (isBlocked ? AppTheme.danger : AppTheme.success).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            key: ValueKey(isBlocked),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (isBlocked ? AppTheme.danger : AppTheme.success).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isBlocked ? Icons.credit_card_off : Icons.credit_card,
                              color: isBlocked ? AppTheme.danger : AppTheme.success,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Card Status', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              const SizedBox(height: 4),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  isBlocked ? 'BLOCKED' : 'ACTIVE',
                                  key: ValueKey(isBlocked),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: isBlocked ? AppTheme.danger : AppTheme.success,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isBlocked ? AppTheme.success : AppTheme.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () => _handleStatusToggle(card),
                      icon: Icon(isBlocked ? Icons.lock_open : Icons.lock, size: 20),
                      label: Text(
                        isBlocked ? 'Unblock Card' : 'Block Card',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    isBlocked
                        ? 'Your card is currently frozen. Unblock it to resume payments.'
                        : 'If you lose your ID card, block it immediately to prevent unauthorized payments.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),

                  const Spacer(),

                  // Card Details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        _detailRow('Card UID', card.cardUid, textColor),
                        Divider(height: 20, color: Colors.grey.withOpacity(0.1)),
                        _detailRow('Holder', card.studentName, textColor),
                        Divider(height: 20, color: Colors.grey.withOpacity(0.1)),
                        _detailRow('Student ID', card.studentId, textColor),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Copy UID button
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: card.cardUid));
                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Card UID copied!'), duration: Duration(seconds: 1)),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy Card UID', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(String label, String value, Color? textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: 13)),
      ],
    );
  }
}