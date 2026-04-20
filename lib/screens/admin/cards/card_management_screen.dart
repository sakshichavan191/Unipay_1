import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../models/auth_models.dart';
import '../../../theme/app_theme.dart';

class CardManagementScreen extends StatefulWidget {
  const CardManagementScreen({super.key});

  @override
  State<CardManagementScreen> createState() => _CardManagementScreenState();
}

class _CardManagementScreenState extends State<CardManagementScreen> with SingleTickerProviderStateMixin {
  final _cardUidController = TextEditingController();
  late AnimationController _fadeInController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeInController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeInController, curve: Curves.easeIn);
    _fadeInController.forward();
  }

  @override
  void dispose() {
    _cardUidController.dispose();
    _fadeInController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final uid = _cardUidController.text.trim();
    if (uid.isEmpty) return;

    final provider = Provider.of<AdminProvider>(context, listen: false);
    final success = await provider.registerCard(uid);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card registered successfully!'), backgroundColor: AppTheme.success),
      );
      _cardUidController.clear();
      _showLinkOfferDialog(uid);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Registration failed'), backgroundColor: AppTheme.danger),
      );
    }
  }

  void _showLinkOfferDialog(String cardUid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.success.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 40),
        ),
        title: const Text('Registration Success!'),
        content: Text(
          'Card $cardUid is now in the inventory.\nWould you like to link it to a student now?',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(elevation: 0),
            onPressed: () {
              Navigator.pop(ctx);
              _showUserPickerSheet(cardUid);
            },
            icon: const Icon(Icons.link_rounded, size: 18),
            label: const Text('Link Now'),
          ),
        ],
      ),
    );
  }

  void _showUserPickerSheet(String cardUid) {
    final provider = Provider.of<AdminProvider>(context, listen: false);
    provider.fetchStudentsForLinking();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UserPickerSheet(cardUid: cardUid),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AdminProvider>().isLoading;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      appBar: AppBar(title: const Text('Card Inventory', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernInfoBox(),
              const SizedBox(height: 32),
              
              Text(
                'Register Physical Token',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 10),
              Text(
                'Assign a new NFC chip to the UniPay ecosystem.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
              
              const SizedBox(height: 24),
              TextField(
                controller: _cardUidController,
                decoration: InputDecoration(
                  labelText: 'NFC UID',
                  hintText: 'e.g. 04:A1:B2:C3:D4:E5:F6',
                  prefixIcon: const Icon(Icons.nfc_rounded, color: AppTheme.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: cardColor,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: isLoading ? null : _handleRegister,
                  child: isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Register to Inventory', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              
              const SizedBox(height: 44),
              _buildStaggeredUtilityActions(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernInfoBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary.withOpacity(0.08), AppTheme.primary.withOpacity(0.03)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.bolt_rounded, color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin Access', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 4),
                Text(
                  'Quickly link new student cards or remotely manage blocked assets.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaggeredUtilityActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Utility Management',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildActionTile(0, 'Link Active Card', 'Assign registered UID to student', Icons.link_rounded, AppTheme.primary, () => _showManualLinkDialog(context)),
        _buildActionTile(1, 'Manual Unlink', 'Remove association via UID', Icons.link_off_rounded, AppTheme.danger, () => _showManualActionDialog(context, 'Unlink')),
        _buildActionTile(2, 'Status Override', 'Toggle card state remotely', Icons.sync_rounded, Colors.orange, () => _showManualActionDialog(context, 'Toggle')),
      ],
    );
  }

  Widget _buildActionTile(int index, String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 15 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(sub, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showManualLinkDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Manual Link Request'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Registered Card UID',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final uid = controller.text.trim();
              if (uid.isEmpty) return;
              Navigator.pop(ctx);
              _showUserPickerSheet(uid);
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  void _showManualActionDialog(BuildContext context, String action) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Confirm $action'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Card UID',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: action == 'Unlink' ? AppTheme.danger : AppTheme.primary),
            onPressed: () async {
              final uid = controller.text.trim();
              if (uid.isEmpty) return;
              Navigator.pop(context);
              
              final provider = Provider.of<AdminProvider>(context, listen: false);
              bool success = false;
              if (action == 'Unlink') success = await provider.unlinkCard(uid, -1); 
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '$action completed' : (provider.errorMessage ?? 'Action failed')),
                    backgroundColor: success ? AppTheme.success : AppTheme.danger,
                  ),
                );
              }
            },
            child: Text(action, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _UserPickerSheet extends StatefulWidget {
  final String cardUid;
  const _UserPickerSheet({required this.cardUid});

  @override
  State<_UserPickerSheet> createState() => _UserPickerSheetState();
}

class _UserPickerSheetState extends State<_UserPickerSheet> {
  String _searchQuery = '';
  bool _isLinking = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final allUsers = provider.linkableUsers;
    final filtered = _searchQuery.isEmpty ? allUsers : allUsers.where((u) {
      final q = _searchQuery.toLowerCase();
      return u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q) || (u.studentId?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 24),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(15)),
                  child: const Icon(Icons.person_search_rounded, color: AppTheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Link Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Targeting Card: ${widget.cardUid}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          Expanded(
            child: allUsers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final user = filtered[index];
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 300 + (index * 50)),
                        curve: Curves.easeOut,
                        builder: (context, value, child) => Transform.translate(
                          offset: Offset(0, 10 * (1 - value)),
                          child: Opacity(opacity: value, child: child),
                        ),
                        child: _UserTile(user: user, isLinking: _isLinking, onTap: () => _handleLink(user)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLink(User user) async {
    setState(() => _isLinking = true);
    final provider = Provider.of<AdminProvider>(context, listen: false);
    final success = await provider.linkCard(widget.cardUid, user.id);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${user.name} linked successfully!'), backgroundColor: AppTheme.success));
    } else {
      setState(() => _isLinking = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Link failed'), backgroundColor: AppTheme.danger));
    }
  }
}

class _UserTile extends StatelessWidget {
  final User user;
  final bool isLinking;
  final VoidCallback onTap;
  const _UserTile({required this.user, required this.isLinking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isLinking ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.primary.withOpacity(0.12),
                child: Text(user.name[0].toUpperCase(), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(user.studentId ?? user.email, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                  ],
                ),
              ),
              if (user.isBlocked == true)
                const Icon(Icons.lock_rounded, size: 16, color: AppTheme.danger)
              else
                Icon(Icons.link_rounded, size: 18, color: Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }
}
