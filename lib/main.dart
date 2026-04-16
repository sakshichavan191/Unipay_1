import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';

import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/card/card_screen.dart';
import 'screens/topup/topup_screen.dart';
import 'screens/transactions/transactions_screen.dart';
import 'screens/profile/profile_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
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
            '/':             (_) => const SplashScreen(),
            '/login':        (_) => LoginScreen(),
            '/home':         (_) => HomeScreen(),
            '/card':         (_) => const CardScreen(),
            '/topup':        (_) => const TopupScreen(),
            '/transactions': (_) => TransactionsScreen(),
            '/profile':      (_) => const ProfileScreen(),
          },
        );
      },
    );
  }
}