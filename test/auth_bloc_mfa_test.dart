import 'package:carlton_leisure_app/features/auth/domain/entities/login_result.dart';
import 'package:carlton_leisure_app/features/auth/domain/entities/mfa_challenge.dart';
import 'package:carlton_leisure_app/features/auth/domain/entities/user.dart';
import 'package:carlton_leisure_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:carlton_leisure_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:carlton_leisure_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:carlton_leisure_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.codeIsValid = true});

  final bool codeIsValid;
  int loginCalls = 0;

  @override
  Future<LoginResult> login(String username, String password) async {
    loginCalls++;
    return LoginMfaRequired(
      MfaChallenge(
        challengeToken: 'tok-$loginCalls',
        maskedEmail: 'du****@mail.com',
      ),
    );
  }

  @override
  Future<UserEntity> verifyMfa(MfaChallenge challenge, String code) async {
    if (!codeIsValid) throw Exception('Invalid or expired code.');
    throw UnimplementedError('user construction is app specific');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('login that needs MFA emits AuthMfaRequired as a new challenge', () async {
    final bloc = AuthBloc(authRepository: _FakeAuthRepository());
    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<AuthLoading>(),
        isA<AuthMfaRequired>()
            .having((s) => s.isNewChallenge, 'isNewChallenge', true)
            .having((s) => s.challenge.challengeToken, 'token', 'tok-1'),
      ]),
    );
    bloc.add(AuthLoginRequested(username: 'a@b.com', password: 'pw'));
    await expectation;
    await bloc.close();
  });

  test('wrong code keeps the challenge and reports the error', () async {
    final bloc = AuthBloc(authRepository: _FakeAuthRepository(codeIsValid: false));
    bloc.add(AuthLoginRequested(username: 'a@b.com', password: 'pw'));
    await bloc.stream.firstWhere((s) => s is AuthMfaRequired);

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<AuthLoading>(),
        isA<AuthMfaRequired>()
            .having((s) => s.errorMessage, 'error', 'Invalid or expired code.'),
      ]),
    );
    bloc.add(AuthMfaVerifyRequested(code: '000000'));
    await expectation;
    await bloc.close();
  });

  test('resend repeats login and swaps in the new tempToken', () async {
    final bloc = AuthBloc(authRepository: _FakeAuthRepository());
    bloc.add(AuthLoginRequested(username: 'a@b.com', password: 'pw'));
    await bloc.stream.firstWhere((s) => s is AuthMfaRequired);

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<AuthLoading>(),
        isA<AuthMfaRequired>()
            .having((s) => s.codeResent, 'codeResent', true)
            .having((s) => s.challenge.challengeToken, 'token', 'tok-2'),
      ]),
    );
    bloc.add(AuthMfaResendRequested());
    await expectation;
    await bloc.close();
  });
}
