import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  final _errors = <String, String>{};

  bool _validate() {
    final e = <String, String>{};
    if (_emailCtrl.text.isEmpty) e['email'] = 'Email is required';
    if (_passCtrl.text.isEmpty) e['password'] = 'Password is required';
    setState(() => _errors..clear()..addAll(e));
    return e.isEmpty;
  }

  Future<void> _login() async {
    if (!_validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().login(_emailCtrl.text.trim(), _passCtrl.text);
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if(mounted && e.toString().contains('Email not verified')) {
        showError(context, 'Please confirm your email first');
        context.go('/confirm-email', extra: _emailCtrl.text.trim());
      } else if (mounted) {
        showError(context, e.toString());
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              // Logo
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.4), blurRadius: 24, spreadRadius: 4)],
                ),
                child: const Center(child: Text('M', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800))),
              ),
              const SizedBox(height: 24),
              const Text('Welcome back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text('Sign in to your account', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 40),
              // Card
              AppCard(
                child: Column(
                  children: [
                    AppTextField(
                      label: 'Email address',
                      hint: 'you@example.com',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _errors['email'],
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Password',
                      hint: 'Your password',
                      controller: _passCtrl,
                      obscure: true,
                      errorText: _errors['password'],
                    ),
                    const SizedBox(height: 24),
                    AppButton(label: 'Sign in', onPressed: _login, loading: _loading, width: double.infinity),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ", style: TextStyle(color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => context.go('/signup'),
                    child: const Text('Create one', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
