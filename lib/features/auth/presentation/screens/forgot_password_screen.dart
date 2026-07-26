import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  int _step = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _isLoading = false;
        _step++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_step == 0 ? 'Forgot password' : _step == 1 ? 'Verify email' : 'Reset password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              if (_step == 0) ...[
                Text('Enter your email to receive a verification code', style: AppTextStyles.bodyMedium),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', hintText: 'you@example.com'),
                ),
                const SizedBox(height: 24),
                PrimaryButton(label: 'Send code', isLoading: _isLoading, onPressed: _submit),
              ] else if (_step == 1) ...[
                Text('Enter the 6-digit code sent to ${_emailController.text}', style: AppTextStyles.bodyMedium),
                const SizedBox(height: 24),
                TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(labelText: 'Verification code', hintText: '123456'),
                ),
                const SizedBox(height: 24),
                PrimaryButton(label: 'Verify', isLoading: _isLoading, onPressed: _submit),
              ] else ...[
                Text('Create a new password', style: AppTextStyles.bodyMedium),
                const SizedBox(height: 24),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirm new password'),
                ),
                const SizedBox(height: 24),
                PrimaryButton(label: 'Reset password', isLoading: _isLoading, onPressed: _submit),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
