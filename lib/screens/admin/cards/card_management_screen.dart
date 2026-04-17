import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../theme/app_theme.dart';

class CardManagementScreen extends StatefulWidget {
  const CardManagementScreen({super.key});

  @override
  State<CardManagementScreen> createState() => _CardManagementScreenState();
}

class _CardManagementScreenState extends State<CardManagementScreen> {
  final _cardUidController = TextEditingController();

  Future<void> _handleRegister() async {
    final uid = _cardUidController.text.trim();
    if (uid.isEmpty) return;

    final provider = Provider.of<AdminProvider>(context, listen: false);
    final success = await provider.registerCard(uid);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card registered successfully!'), backgroundColor: AppTheme.success),
        );
        _cardUidController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'Registration failed'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AdminProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Card Inventory')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 32),
            const Text(
              'Register New Physical Card',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the physical NFC/RFID chip UID to add it to the UniPay system.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _cardUidController,
              decoration: InputDecoration(
                labelText: 'Card UID (e.g. NFC-UID-A1B2C3)',
                prefixIcon: const Icon(Icons.nfc_rounded, color: AppTheme.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleRegister,
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Register Card'),
              ),
            ),
            const SizedBox(height: 40),
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Cards must be registered in the system before they can be linked to any user account.',
              style: TextStyle(fontSize: 13, color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Utility Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildActionTile(
          context,
          'Manual Unlink',
          'Disconnect a card from its user via UID',
          Icons.link_off_rounded,
          AppTheme.danger,
          () => _showManualActionDialog(context, 'Unlink'),
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          context,
          'Toggle Status',
          'Activate or Deactivate a card remotely',
          Icons.toggle_on_outlined,
          Colors.orange,
          () => _showManualActionDialog(context, 'Toggle'),
        ),
      ],
    );
  }

  Widget _buildActionTile(BuildContext context, String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        sub,
        style: const TextStyle(fontSize: 11),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }

  void _showManualActionDialog(BuildContext context, String action) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manual $action'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Enter Card UID'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final uid = controller.text.trim();
              if (uid.isEmpty) return;
              Navigator.pop(context);
              
              final provider = Provider.of<AdminProvider>(context, listen: false);
              bool success = false;
              
              if (action == 'Unlink') {
                 // Note: unlinking in this generic context doesn't need userId for the API, 
                 // but my provider method takes it to refresh details. 
                 // I'll add a version without refresh.
                 success = await provider.unlinkCard(uid, -1); 
              }
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '$action successful' : (provider.errorMessage ?? 'Action failed')),
                    backgroundColor: success ? AppTheme.success : AppTheme.danger,
                  ),
                );
              }
            },
            child: const Text('Process'),
          ),
        ],
      ),
    );
  }
}
