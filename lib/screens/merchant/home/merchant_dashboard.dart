import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/unipay_refresh_indicator.dart';
import '../../../widgets/transaction_tile.dart';

class MerchantDashboard extends StatefulWidget {
  const MerchantDashboard({super.key});

  @override
  State<MerchantDashboard> createState() => _MerchantDashboardState();
}

class _MerchantDashboardState extends State<MerchantDashboard> {
  int _selectedIndex = 0;
  bool _initialLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll({bool forceRefresh = false}) async {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final txnProv = Provider.of<TransactionProvider>(context, listen: false);

    if (_initialLoaded && !forceRefresh) return;

    await Future.wait([
      auth.fetchBalance(),
      txnProv.fetchInitial(auth),
    ]);

    _initialLoaded = true;
  }

  Future<void> _refreshAfterNavigation() async {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await Future.wait([
      auth.fetchBalance(),
      Provider.of<TransactionProvider>(context, listen: false).fetchInitial(auth),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _MerchantHomeTab(onForceRefresh: () => _loadAll(forceRefresh: true)),
          const _MerchantTransactionsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) async {
          if (i == 2) {
            await Navigator.pushNamed(context, '/profile');
            _refreshAfterNavigation();
            return;
          }
          setState(() => _selectedIndex = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─── Dashboard Tab ───────────────────────────────────────────────────────────

class _MerchantHomeTab extends StatefulWidget {
  final VoidCallback onForceRefresh;
  const _MerchantHomeTab({required this.onForceRefresh});

  @override
  State<_MerchantHomeTab> createState() => _MerchantHomeTabState();
}

class _MerchantHomeTabState extends State<_MerchantHomeTab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge!.color;
    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        automaticallyImplyLeading: false,
      ),
      body: UniPayRefreshIndicator(
        onRefresh: () async => widget.onForceRefresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Earnings card
                Consumer<AuthProvider>(
                  builder: (context, auth, child) {
                    final user = auth.user;
                    final businessName = user?.businessName ?? user?.name ?? 'Merchant';
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E1B4B), Color(0xFF4338CA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E1B4B).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_getGreeting()} ☕',
                                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                                    ),
                                    Text(
                                      businessName,
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'TOTAL EARNINGS',
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formatCurrency.format(user?.walletBalance ?? 0.0),
                            style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Recent Transactions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activity',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    Icon(Icons.trending_up_rounded, color: AppTheme.success, size: 20),
                  ],
                ),
                const SizedBox(height: 16),

                Consumer<TransactionProvider>(
                  builder: (context, txnProv, child) {
                    if (txnProv.isLoading) {
                      return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
                    }

                    if (txnProv.transactions.isEmpty) {
                      return _buildEmptyState();
                    }

                    final recentTxns = txnProv.transactions.take(8).toList();
                    return Column(
                      children: recentTxns.asMap().entries.map((entry) {
                        return TransactionTile(txn: entry.value, index: entry.key);
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), shape: BoxShape.circle),
              child: Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text('No earnings yet', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─── Transactions Tab ────────────────────────────────────────────────────────

class _MerchantTransactionsTab extends StatefulWidget {
  const _MerchantTransactionsTab();

  @override
  State<_MerchantTransactionsTab> createState() => _MerchantTransactionsTabState();
}

class _MerchantTransactionsTabState extends State<_MerchantTransactionsTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<TransactionProvider>(context, listen: false).fetchMore(auth);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final textColor = Theme.of(context).textTheme.bodyLarge!.color;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History', style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Selector<TransactionProvider, String>(
            selector: (_, prov) => prov.currentType,
            builder: (context, currentType, child) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Row(
                  children: [
                    _buildFilterChip('All', 'ALL', currentType, auth),
                    const SizedBox(width: 10),
                    _buildFilterChip('Sales', 'NFC_PAYMENT', currentType, auth),
                    const SizedBox(width: 10),
                    _buildFilterChip('Refunds', 'REFUND', currentType, auth),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, txnProvider, child) {
                if (txnProvider.isLoading && txnProvider.transactions.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (txnProvider.transactions.isEmpty) {
                  return Center(child: Text('No results found', style: TextStyle(color: Colors.grey.shade500)));
                }
                return UniPayRefreshIndicator(
                  onRefresh: () => txnProvider.fetchInitial(auth, type: txnProvider.currentType, forceRefresh: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: txnProvider.transactions.length + (txnProvider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == txnProvider.transactions.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                        );
                      }
                      return TransactionTile(
                        txn: txnProvider.transactions[index],
                        index: index % 10, // Stagger relative to viewport
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String type, String currentType, AuthProvider auth) {
    final isSelected = currentType == type;
    return GestureDetector(
      onTap: () {
        Provider.of<TransactionProvider>(context, listen: false).setFilter(auth, type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.withOpacity(0.12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
