import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform, debugPrint;
import 'package:flutter/widgets.dart' show GlobalKey, NavigatorState;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_constants.dart';
import '../firebase/habitduel_firestore_store.dart';
import 'notification_service.dart';

/// Обработчик входящих FCM пушей в фоне.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background message: ${message.notification?.title}');
}

/// Сервис FCM: регистрация токенов, приём пушей, Smart Reminder scheduling.
class FcmService {
  FcmService._();

  static final instance = FcmService._();

  final _messaging = FirebaseMessaging.instance;
  final _storage = const FlutterSecureStorage();
  final _store = HabitDuelFirestoreStore();

  Future<void> init() async {
    if (kIsWeb) return;

    // Регистрируем background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Запрашиваем разрешения
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    // Синхронизируем токен
    await syncCurrentUserToken();

    // Обновление токена
    _messaging.onTokenRefresh.listen((token) {
      syncToken(token);
    });

    // Обработка пушей, когда приложение открыто (foreground)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Обработка клика на пуш из background (приложение было свёрнуто)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Проверяем, был ли запуск через пуш
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  // ─── Foreground message handler ──────────────────────────────────

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('FCM foreground: ${message.notification?.title}');
    final data = message.data;
    final type = data['type'] as String?;

    switch (type) {
      case 'streak_broken':
        final username = data['username'] as String? ?? 'Opponent';
        final streak = int.tryParse(data['old_streak'] as String? ?? '0') ?? 0;
        NotificationService.instance.showStreakBrokenNotification(
          opponentUsername: username,
          oldStreak: streak,
        );
      case 'duel_reminder':
        NotificationService.instance.showCheckInReminder(
          habitName: data['habit_name'] as String? ?? 'Duel',
        );
      case 'opponent_checkin':
        NotificationService.instance.showOpponentCheckinNotification(
          opponentUsername: data['username'] as String? ?? 'Opponent',
          habitName: data['habit_name'] as String? ?? '',
        );
      case 'group_lobby_ready':
        NotificationService.instance.showGroupLobbyReadyNotification(
          duelId: data['duel_id'] as String? ?? '',
          habitName: data['habit_name'] as String? ?? '',
        );
      default:
        // Показываем как обычное уведомление
        if (message.notification != null) {
          NotificationService.instance.showGenericNotification(
            title: message.notification!.title ?? 'HabitDuel',
            body: message.notification!.body ?? '',
          );
        }
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('FCM app opened from message: ${message.data}');
    final duelId = message.data['duel_id'] as String?;
    if (duelId != null && duelId.isNotEmpty) {
      final type = message.data['type'] as String?;
      final route = type == 'group_lobby_ready' ? '/group-lobby' : '/duel';
      _navigatorKey?.currentState?.pushNamed(route, arguments: duelId);
    }
  }

  /// Глобальный ключ навигатора — должен быть установлен из main.dart.
  static GlobalKey<NavigatorState>? _navigatorKey;
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  // ─── Token management ────────────────────────────────────────────

  Future<void> syncCurrentUserToken() async {
    if (kIsWeb) return;
    final userId = await _storage.read(key: kUserIdKey);
    if (userId == null || userId.isEmpty) return;

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    await syncToken(token, userId: userId);
  }

  Future<void> syncToken(String token, {String? userId}) async {
    if (kIsWeb) return;

    final resolvedUserId = userId ?? await _storage.read(key: kUserIdKey);
    if (resolvedUserId == null || resolvedUserId.isEmpty) return;

    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };

    await _store.registerDeviceToken(
      userId: resolvedUserId,
      token: token,
      platform: platform,
    );
  }

  // ─── Smart Reminder scheduling ───────────────────────────────────

  /// Планирует умное напоминание на основе паттерна чекинов пользователя.
  ///
  /// Если среднее время чекина пользователя — 08:30, то напоминание придёт
  /// в 08:30 (если ещё не было сделан чекин), либо в 20:00 как вечерний дедлайн.
  Future<void> scheduleSmartReminder({
    required String userId,
    required String duelId,
    required String habitName,
  }) async {
    final pattern = await _store.readCheckinPattern(userId);
    final preferredHour = pattern?.preferredHour ?? 9;
    final preferredMinute = pattern?.preferredMinute ?? 0;

    await NotificationService.instance.scheduleSmartReminder(
      duelId: duelId,
      habitName: habitName,
      preferredHour: preferredHour,
      preferredMinute: preferredMinute,
    );
  }

  /// Обновляет паттерн после успешного чекина.
  Future<void> onCheckinCompleted(String userId, DateTime checkinTime) async {
    await _store.updateCheckinPattern(userId, checkinTime);
  }
}