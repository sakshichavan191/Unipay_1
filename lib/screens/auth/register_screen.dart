import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _studentIdController = TextEditingController();
  bool _obscurePassword = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _studentIdController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      await auth.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passController.text,
        _studentIdController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(msg)),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('SocketException') || raw.contains('ClientException') || raw.contains('HandshakeException')) {
      return 'Cannot reach server. Please check your internet connection.';
    }
    if (raw.contains('TimeoutException')) {
      return 'Server is taking too long. Please try again.';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Form(
            key: _formKey,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  ),
                  const SizedBox(height: 24),
                  
                  // Animated Header
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, val, child) => Transform.translate(
                      offset: Offset(0, 15 * (1 - val)),
                      child: child,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Join UniPay 🎓',
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Create a student account to get started',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Cascading Inputs
                  _buildAnimatedInput(0, 'Full Name', Icons.person_outline_rounded, _nameController),
                  const SizedBox(height: 18),
                  _buildAnimatedInput(1, 'Email Address', Icons.alternate_email_rounded, _emailController),
                  const SizedBox(height: 18),
                  _buildAnimatedInput(2, 'Student ID', Icons.badge_outlined, _studentIdController),
                  const SizedBox(height: 18),
                  _buildAnimatedInput(3, 'Create Password', Icons.lock_open_rounded, _passController, isPassword: true),
                  
                  const SizedBox(height: 44),
                  
                  // Submit Button
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, child) => Transform.translate(
                      offset: Offset(0, 20 * (1 - val)),
                      child: Opacity(opacity: val, child: child),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: isLoading ? null : _handleRegister,
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedInput(int index, String label, IconData icon, TextEditingController ctrl, {bool isPassword = false}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 150)),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) => Transform.translate(
        offset: Offset(0, 15 * (1 - val)),
        child: Opacity(opacity: val, child: child),
      ),
      child: TextFormField(
        controller: ctrl,
        obscureText: isPassword && _obscurePassword,
        keyboardType: isPassword ? TextInputType.visiblePassword : TextInputType.text,
        textInputAction: isPassword ? TextInputAction.done : TextInputAction.next,
        validator: (val) {
          if (val == null || val.trim().isEmpty) return '$label is required';
          if (label.contains('Email') && !RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$').hasMatch(val.trim())) {
            return 'Enter a valid email';
          }
          if (isPassword && val.length < 6) return 'Password too short (6+ char)';
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
          suffixIcon: isPassword ? IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.grey.shade400,
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
          ),
          filled: true,
          fillColor: Theme.of(context).cardColor,
        ),
      ),
    );
  }
}
