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

class _UserDetailScreenState extends State<UserDetailScreen> with TickerProviderStateMixin {
  final _reasonController = TextEditingController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();

    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchUserDetails(widget.userId);
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _showBlockDialog(bool block) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (block ? AppTheme.danger : AppTheme.success).withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(block ? Icons.block_rounded : Icons.check_circle_rounded, color: block ? AppTheme.danger : AppTheme.success, size: 32),
        ),
        title: Text(block ? 'Block Account?' : 'Unblock Account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to ${block ? 'suspend' : 'restore'} access for this user?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            if (block) ...[
              const SizedBox(height: 20),
              TextField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason for suspension',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: 'e.g., Security violation',
                ),
                maxLines: 2,
              ),
            ],
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: block ? AppTheme.danger : AppTheme.success,
              elevation: 0,
            ),
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
                    content: Text('Account ${block ? 'suspended' : 'restored'} successfully'),
                    backgroundColor: block ? AppTheme.danger : AppTheme.success,
                  ),
                );
                _reasonController.clear();
              }
            },
            child: Text(block ? 'Block Now' : 'Unblock Now', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      appBar: AppBar(title: const Text('Account Details', style: TextStyle(fontWeight: FontWeight.bold))),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? const Center(child: Text('User details unavailable'))
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      children: [
                        _buildHeader(user),
                        const SizedBox(height: 32),
                        _buildStatsGrid(user),
                        const SizedBox(height: 32),
                        _buildInfoSection(user),
                        const SizedBox(height: 40),
                        _buildActionButtons(user),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeader(user) {
    final bool isActive = user.isActive;
    Color roleColor = AppTheme.primary;
    IconData roleIcon = Icons.school_rounded;
    if (user.role == 'MERCHANT') {
      roleColor = AppTheme.success;
      roleIcon = Icons.storefront_rounded;
    }
    if (user.role == 'ADMIN') {
      roleColor = Colors.purple;
      roleIcon = Icons.admin_panel_settings_rounded;
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) => Transform.scale(scale: value, child: child),
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [roleColor.withOpacity(0.15), roleColor.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: roleColor.withOpacity(0.1)),
                ),
                child: Center(
                  child: Icon(roleIcon, size: 40, color: roleColor),
                ),
              ),
            ),
            // Pulsing Status Dot
            FadeTransition(
              opacity: _pulseController,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.success : AppTheme.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(user.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: (isActive ? AppTheme.success : AppTheme.danger).withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: (isActive ? AppTheme.success : AppTheme.danger).withOpacity(0.2)),
          ),
          child: Text(
            isActive ? 'ACTIVE ACCOUNT' : 'SUSPENDED',
            style: TextStyle(
              color: isActive ? AppTheme.success : AppTheme.danger,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
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
            _buildStatCard(0, 'Wallet Balance', '₹${user.walletBalance.toStringAsFixed(2)}', Icons.account_balance_wallet_rounded, AppTheme.success),
            const SizedBox(width: 14),
            _buildStatCard(1, 'Linked Cards', user.linkedCards.toString(), Icons.credit_card_rounded, AppTheme.primary),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _buildHeaderActionButton(0, 'Link Card', Icons.add_link_rounded, AppTheme.primary, () => _showLinkCardDialog()),
            const SizedBox(width: 12),
            _buildHeaderActionButton(1, 'Unlink', Icons.link_off_rounded, AppTheme.danger, () => _showUnlinkCardDialog()),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderActionButton(int index, String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 600 + (index * 150)),
        builder: (context, value, child) => Opacity(opacity: value, child: child),
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color.withOpacity(0.4)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }

  void _showLinkCardDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Link Registered Card'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Registered Card UID',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
            child: const Text('Link Now'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Disconnect Card'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Card UID to unlink',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
            child: const Text('Unlink Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(int index, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 400 + (index * 150)),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Transform.translate(
          offset: Offset(0, 15 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.04),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withOpacity(0.08)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(user) {
    final DateFormat formatter = DateFormat('MMMM dd, yyyy');
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildAnimatedInfoRow(0, 'Email Profile', user.email, Icons.alternate_email_rounded),
          Divider(height: 32, color: Colors.grey.withOpacity(0.05)),
          _buildAnimatedInfoRow(1, 'Contact Number', user.phone ?? 'Directly Not Provided', Icons.phone_android_rounded),
          Divider(height: 32, color: Colors.grey.withOpacity(0.05)),
          _buildAnimatedInfoRow(2, 'Access Privilege', user.role, Icons.security_rounded),
          Divider(height: 32, color: Colors.grey.withOpacity(0.05)),
          _buildAnimatedInfoRow(3, 'Registration Date', formatter.format(user.createdAt.toLocal()), Icons.event_available_rounded),
          Divider(height: 32, color: Colors.grey.withOpacity(0.05)),
          _buildAnimatedInfoRow(4, 'UniPay Sequence', '#ID-${user.userId}', Icons.tag_rounded),
        ],
      ),
    );
  }

  Widget _buildAnimatedInfoRow(int index, String label, String value, IconData icon) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (index * 80)),
      builder: (context, val, child) => Opacity(opacity: val, child: child),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: Colors.grey.shade400),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(user) {
    if (user.role == 'ADMIN') return const SizedBox.shrink();
    final bool isBlocked = !user.isActive;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (context, val, child) => Transform.scale(scale: 0.8 + (0.2 * val), child: Opacity(opacity: val, child: child)),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: isBlocked ? AppTheme.success : AppTheme.danger,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          onPressed: () => _showBlockDialog(!isBlocked),
          icon: Icon(isBlocked ? Icons.lock_open_rounded : Icons.lock_person_rounded),
          label: Text(
            isBlocked ? 'Restore Account Access' : 'Suspend Account',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
