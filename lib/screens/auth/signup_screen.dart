import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../api/api_service.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _phone = TextEditingController();
  final _dob = TextEditingController();
  bool _loading = false;
  final _errors = <String, String>{};

  bool _validate() {
    final e = <String, String>{};
    if (_username.text.isEmpty) e['username'] = 'Required';
    if (_email.text.isEmpty) e['email'] = 'Required';
    if (_pass.text.isEmpty) e['password'] = 'Required';
    if (_phone.text.isEmpty) e['phone'] = 'Required';
    if (_dob.text.isEmpty) e['dob'] = 'Required';
    final passReg = RegExp(r'(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#])');
    if (_pass.text.isNotEmpty && !passReg.hasMatch(_pass.text)) {
      e['password'] = 'Must have uppercase, number & special char';
    }
    setState(() => _errors..clear()..addAll(e));
    return e.isEmpty;
  }

  Future<void> _signup() async {
    if (!_validate()) return;
    setState(() => _loading = true);
    try {
      await ApiService().signup({
        'username': _username.text.trim(),
        'email': _email.text.trim(),
        'password': _pass.text,
        'phone': _phone.text.trim(),
        'DOB': _dob.text.trim(),
      });
      if (mounted) {
        showSuccess(context, 'Account created! Check your email.');
        context.go('/confirm-email', extra: _email.text.trim());
      }
    } catch (e) {
      if (mounted) showError(context, e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _username.dispose(); _email.dispose();
    _pass.dispose(); _phone.dispose(); _dob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: BackButton(onPressed: () => context.go('/login')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                children: [
                  AppTextField(
                    label: 'Username',
                    hint: 'Your full name',
                    controller: _username,
                    errorText: _errors['username'],
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Email',
                    hint: 'you@example.com',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    errorText: _errors['email'],
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Password',
                    hint: 'Password@123',
                    controller: _pass,
                    obscure: true,
                    errorText: _errors['password'],
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Phone',
                    hint: '01012345678',
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    errorText: _errors['phone'],
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Date of Birth',
                    hint: 'YYYY-MM-DD',
                    controller: _dob,
                    errorText: _errors['dob'],
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Create Account',
                    onPressed: _signup,
                    loading: _loading,
                    width: double.infinity,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account? ', style: TextStyle(color: AppColors.textSecondary)),
                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: const Text('Sign in', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}