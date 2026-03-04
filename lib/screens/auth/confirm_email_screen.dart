import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../api/api_service.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';

class ConfirmEmailScreen extends StatefulWidget {
  final String? email;
  const ConfirmEmailScreen({super.key, this.email});

  @override
  State<ConfirmEmailScreen> createState() => _ConfirmEmailScreenState();
}

class _ConfirmEmailScreenState extends State<ConfirmEmailScreen> {
  late final TextEditingController _emailCtrl;
  final _otpCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.email ?? '');
  }

  Future<void> _confirm() async {
    if (_emailCtrl.text.isEmpty || _otpCtrl.text.isEmpty) {
      showError(context, 'Please fill all fields');
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService().confirmEmail(_emailCtrl.text.trim(), _otpCtrl.text.trim());
      if (mounted) {
        showSuccess(context, 'Email confirmed! Please sign in.');
        context.go('/login');
      }
    } catch (e) {
      if (mounted) showError(context, e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Email'), leading: BackButton(onPressed: () => context.go('/login'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.successGlow,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: const Icon(Icons.mail_outline_rounded, color: AppColors.success, size: 32),
            ),
            const SizedBox(height: 20),
            const Text('Check your inbox', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('Enter the OTP code sent to your email', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 36),
            AppCard(
              child: Column(
                children: [
                  AppTextField(label: 'Email address', hint: 'you@example.com', controller: _emailCtrl, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  AppTextField(label: 'OTP Code', hint: 'Enter 6-character OTP', controller: _otpCtrl),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Check your spam folder if you don\'t see it', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ),
                  const SizedBox(height: 24),
                  AppButton(label: 'Confirm Email', onPressed: _confirm, loading: _loading, width: double.infinity, color: AppColors.success),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
