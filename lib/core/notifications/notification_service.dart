import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Ключи SharedPreferences.
const kReminderEnabledKey = 'reminder_enabled';
const kReminderHourKey = 'reminder_hour';
const kReminderMinuteKey = 'reminder_minute';
const kSmartReminderEnabledKey = 'smart_reminder_enabled';

/// Идентификаторы уведомлений.
const _dailyReminderId = 0;
const _streakBrokenId = 1;
const _opponentCheckinId = 2;
const _groupLobbyReadyId = 3;
const _checkInReminderId = 4;
const _genericId = 5;
const _eveningDeadlineId = 6;

/// Идентификаторы каналов Android.
const _channelId = 'habitduel_channel';
const _channelName = 'HabitDuel';
const _urgentChannelId = 'habitduel_urgent';
const _urgentChannelName = 'HabitDuel — Срочно';

/// Сервис уведомлений (синглтон).
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialised = false;

  /// Вызывается один раз при запуске приложения.
  Future<void> init() async {
    if (kIsWeb) return;
    if (_initialised) return;
    _initialised = true;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(initSettings);

    if (!kIsWeb && Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  // ─── Вспомогательные детали уведомлений ─────────────────────────────────

  NotificationDetails _normalDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  NotificationDetails _urgentDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _urgentChannelId,
        _urgentChannelName,
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(sound: 'default'),
    );
  }

  // ─── Ежедневное напоминание (ручное) ────────────────────────────────────

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return;
    await _plugin.cancel(_dailyReminderId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _dailyReminderId,
      'HabitDuel ⚔️',
      'Не забудь check-in! 🔥',
      scheduled,
      _normalDetails(),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() async {
    if (kIsWeb) return;
    await _plugin.cancel(_dailyReminderId);
  }

  Future<void> restoreReminder() async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(kReminderEnabledKey) ?? false;
    if (!enabled) return;
    final hour = prefs.getInt(kReminderHourKey) ?? 9;
    final minute = prefs.getInt(kReminderMinuteKey) ?? 0;
    await scheduleDailyReminder(hour: hour, minute: minute);
  }

  Future<void> saveAndScheduleReminder({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kReminderEnabledKey, enabled);
    await prefs.setInt(kReminderHourKey, hour);
    await prefs.setInt(kReminderMinuteKey, minute);

    if (enabled) {
      await scheduleDailyReminder(hour: hour, minute: minute);
    } else {
      await cancelDailyReminder();
    }
  }

  // ─── Smart Reminder (адаптивное) ─────────────────────────────────────────

  /// Планирует напоминание на предпочтительное время пользователя.
  /// Дополнительно — «вечерний дедлайн» в 20:00.
  Future<void> scheduleSmartReminder({
    required String duelId,
    required String habitName,
    required int preferredHour,
    required int preferredMinute,
  }) async {
    if (kIsWeb) return;

    final now = tz.TZDateTime.now(tz.local);

    // --- Основное напоминание в "умное" время ---
    var smartTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      preferredHour,
      preferredMinute,
    );
    if (smartTime.isBefore(now)) {
      smartTime = smartTime.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _checkInReminderId,
      'Время check-in! 💪',
      '$habitName — держи свою серию!',
      smartTime,
      _normalDetails(),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: duelId,
    );

    // --- Вечерний дедлайн в 20:00 (если умное время не вечернее) ---
    if (preferredHour < 18) {
      var eveningTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20, 0);
      if (eveningTime.isBefore(now)) {
        eveningTime = eveningTime.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        _eveningDeadlineId,
        'Последний шанс! ⏰',
        'До конца дня осталось немного. Не пропусти $habitName!',
        eveningTime,
        _urgentDetails(),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: duelId,
      );
    }
  }

  // ─── Мгновенные уведомления от событий дуэлей ───────────────────────────

  Future<void> showStreakBrokenNotification({
    required String opponentUsername,
    required int oldStreak,
  }) async {
    if (kIsWeb) return;
    await _plugin.show(
      _streakBrokenId,
      'Атакуй! 🎯',
      '$opponentUsername потерял стрик ($oldStreak дней). Время атаковать!',
      _urgentDetails(),
    );
  }

  Future<void> showOpponentCheckinNotification({
    required String opponentUsername,
    required String habitName,
  }) async {
    if (kIsWeb) return;
    await _plugin.show(
      _opponentCheckinId,
      'Соперник сделал check-in! 🔥',
      '$opponentUsername только что отметился в «$habitName». Не отставай!',
      _normalDetails(),
    );
  }

  Future<void> showCheckInReminder({required String habitName}) async {
    if (kIsWeb) return;
    await _plugin.show(
      _checkInReminderId,
      'HabitDuel напоминает 🕐',
      'Не забудь сделать check-in в «$habitName»!',
      _normalDetails(),
    );
  }

  Future<void> showGroupLobbyReadyNotification({
    required String duelId,
    required String habitName,
  }) async {
    if (kIsWeb) return;
    await _plugin.show(
      _groupLobbyReadyId,
      'Дуэль начинается! ⚔️',
      'Групповая дуэль «$habitName» готова. Все участники на борту!',
      _urgentDetails(),
      payload: duelId,
    );
  }

  Future<void> showGenericNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
    await _plugin.show(
      _genericId,
      title,
      body,
      _normalDetails(),
      payload: payload,
    );
  }

  /// Отмена запланированных напоминаний при успешном чекине.
  Future<void> cancelDuelReminders() async {
    if (kIsWeb) return;
    await _plugin.cancel(_checkInReminderId);
    await _plugin.cancel(_eveningDeadlineId);
  }
}
