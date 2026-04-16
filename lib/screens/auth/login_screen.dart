import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatelessWidget {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text('Welcome back 👋',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Sign in to your UniPay account',
                  style: TextStyle(color: Colors.grey.shade500)),
              const SizedBox(height: 40),
              _buildField('Email', Icons.email_outlined, _emailController),
              const SizedBox(height: 16),
              _buildField('Password', Icons.lock_outline, _passController,
                  obscure: true),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                  child: const Text('Sign In'),
                ),
              ),
              const SizedBox(height: 16),
              Center(child: TextButton(
                onPressed: () {},
                child: const Text("Don't have an account? Register"),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, IconData icon,
      TextEditingController ctrl, {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}