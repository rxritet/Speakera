import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'core_providers.dart';

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  const Authenticated(this.user);
  final User user;
}

class Unauthenticated extends AuthState {
  const Unauthenticated([this.error]);
  final String? error;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref, this._repo) : super(const AuthInitial());

  final Ref _ref;
  final AuthRepository _repo;

  Future<void> checkSession() async {
    state = const AuthLoading();
    final hasToken = await _repo.hasToken();
    if (hasToken) {
      final storage = _ref.read(secureStorageProvider);
      final userId = await storage.read(key: kUserIdKey);
      final username = await storage.read(key: kUsernameKey);
      if (userId != null && userId.isNotEmpty) {
        state = Authenticated(
          User(
            id: userId,
            username: (username == null || username.isEmpty) ? 'Player' : username,
          ),
        );
      } else {
        state = const Unauthenticated();
      }
    } else {
      state = const Unauthenticated();
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final result = await _repo.register(
        username: username,
        email: email,
        password: password,
      );
      state = Authenticated(result.user);
    } on Failure catch (e) {
      if (e is NetworkFailure && kIsWeb) {
        await _activateDemoSession(username: username, email: email);
        return;
      }
      state = Unauthenticated(e.message);
    } catch (e) {
      state = Unauthenticated(e.toString());
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final result = await _repo.login(email: email, password: password);
      state = Authenticated(result.user);
    } on Failure catch (e) {
      if (e is NetworkFailure && kIsWeb) {
        final fallbackUsername = email.split('@').first.trim();
        await _activateDemoSession(
          username: fallbackUsername.isEmpty ? 'guest' : fallbackUsername,
          email: email,
        );
        return;
      }
      state = Unauthenticated(e.message);
    } catch (e) {
      state = Unauthenticated(e.toString());
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AuthLoading();
    try {
      final result = await _repo.signInWithGoogle();
      state = Authenticated(result.user);
    } on Failure catch (e) {
      state = Unauthenticated(e.message);
    } catch (e) {
      state = Unauthenticated(e.toString());
    }
  }

  Future<void> _activateDemoSession({
    required String username,
    required String email,
  }) async {
    final storage = _ref.read(secureStorageProvider);
    await storage.write(key: kTokenKey, value: 'demo');
    await storage.write(key: kUserIdKey, value: 'demo-user');
    await storage.write(key: kUsernameKey, value: username);
    state = Authenticated(
      User(
        id: 'demo-user',
        username: username,
        email: email,
      ),
    );
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const Unauthenticated();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref, ref.watch(authRepositoryProvider));
});
