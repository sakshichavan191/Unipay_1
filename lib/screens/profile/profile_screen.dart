import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge!.color;
    final subTextColor = Theme.of(context).textTheme.bodyMedium!.color;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),

      // ✅ FIX: Added scroll
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppTheme.primary,
                child: const Text(
                  'RS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Text(
                'Ravi Sharma',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),

              Text(
                'STU2024001',
                style: TextStyle(color: subTextColor),
              ),

              const SizedBox(height: 28),

              _infoTile(
                context,
                Icons.email_outlined,
                'Email',
                'ravi@university.edu',
                cardColor,
                textColor,
                subTextColor,
              ),
              _infoTile(
                context,
                Icons.phone_outlined,
                'Phone',
                '+91 98765 43210',
                cardColor,
                textColor,
                subTextColor,
              ),
              _infoTile(
                context,
                Icons.school_outlined,
                'Department',
                'Computer Engineering',
                cardColor,
                textColor,
                subTextColor,
              ),
              _infoTile(
                context,
                Icons.calendar_today_outlined,
                'Year',
                '3rd Year',
                cardColor,
                textColor,
                subTextColor,
              ),

              const SizedBox(height: 20),

              // 🌙 Dark Mode Toggle
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
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
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