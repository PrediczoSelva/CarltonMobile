import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Second step of sign-in: the user types the 6-digit code sent to their email.
class MfaVerificationScreen extends StatefulWidget {
  const MfaVerificationScreen({super.key});

  @override
  State<MfaVerificationScreen> createState() => _MfaVerificationScreenState();
}

class _MfaVerificationScreenState extends State<MfaVerificationScreen> {
  static const int _codeLength = 6;
  static const int _resendCooldownSeconds = 30;

  final _codeController = TextEditingController();
  late final AuthBloc _authBloc;
  Timer? _timer;
  int _secondsLeft = _resendCooldownSeconds;

  @override
  void initState() {
    super.initState();
    _authBloc = context.read<AuthBloc>();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    // Leaving the screen without finishing cancels the pending sign-in.
    if (_authBloc.state is AuthMfaRequired) {
      _authBloc.add(AuthMfaCancelled());
    }
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendCooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
      }
      if (mounted) {
        setState(() => _secondsLeft = _secondsLeft > 0 ? _secondsLeft - 1 : 0);
      }
    });
  }

  void _submit() {
    final code = _codeController.text.trim();
    if (code.length != _codeLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit code.')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    _authBloc.add(AuthMfaVerifyRequested(code: code));
  }

  void _resend() {
    _codeController.clear();
    _authBloc.add(AuthMfaResendRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your identity')),
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              context.go('/home');
            } else if (state is AuthMfaRequired) {
              if (state.codeResent) {
                _startCooldown();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('A new code has been sent.')),
                );
              }
              final error = state.errorMessage;
              if (error != null) {
                _codeController.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error)),
                );
              }
            } else if (state is AuthUnauthenticated && context.canPop()) {
              context.pop();
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            final masked =
                state is AuthMfaRequired ? state.challenge.maskedEmail : null;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Text('Enter the code', style: AppTextStyles.h2),
                  const SizedBox(height: 8),
                  Text(
                    masked != null
                        ? 'We sent a 6-digit code to $masked.'
                        : 'We sent a 6-digit code to your email.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _codeController,
                    autofocus: true,
                    enabled: !isLoading,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: _codeLength,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontSize: 28, letterSpacing: 12),
                    decoration: const InputDecoration(
                      labelText: 'Verification code',
                      counterText: '',
                    ),
                    onChanged: (value) {
                      if (value.length == _codeLength && !isLoading) {
                        _submit();
                      }
                    },
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Verify',
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _submit,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: (isLoading || _secondsLeft > 0) ? null : _resend,
                    child: Text(
                      _secondsLeft > 0
                          ? 'Resend code in ${_secondsLeft}s'
                          : 'Resend code',
                    ),
                  ),
                  TextButton(
                    onPressed: isLoading ? null : () => context.pop(),
                    child: const Text('Back to sign in'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
