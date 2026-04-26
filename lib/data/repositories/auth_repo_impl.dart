import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/firebase/habitduel_firestore_store.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._storage, this._store);

  final FlutterSecureStorage _storage;
  final HabitDuelFirestoreStore _store;

  fb.FirebaseAuth get _auth => fb.FirebaseAuth.instance;

  @override
  Future<RegisterResult> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _assertFirebaseReady();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = credential.user!;

      await fbUser.updateDisplayName(username);

      final user = User(
        id: fbUser.uid,
        username: username,
        email: email,
        wins: 0,
        losses: 0,
      );

      await _persistLocally(fbUser.uid, username);
      unawaited(_store.mirrorUserFromAuth(user));

      return RegisterResult(
        user: user,
        token: await fbUser.getIdToken() ?? '',
      );
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  @override
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    _assertFirebaseReady();
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _buildLoginResult(credential.user!);
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  @override
  Future<LoginResult> signInWithGoogle() async {
    _assertFirebaseReady();
    try {
      late final fb.UserCredential credential;

      if (kIsWeb) {
        credential = await _auth.signInWithPopup(fb.GoogleAuthProvider());
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          throw const AuthFailure('Вход через Google отменён.');
        }

        final googleAuth = await googleUser.authentication;
        final googleCredential = fb.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        credential = await _auth.signInWithCredential(googleCredential);
      }

      final fbUser = credential.user;
      if (fbUser == null) {
        throw const AuthFailure('Не удалось получить пользователя Google.');
      }

      return _buildLoginResult(fbUser);
    } on AuthFailure {
      rethrow;
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    } on PlatformException catch (e) {
      final message = e.message ?? e.toString();
      if (e.code == 'sign_in_failed' && message.contains('ApiException: 10')) {
        throw const AuthFailure(
          'Google Sign-In не настроен для Android. Добавьте SHA-1 и SHA-256 в Firebase, скачайте новый google-services.json и пересоберите APK.',
        );
      }
      throw AuthFailure('Ошибка входа через Google: $message');
    } catch (e) {
      throw AuthFailure('Ошибка входа через Google: $e');
    }
  }

  @override
  Future<bool> hasToken() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final savedId = await _storage.read(key: kUserIdKey);
      if (savedId == null || savedId.isEmpty) {
        final username =
            currentUser.displayName ?? currentUser.email?.split('@').first ?? '';
        await _persistLocally(currentUser.uid, username);
      }
      return true;
    }

    await _storage.delete(key: kTokenKey);
    await _storage.delete(key: kUserIdKey);
    await _storage.delete(key: kUsernameKey);
    return false;
  }

  @override
  Future<void> logout() async {
    await _storage.delete(key: kTokenKey);
    await _storage.delete(key: kUserIdKey);
    await _storage.delete(key: kUsernameKey);

    if (Firebase.apps.isNotEmpty) {
      await _auth.signOut();
    }

    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Ignore Google sign-out failures for non-Google sessions.
    }
  }

  Future<LoginResult> _buildLoginResult(fb.User fbUser) async {
    final email = fbUser.email;
    final profile = await _store.readProfile(fbUser.uid);
    final username =
        profile?.username ?? fbUser.displayName ?? email?.split('@').first ?? 'Player';

    await _persistLocally(fbUser.uid, username);

    final user = User(
      id: fbUser.uid,
      username: username,
      email: email,
      wins: profile?.wins ?? 0,
      losses: profile?.losses ?? 0,
    );

    if (profile == null) {
      unawaited(_store.mirrorUserFromAuth(user));
    }

    return LoginResult(
      user: user,
      token: await fbUser.getIdToken() ?? '',
    );
  }

  Future<void> _persistLocally(String uid, String username) async {
    await _storage.write(key: kUserIdKey, value: uid);
    await _storage.write(key: kUsernameKey, value: username);
    await _storage.write(key: kTokenKey, value: 'firebase');
  }

  void _assertFirebaseReady() {
    if (Firebase.apps.isEmpty) {
      throw const AuthFailure('Firebase is not initialized.');
    }
  }

  AuthFailure _mapFirebaseError(fb.FirebaseAuthException e) {
    final message = switch (e.code) {
      'account-exists-with-different-credential' =>
        'Этот Google-аккаунт уже связан с другим способом входа.',
      'email-already-in-use' => 'Этот email уже занят. Попробуйте войти.',
      'user-not-found' => 'Пользователь не найден.',
      'wrong-password' => 'Неверный пароль.',
      'invalid-email' => 'Некорректный email.',
      'weak-password' => 'Пароль слишком слабый. Минимум 6 символов.',
      'too-many-requests' => 'Слишком много попыток. Попробуйте позже.',
      'invalid-credential' => 'Неверный email или пароль.',
      _ => 'Ошибка авторизации: ${e.message ?? e.code}',
    };
    return AuthFailure(message);
  }
}
