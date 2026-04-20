import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/pin_service.dart';
import '../../theme/app_theme.dart';
import 'pin_lock_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();

    _handleStartUp();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleStartUp() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isAuthenticated) {
      // Check if PIN lock is enabled
      final pinEnabled = await PinService.isPinEnabled();
      if (pinEnabled && mounted) {
        final unlocked = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const PinLockScreen(mode: PinScreenMode.verify)),
        );
        if (unlocked != true) return; // User didn't unlock — stay on splash
      }

      if (!mounted) return;
      final user = auth.user;
      if (user?.role == 'ADMIN') {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else if (user?.role == 'MERCHANT') {
        Navigator.pushReplacementNamed(context, '/merchant-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cardBg,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.credit_card_rounded,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              const Text('UniPay', style: TextStyle(
                  color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Cashless Campus Payments',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}