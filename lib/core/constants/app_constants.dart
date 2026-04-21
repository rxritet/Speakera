import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kDebugMode, kIsWeb, TargetPlatform;

/// Базовый URL API-сервера HabitDuel.
///
/// Можно переопределить через `--dart-define=API_BASE_URL=https://...`.
/// В debug используются локальные адреса для эмулятора/симулятора.
String get kBaseUrl {
  const overrideUrl = String.fromEnvironment('API_BASE_URL');
  if (overrideUrl.isNotEmpty) {
    return overrideUrl;
  }

  if (kIsWeb) {
    final webUri = Uri.base;
    final scheme = webUri.scheme == 'https' ? 'https' : 'http';
    final host = webUri.host.isEmpty ? 'localhost' : webUri.host;
    return '$scheme://$host:8080';
  }

  if (kDebugMode) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8080';
      case TargetPlatform.iOS:
        return 'http://localhost:8080';
      default:
        return 'http://localhost:8080';
    }
  }

  throw StateError(
    'API_BASE_URL must be provided for non-debug mobile builds via --dart-define',
  );
}

/// Тайм-ауты HTTP.
///
/// В debug делаем fail-fast, чтобы UI не подвисал долго,
/// если локальный backend не запущен.
Duration get kConnectTimeout =>
  kDebugMode ? const Duration(seconds: 3) : const Duration(seconds: 10);

Duration get kReceiveTimeout =>
  kDebugMode ? const Duration(seconds: 5) : const Duration(seconds: 10);

/// Ключи защищённого хранилища.
const String kTokenKey = 'jwt_token';
const String kUserIdKey = 'user_id';
const String kUsernameKey = 'username';
