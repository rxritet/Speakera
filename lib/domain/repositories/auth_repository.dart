import '../entities/user.dart';

class RegisterResult {
  const RegisterResult({required this.user, required this.token});
  final User user;
  final String token;
}

class LoginResult {
  const LoginResult({required this.user, required this.token});
  final User user;
  final String token;
}

abstract class AuthRepository {
  Future<RegisterResult> register({
    required String username,
    required String email,
    required String password,
  });

  Future<LoginResult> login({
    required String email,
    required String password,
  });

  Future<LoginResult> signInWithGoogle();

  Future<bool> hasToken();

  Future<void> logout();
}
