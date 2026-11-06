import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:carlton_leisure_app/features/auth/data/models/login_request.dart';
import 'package:carlton_leisure_app/features/auth/domain/entities/login_result.dart';
import 'package:carlton_leisure_app/features/auth/domain/entities/mfa_challenge.dart';
import 'package:carlton_leisure_app/features/auth/domain/entities/user.dart';
import 'package:carlton_leisure_app/features/auth/domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthCheckSessionRequested>(_onCheckSession);
    on<AuthMfaVerifyRequested>(_onMfaVerify);
    on<AuthMfaResendRequested>(_onMfaResend);
    on<AuthMfaCancelled>(_onMfaCancelled);
  }

  final AuthRepository authRepository;

  /// The pending MFA challenge between the password step and code entry.
  MfaChallenge? _challenge;

  /// Kept in memory only while the code screen is open, so "Resend code"
  /// can repeat the password step (the API has no separate resend endpoint).
  String? _pendingUsername;
  String? _pendingPassword;

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final result =
          await authRepository.login(event.username, event.password);
      switch (result) {
        case LoginSuccess(:final user):
          emit(AuthAuthenticated(user: user));
        case LoginMfaRequired(:final challenge):
          _challenge = challenge;
          _pendingUsername = event.username;
          _pendingPassword = event.password;
          emit(AuthMfaRequired(challenge: challenge, isNewChallenge: true));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.register(
        firstName: event.firstName,
        lastName: event.lastName,
        email: event.email,
        password: event.password,
        phoneCountryCode: event.phoneCountryCode,
        phoneNumber: event.phoneNumber,
        dateOfBirth: event.dateOfBirth,
        nationality: event.nationality,
      );
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await authRepository.logout();
    emit(AuthUnauthenticated());
  }

  Future<void> _onCheckSession(
    AuthCheckSessionRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final hasSession = await authRepository.hasActiveSession();
      if (hasSession) {
        final user = await authRepository.getCurrentUser();
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onMfaVerify(
    AuthMfaVerifyRequested event,
    Emitter<AuthState> emit,
  ) async {
    final challenge = _challenge;
    if (challenge == null) {
      emit(AuthUnauthenticated());
      return;
    }
    emit(AuthLoading());
    try {
      final user = await authRepository.verifyMfa(challenge, event.code);
      _clearPending();
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthMfaRequired(
        challenge: challenge,
        errorMessage: _cleanMessage(e),
      ));
    }
  }

  Future<void> _onMfaResend(
    AuthMfaResendRequested event,
    Emitter<AuthState> emit,
  ) async {
    final challenge = _challenge;
    final username = _pendingUsername;
    final password = _pendingPassword;
    if (challenge == null || username == null || password == null) {
      _clearPending();
      emit(AuthUnauthenticated());
      return;
    }
    emit(AuthLoading());
    try {
      final result = await authRepository.login(username, password);
      switch (result) {
        case LoginSuccess(:final user):
          // 2FA was switched off in the meantime – just sign in.
          _clearPending();
          emit(AuthAuthenticated(user: user));
        case LoginMfaRequired(challenge: final fresh):
          _challenge = fresh;
          emit(AuthMfaRequired(challenge: fresh, codeResent: true));
      }
    } catch (e) {
      emit(AuthMfaRequired(
        challenge: challenge,
        errorMessage: _cleanMessage(e),
      ));
    }
  }

  void _onMfaCancelled(
    AuthMfaCancelled event,
    Emitter<AuthState> emit,
  ) {
    _clearPending();
    emit(AuthUnauthenticated());
  }

  void _clearPending() {
    _challenge = null;
    _pendingUsername = null;
    _pendingPassword = null;
  }

  String _cleanMessage(Object e) =>
      e.toString().replaceFirst('Exception: ', '');
}
