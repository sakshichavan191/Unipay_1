import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../models/auth_models.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProv = Provider.of<AdminProvider>(context, listen: false);
      
      // Determine if we should start with a specific role filter based on route
      final route = ModalRoute.of(context)?.settings.name;
      if (route == '/admin/manage-merchants') {
        adminProv.fetchUsers(role: 'MERCHANT');
      } else {
        adminProv.fetchUsers(role: 'ALL');
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      Provider.of<AdminProvider>(context, listen: false).fetchMoreUsers();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = Provider.of<AdminProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('All', 'ALL', adminProv),
                const SizedBox(width: 8),
                _buildFilterChip('Students', 'STUDENT', adminProv),
                const SizedBox(width: 8),
                _buildFilterChip('Merchants', 'MERCHANT', adminProv),
                const SizedBox(width: 8),
                _buildFilterChip('Admins', 'ADMIN', adminProv),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Showing ${adminProv.totalElements} users',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),

          Expanded(
            child: adminProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : adminProv.users.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => adminProv.fetchUsers(isInitial: true),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: adminProv.users.length + (adminProv.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == adminProv.users.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            final user = adminProv.users[index];
                            return _buildUserCard(context, user);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String role, AdminProvider provider) {
    final isSelected = provider.currentRole == role;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) provider.setRoleFilter(role);
      },
      selectedColor: AppTheme.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primary : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, User user) {
    final bool isMerchant = user.role == 'MERCHANT';
    final bool isStudent = user.role == 'STUDENT';
    final bool isAdmin = user.role == 'ADMIN';

    Color roleColor = Colors.grey;
    if (isStudent) roleColor = AppTheme.primary;
    if (isMerchant) roleColor = AppTheme.success;
    if (isAdmin) roleColor = Colors.purple;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: roleColor.withOpacity(0.1),
          child: Icon(
            isMerchant ? Icons.storefront_rounded : (isStudent ? Icons.school_rounded : Icons.admin_panel_settings_rounded),
            color: roleColor,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (user.isActive == false || user.isBlocked == true)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'BLOCKED',
                  style: TextStyle(color: AppTheme.danger, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              user.email,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    user.role,
                    style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                if (user.studentId != null)
                   Text('ID: ${user.studentId}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/admin/user-detail',
            arguments: user.id,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No users found matching this filter', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
