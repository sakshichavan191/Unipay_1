import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/card_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/admin_provider.dart';

import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/student/home/home_screen.dart';
import 'screens/merchant/home/merchant_dashboard.dart';
import 'screens/student/card/card_screen.dart';
import 'screens/student/topup/topup_screen.dart';
import 'screens/shared/transactions/transactions_screen.dart';
import 'screens/shared/transactions/transaction_detail_screen.dart';
import 'screens/shared/profile/profile_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/merchants/register_merchant_screen.dart';
import 'screens/admin/users/manage_users_screen.dart';
import 'screens/admin/users/user_detail_screen.dart';
import 'screens/admin/cards/card_management_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final authProvider = AuthProvider();
  await authProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProxyProvider<AuthProvider, CardProvider>(
          create: (context) => CardProvider(authProvider),
          update: (context, auth, previous) => CardProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, PaymentProvider>(
          create: (context) => PaymentProvider(authProvider),
          update: (context, auth, previous) => PaymentProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AdminProvider>(
          create: (context) => AdminProvider(authProvider),
          update: (context, auth, previous) => AdminProvider(auth),
        ),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: const UniPayApp(),
    ),
  );
}

class UniPayApp extends StatelessWidget {
  const UniPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'UniPay',
          debugShowCheckedModeBanner: false,

          theme: AppTheme.theme,
          darkTheme: AppTheme.darkTheme,

          // 🔥 controlled manually now
          themeMode: themeProvider.themeMode,

          initialRoute: '/',
          routes: {
            '/':                   (_) => const SplashScreen(),
            '/login':              (_) => const LoginScreen(),
            '/register':           (_) => const RegisterScreen(),
            '/home':               (_) => HomeScreen(),
            '/merchant-dashboard': (_) => const MerchantDashboard(),
            '/card':               (_) => const CardScreen(),
            '/topup':              (_) => const TopupScreen(),
            '/transactions':       (_) => TransactionsScreen(),
            '/profile':            (_) => const ProfileScreen(),
            '/admin-dashboard':     (_) => const AdminDashboard(),
            '/admin/register-merchant': (_) => const RegisterMerchantScreen(),
            '/admin/manage-users':      (_) => const ManageUsersScreen(),
            '/admin/manage-merchants':  (_) => const ManageUsersScreen(), // Reusing with context handling possibly
            '/admin/manage-cards':      (_) => const CardManagementScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/transaction-detail') {
              final int id = settings.arguments as int;
              return MaterialPageRoute(
                builder: (context) => TransactionDetailScreen(transactionId: id),
              );
            }
            if (settings.name == '/admin/user-detail') {
              final int id = settings.arguments as int;
              return MaterialPageRoute(
                builder: (context) => UserDetailScreen(userId: id),
              );
            }
            return null;
          },
        );
      },
    );
  }
}