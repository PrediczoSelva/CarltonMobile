import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:carlton_leisure_app/features/auth/data/models/login_request.dart';
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
  }

  final AuthRepository authRepository;

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.login(event.username, event.password);
      emit(AuthAuthenticated(user: user));
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
}
