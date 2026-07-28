import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../presentation/bloc/auth_bloc.dart';
import '../../presentation/bloc/auth_event.dart';
import '../../presentation/bloc/auth_state.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  int _step = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_step == 0) {
      return _emailController.text.trim().isNotEmpty &&
          _phoneController.text.trim().isNotEmpty;
    }
    if (_step == 1) {
      return _newPasswordController.text.isNotEmpty &&
          _confirmPasswordController.text == _newPasswordController.text;
    }
    return false;
  }

  void _submit() {
    context.read<AuthBloc>().add(AuthCheckSessionRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_step == 0 ? 'Forgot password' : _step == 1 ? 'Verify contact' : 'Reset password')),
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
            if (state is AuthAuthenticated) {
              context.go('/home');
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                if (_step == 0) ...[
                  Text('Enter your email and phone number to verify your identity', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email', hintText: 'you@example.com'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone number', hintText: '+44 7700 900000'),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Verify',
                    isLoading: _isLoading,
                    onPressed: _isLoading || !_canSubmit ? null : _submit,
                  ),
                ] else if (_step == 1) ...[
                  Text('Enter your new password', style: AppTextStyles.bodyMedium),
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
                  PrimaryButton(
                    label: 'Reset password',
                    isLoading: _isLoading,
                    onPressed: _isLoading || !_canSubmit ? null : _submit,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
