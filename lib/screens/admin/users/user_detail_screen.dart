import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/admin_provider.dart';
import '../../../theme/app_theme.dart';

class UserDetailScreen extends StatefulWidget {
  final int userId;
  const UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchUserDetails(widget.userId);
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _showBlockDialog(bool block) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(block ? 'Block User?' : 'Unblock User?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to ${block ? 'block' : 'unblock'} this user?'),
            if (block) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: block ? AppTheme.danger : AppTheme.success),
            onPressed: () async {
              Navigator.pop(context);
              final success = await Provider.of<AdminProvider>(context, listen: false).toggleUserBlock(
                widget.userId,
                block: block,
                reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
              );
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('User ${block ? 'blocked' : 'unblocked'} successfully'),
                    backgroundColor: block ? AppTheme.danger : AppTheme.success,
                  ),
                );
                _reasonController.clear();
              }
            },
            child: Text(block ? 'Block' : 'Unblock', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = Provider.of<AdminProvider>(context);
    final user = adminProv.selectedUserDetails;
    final isLoading = adminProv.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('User Details')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? const Center(child: Text('User not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildHeader(user),
                      const SizedBox(height: 32),
                      _buildStatsGrid(user),
                      const SizedBox(height: 32),
                      _buildInfoSection(user),
                      const SizedBox(height: 48),
                      _buildActionButtons(user),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader(user) {
    // isActive=false means the user is blocked (backend semantics)
    final bool isActive = user.isActive;
    Color roleColor = AppTheme.primary;
    if (user.role == 'MERCHANT') roleColor = AppTheme.success;
    if (user.role == 'ADMIN') roleColor = Colors.purple;

    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: roleColor.withOpacity(0.1),
          child: Text(
            user.fullName.substring(0, 1).toUpperCase(),
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: roleColor),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user.fullName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.success.withOpacity(0.1) : AppTheme.danger.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: FittedBox(
            child: Text(
              isActive ? 'ACTIVE' : 'BLOCKED',
              style: TextStyle(
                color: isActive ? AppTheme.success : AppTheme.danger,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(user) {
    return Column(
      children: [
        Row(
          children: [
            _buildStatCard('Wallet Balance', '₹${user.walletBalance.toStringAsFixed(2)}', Icons.account_balance_wallet_outlined, AppTheme.success),
            const SizedBox(width: 16),
            _buildStatCard('Linked Cards', user.linkedCards.toString(), Icons.credit_card_outlined, AppTheme.primary),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: (MediaQuery.of(context).size.width - 64) / 2, // 24*2 + 16/2? No, 24*2 + 12
              child: OutlinedButton.icon(
                onPressed: () => _showLinkCardDialog(),
                icon: const Icon(Icons.add_link_rounded, size: 18),
                label: const FittedBox(child: Text('Link New Card')),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            SizedBox(
              width: (MediaQuery.of(context).size.width - 64) / 2,
              child: OutlinedButton.icon(
                onPressed: () => _showUnlinkCardDialog(),
                icon: const Icon(Icons.link_off_rounded, size: 18),
                label: const FittedBox(child: Text('Unlink Card')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  side: const BorderSide(color: AppTheme.danger),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showLinkCardDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Link Card to User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the UID of a registered card to link it to this student.', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Card UID', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final uid = controller.text.trim();
              if (uid.isEmpty) return;
              Navigator.pop(context);
              final success = await Provider.of<AdminProvider>(context, listen: false).linkCard(uid, widget.userId);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Card linked successfully'), backgroundColor: AppTheme.success));
              }
            },
            child: const Text('Link Card'),
          ),
        ],
      ),
    );
  }

  void _showUnlinkCardDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink Card'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the UID of the card you wish to disconnect from this user.', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Card UID', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              final uid = controller.text.trim();
              if (uid.isEmpty) return;
              Navigator.pop(context);
              final success = await Provider.of<AdminProvider>(context, listen: false).unlinkCard(uid, widget.userId);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Card unlinked successfully'), backgroundColor: AppTheme.success));
              }
            },
            child: const Text('Unlink', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(user) {
    final DateFormat formatter = DateFormat('MMM dd, yyyy');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildInfoRow('Email', user.email, Icons.email_outlined),
          const Divider(height: 24),
          _buildInfoRow('Phone', user.phone ?? 'Not set', Icons.phone_outlined),
          const Divider(height: 24),
          _buildInfoRow('Role', user.role, Icons.badge_outlined),
          const Divider(height: 24),
          _buildInfoRow('Joined Date', formatter.format(user.createdAt.toLocal()), Icons.calendar_today_outlined),
          const Divider(height: 24),
          _buildInfoRow('System ID', '#${user.userId}', Icons.fingerprint_rounded),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade400),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(user) {
    // Never show a block/unblock button for admin accounts
    if (user.role == 'ADMIN') return const SizedBox.shrink();

    // isActive=false means the user is currently blocked
    final bool isBlocked = !user.isActive;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: isBlocked ? AppTheme.success : AppTheme.danger,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () => _showBlockDialog(!isBlocked),
          icon: Icon(isBlocked ? Icons.check_circle_outline_rounded : Icons.block_rounded),
          label: Text(
            isBlocked ? 'Unblock User' : 'Block User',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
