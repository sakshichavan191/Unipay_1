import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/theme_provider.dart';
import '../../../widgets/edit_profile_sheet.dart';
import '../../../services/pin_service.dart';
import '../../auth/pin_lock_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _pinEnabled = false;
  bool _pinLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPinStatus();
  }

  Future<void> _loadPinStatus() async {
    final enabled = await PinService.isPinEnabled();
    if (mounted) {
      setState(() {
        _pinEnabled = enabled;
        _pinLoading = false;
      });
    }
  }

  Future<void> _togglePin(bool enable) async {
    if (enable) {
      // Setup new PIN
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const PinLockScreen(mode: PinScreenMode.setup)),
      );
      if (result == true && mounted) {
        setState(() => _pinEnabled = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App PIN enabled!'), backgroundColor: AppTheme.success),
        );
      }
    } else {
      // Verify current PIN before disabling
      final unlocked = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const PinLockScreen(mode: PinScreenMode.verify)),
      );
      if (unlocked == true) {
        await PinService.removePin();
        if (mounted) {
          setState(() => _pinEnabled = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('App PIN disabled'), backgroundColor: AppTheme.danger),
          );
        }
      }
    }
  }

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

              const SizedBox(height: 12),

              // ─── Settings Section ──────────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Settings',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text('Dark Mode', style: TextStyle(color: textColor, fontSize: 14)),
                      secondary: Icon(
                        Provider.of<ThemeProvider>(context).isDark 
                            ? Icons.dark_mode_rounded 
                            : Icons.light_mode_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                      value: Provider.of<ThemeProvider>(context).isDark,
                      onChanged: (val) {
                        Provider.of<ThemeProvider>(context, listen: false).toggleTheme(val);
                      },
                    ),
                    Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                    SwitchListTile(
                      title: Text('App PIN Lock', style: TextStyle(color: textColor, fontSize: 14)),
                      subtitle: Text(
                        _pinEnabled ? 'PIN is active' : 'Protect app with a 4-digit PIN',
                        style: TextStyle(color: subTextColor, fontSize: 11),
                      ),
                      secondary: Icon(
                        _pinEnabled ? Icons.lock_rounded : Icons.lock_open_rounded,
                        color: _pinEnabled ? AppTheme.success : Colors.grey,
                        size: 20,
                      ),
                      value: _pinEnabled,
                      onChanged: _pinLoading ? null : _togglePin,
                    ),
                    if (_pinEnabled) ...[
                      Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                      ListTile(
                        leading: const Icon(Icons.password_rounded, color: AppTheme.primary, size: 20),
                        title: Text('Change PIN', style: TextStyle(color: textColor, fontSize: 14)),
                        trailing: const Icon(Icons.chevron_right, size: 18),
                        onTap: () async {
                          // Verify current PIN first
                          final unlocked = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(builder: (_) => const PinLockScreen(mode: PinScreenMode.verify)),
                          );
                          if (unlocked == true && mounted) {
                            final changed = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(builder: (_) => const PinLockScreen(mode: PinScreenMode.change)),
                            );
                            if (changed == true && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('PIN updated!'), backgroundColor: AppTheme.success),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.danger,
                  ),
                  onPressed: () {
                    auth.logout();
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