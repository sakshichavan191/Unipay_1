import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/theme_provider.dart';
import '../../../widgets/edit_profile_sheet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    
    final textColor = Theme.of(context).textTheme.bodyLarge!.color;
    final subTextColor = Theme.of(context).textTheme.bodyMedium!.color;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          TextButton(
            onPressed: () => _showEditSheet(context, user?.name ?? '', user?.phone ?? ''),
            child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppTheme.primary,
                child: Text(
                  user?.name.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Text(
                user?.name ?? 'Loading...',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),

              Text(
                user?.role ?? 'User',
                style: TextStyle(color: subTextColor),
              ),

              const SizedBox(height: 28),

              _infoTile(
                context,
                Icons.email_outlined,
                'Email',
                user?.email ?? '-',
                cardColor,
                textColor,
                subTextColor,
              ),
              if (user?.studentId != null)
                _infoTile(
                  context,
                  Icons.badge_outlined,
                  'Student ID',
                  user!.studentId!,
                  cardColor,
                  textColor,
                  subTextColor,
                ),
              if (user?.businessName != null)
                _infoTile(
                  context,
                  Icons.business_outlined,
                  'Business',
                  user!.businessName!,
                  cardColor,
                  textColor,
                  subTextColor,
                ),
              _infoTile(
                context,
                Icons.phone_outlined,
                'Phone',
                user?.phone ?? 'Not set',
                cardColor,
                textColor,
                subTextColor,
              ),

              const SizedBox(height: 20),

              SwitchListTile(
                title: Text(
                  'Dark Mode',
                  style: TextStyle(color: textColor),
                ),
                value: Provider.of<ThemeProvider>(context).isDark,
                onChanged: (val) {
                  Provider.of<ThemeProvider>(context, listen: false)
                      .toggleTheme(val);
                },
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.danger,
                  ),
                  onPressed: () {
                    auth.logout();
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, String name, String phone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: EditProfileSheet(initialName: name, initialPhone: phone),
      ),
    );
  }

  Widget _infoTile(
      BuildContext context,
      IconData icon,
      String label,
      String value,
      Color cardColor,
      Color? textColor,
      Color? subTextColor,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: subTextColor, fontSize: 12),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}