import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/card_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../models/card_model.dart';
import '../../../widgets/balance_card.dart';
import '../../../widgets/transaction_tile.dart';
import '../../../widgets/card_manage_bottom_sheet.dart';
import '../../../widgets/wallet_card.dart';
import '../../../widgets/unipay_refresh_indicator.dart';
import '../../../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _initialLoaded = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadAll({bool forceRefresh = false}) async {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final cardProv = Provider.of<CardProvider>(context, listen: false);
    final txnProv = Provider.of<TransactionProvider>(context, listen: false);

    if (_initialLoaded && !forceRefresh) return;

    await Future.wait([
      auth.fetchBalance(),
      cardProv.loadCards(),
      txnProv.fetchInitial(auth),
    ]);

    _initialLoaded = true;
    if (mounted) _fadeController.forward();
  }

  Future<void> _refreshAfterNavigation() async {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final txnProv = Provider.of<TransactionProvider>(context, listen: false);

    await Future.wait([
      auth.fetchBalance(),
      txnProv.fetchInitial(auth),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge!.color;

    return Scaffold(
      appBar: AppBar(
        title: const Text('UniPay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 0.5)),
        automaticallyImplyLeading: false,
      ),
      body: UniPayRefreshIndicator(
        onRefresh: () => _loadAll(forceRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wallet balance
              const WalletCard(),
              const SizedBox(height: 20),

              // NFC Card
              Consumer<CardProvider>(
                builder: (context, cardProv, child) {
                  if (cardProv.isLoading && cardProv.cards.isEmpty) {
                    return _buildCardSkeleton();
                  }

                  final activeCard = cardProv.activeCard;
                  if (activeCard != null) {
                    return BalanceCard(
                      card: activeCard,
                      onManage: () => _showManageSheet(context, activeCard),
                    );
                  }
                  return _buildNoCardState(context);
                },
              ),

              const SizedBox(height: 22),

              // Quick Actions
              Selector<CardProvider, bool>(
                selector: (_, prov) => prov.activeCard?.isBlocked ?? false,
                builder: (context, isBlocked, child) {
                  return Row(
                    children: [
                      _quickAction(context, Icons.add_rounded, 'Add Money', '/topup', AppTheme.success, 0),
                      const SizedBox(width: 10),
                      _quickAction(
                        context,
                        isBlocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                        isBlocked ? 'Unblock' : 'Block',
                        '',
                        isBlocked ? AppTheme.success : AppTheme.danger,
                        1,
                        onTap: () {
                          final card = Provider.of<CardProvider>(context, listen: false).activeCard;
                          if (card != null) _showManageSheet(context, card);
                        },
                      ),
                      const SizedBox(width: 10),
                      _quickAction(context, Icons.receipt_long_outlined, 'History', '/transactions', AppTheme.primary, 2),
                      const SizedBox(width: 10),
                      _quickAction(context, Icons.credit_card_rounded, 'My Card', '/card', const Color(0xFF7C3AED), 3),
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),

              // Recent transactions header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Activity', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textColor)),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.pushNamed(context, '/transactions');
                      _refreshAfterNavigation();
                    },
                    child: Text('See All', style: TextStyle(
                      color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600,
                    )),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Transactions list
              Consumer<TransactionProvider>(
                builder: (context, txnProv, child) {
                  if (txnProv.isLoading) {
                    return _buildTransactionSkeletons();
                  }

                  if (txnProv.transactions.isEmpty) {
                    return _buildEmptyTransactions();
                  }

                  final recentTxns = txnProv.transactions.take(5).toList();
                  return Column(
                    children: recentTxns.asMap().entries.map((entry) =>
                      TransactionTile(txn: entry.value, index: entry.key),
                    ).toList(),
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

  /// Skeleton loading for NFC card
  Widget _buildCardSkeleton() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.cardBg.withOpacity(0.6),
            AppTheme.cardBg.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Center(
        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54)),
      ),
    );
  }

  /// Skeleton loading for transaction list
  Widget _buildTransactionSkeletons() {
    return Column(
      children: List.generate(3, (i) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 72,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 1.5)),
        ),
      )),
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_outlined, size: 32, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 12),
          Text('No transactions yet', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('Your activity will appear here', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildNoCardState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.cardBg.withOpacity(0.9), AppTheme.cardBg.withOpacity(0.6)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.contactless_outlined, color: Colors.white54, size: 28),
          ),
          const SizedBox(height: 12),
          const Text('No NFC Card Linked', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Visit admin office to link your ID card', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
        ],
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

  Widget _quickAction(BuildContext context, IconData icon, String label, String route, Color color, int index, {VoidCallback? onTap}) {
    final textColor = Theme.of(context).textTheme.bodyMedium!.color;

    return Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 500 + (index * 100)),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Opacity(opacity: value.clamp(0, 1), child: child),
          );
        },
        child: GestureDetector(
          onTap: onTap ?? () async {
            await Navigator.pushNamed(context, route);
            _refreshAfterNavigation();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.12)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int index) {
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) async {
        const routes = ['/home', '/transactions', '/topup', '/profile'];
        if (routes[i] != '/home') {
          await Navigator.pushNamed(context, routes[i]);
          _refreshAfterNavigation();
        }
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