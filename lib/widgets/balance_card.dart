import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../theme/app_theme.dart';

class BalanceCard extends StatefulWidget {
  final CardModel card;
  final VoidCallback? onManage;

  const BalanceCard({super.key, required this.card, this.onManage});

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnim = Tween<double>(begin: 30, end: 0)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_animController);
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final isBlocked = card.isBlocked;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: Opacity(
            opacity: _fadeAnim.value,
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isBlocked
                ? [const Color(0xFF991B1B), const Color(0xFF7F1D1D)]
                : [const Color(0xFF1E1B4B), const Color(0xFF312E81)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: (isBlocked ? AppTheme.danger : AppTheme.primary).withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row — branding + status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // NFC chip icon + UniPay text
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.contactless_rounded, color: Colors.white60, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text('UniPay NFC', style: TextStyle(
                        color: Colors.white60, fontSize: 13, letterSpacing: 1.5, fontWeight: FontWeight.w500)),
                  ],
                ),
                Row(
                  children: [
                    // Status pill
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isBlocked
                            ? Colors.red.withOpacity(0.3)
                            : Colors.green.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isBlocked
                              ? Colors.red.withOpacity(0.5)
                              : Colors.green.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              color: isBlocked ? AppTheme.danger : AppTheme.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isBlocked ? 'BLOCKED' : 'ACTIVE',
                            style: TextStyle(
                              color: isBlocked ? Colors.red.shade200 : Colors.green.shade200,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.onManage != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: widget.onManage,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.tune_rounded, color: Colors.white60, size: 16),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Card UID (styled like card number)
            Text(
              _formatCardUid(card.cardUid),
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
                letterSpacing: 3,
                fontFamily: 'monospace',
              ),
            ),

            const SizedBox(height: 20),

            // Bottom row — student info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('CARD HOLDER',
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(card.studentName.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('STUDENT ID',
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(card.studentId,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Format UID like a card number: "ABCD-EFGH-1234"
  String _formatCardUid(String uid) {
    if (uid.length <= 4) return uid;
    final buffer = StringBuffer();
    for (int i = 0; i < uid.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' · ');
      buffer.write(uid[i]);
    }
    return buffer.toString();
  }
}