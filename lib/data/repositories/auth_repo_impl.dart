import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/firebase/habitduel_firestore_store.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Firebase Auth — основной провайдер аутентификации.
///
/// Логика:
/// 1. Регистрация/вход через [FirebaseAuth].
/// 2. При успехе записываем userId (=Firebase UID) в SecureStorage.
/// 3. Дублируем профиль в Firestore через [HabitDuelFirestoreStore].
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._storage, this._store);

  final FlutterSecureStorage _storage;
  final HabitDuelFirestoreStore _store;

  fb.FirebaseAuth get _auth => fb.FirebaseAuth.instance;

  // ─── Register ────────────────────────────────────────────────────────

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

      // Устанавливаем displayName сразу после создания
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

      return RegisterResult(user: user, token: await fbUser.getIdToken() ?? '');
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  // ─── Login ───────────────────────────────────────────────────────────

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
      final fbUser = credential.user!;

      // Пробуем прочитать профиль из Firestore
      final profile = await _store.readProfile(fbUser.uid);
      final username = profile?.username ?? fbUser.displayName ?? email.split('@').first;
      final wins = profile?.wins ?? 0;
      final losses = profile?.losses ?? 0;

      await _persistLocally(fbUser.uid, username);

      final user = User(
        id: fbUser.uid,
        username: username,
        email: email,
        wins: wins,
        losses: losses,
      );

      return LoginResult(user: user, token: await fbUser.getIdToken() ?? '');
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  // ─── Session management ──────────────────────────────────────────────

  @override
  Future<bool> hasToken() async {
    // Приоритет: Firebase session
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      // Синхронизируем SecureStorage если нужно
      final savedId = await _storage.read(key: kUserIdKey);
      if (savedId == null || savedId.isEmpty) {
        final username = currentUser.displayName ?? currentUser.email?.split('@').first ?? '';
        await _persistLocally(currentUser.uid, username);
      }
      return true;
    }
    // Fallback: старый JWT токен (для совместимости при первом запуске)
    final token = await _storage.read(key: kTokenKey);
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> logout() async {
    await _storage.delete(key: kTokenKey);
    await _storage.delete(key: kUserIdKey);
    await _storage.delete(key: kUsernameKey);
    if (Firebase.apps.isNotEmpty) {
      await _auth.signOut();
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

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
