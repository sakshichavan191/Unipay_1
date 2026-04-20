import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Custom RefreshIndicator with the UniPay branding.
/// 
/// Usage: Replace `RefreshIndicator` with `UniPayRefreshIndicator`
/// everywhere. Same API — just wrap your scrollable child.
class UniPayRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const UniPayRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      backgroundColor: AppTheme.cardBg,
      color: Colors.white,
      displacement: 60,
      strokeWidth: 2.5,
      child: child,
    );
  }
}
