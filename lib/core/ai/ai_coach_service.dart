import 'package:flutter/foundation.dart';

import '../../domain/entities/gamification.dart';

/// AI Coach — генерирует еженедельные персонализированные сообщения.
///
/// Логика: шаблонный движок на языковых паттернах (без внешнего API),
/// который анализирует статистику за неделю и создаёт уникальное сообщение.
/// В боевой версии — можно подключить Gemini API через Cloud Function.
class AiCoachService {
  AiCoachService._();
  static final instance = AiCoachService._();

  /// Генерирует сообщение коуча на основе статистики недели.
  AiCoachMessage generateWeeklyMessage({
    required String userId,
    required int checkinsThisWeek,
    required int bestStreak,
    required int totalDuels,
    required int wins,
    required int losses,
    required int xpThisWeek,
  }) {
    final weekStart = _weekStart(DateTime.now());
    final message = _buildMessage(
      checkinsThisWeek: checkinsThisWeek,
      bestStreak: bestStreak,
      wins: wins,
      losses: losses,
      xpThisWeek: xpThisWeek,
    );
    final suggestion = _buildSuggestion(
      checkinsThisWeek: checkinsThisWeek,
      bestStreak: bestStreak,
      wins: wins,
      losses: losses,
    );

    debugPrint('AiCoach: Generated weekly message for $userId');

    return AiCoachMessage(
      userId: userId,
      weekStartDate: weekStart,
      message: message,
      checkinsThisWeek: checkinsThisWeek,
      bestStreak: bestStreak,
      suggestion: suggestion,
      generatedAt: DateTime.now().toUtc(),
    );
  }

  // ─── Генерация сообщения ─────────────────────────────────────────────────

  String _buildMessage({
    required int checkinsThisWeek,
    required int bestStreak,
    required int wins,
    required int losses,
    required int xpThisWeek,
  }) {
    final performance = _classifyPerformance(
      checkinsThisWeek: checkinsThisWeek,
      bestStreak: bestStreak,
      wins: wins,
    );

    return switch (performance) {
      _Performance.excellent => _excellentMessages(
          checkinsThisWeek: checkinsThisWeek,
          bestStreak: bestStreak,
          xpThisWeek: xpThisWeek,
        ),
      _Performance.good => _goodMessages(
          checkinsThisWeek: checkinsThisWeek,
          bestStreak: bestStreak,
        ),
      _Performance.average => _averageMessages(
          checkinsThisWeek: checkinsThisWeek,
          losses: losses,
        ),
      _Performance.needsWork => _needsWorkMessages(
          checkinsThisWeek: checkinsThisWeek,
        ),
    };
  }

  String _excellentMessages({
    required int checkinsThisWeek,
    required int bestStreak,
    required int xpThisWeek,
  }) {
    final options = [
      '🔥 Отличная неделя! $checkinsThisWeek чекинов без пропусков — ты настоящая машина привычек. Стрик $bestStreak дней — это уже сила воли на уровне. Так держать!',
      '⚔️ Ты доминируешь! $bestStreak дней стрика — соперники должны бояться. На этой неделе ты заработал $xpThisWeek XP. Ты на правильном пути к легенде!',
      '🏆 Феноменально! $checkinsThisWeek из 7 чекинов выполнено. Твоя дисциплина — пример для всех участников HabitDuel этой недели.',
    ];
    return options[DateTime.now().second % options.length];
  }

  String _goodMessages({
    required int checkinsThisWeek,
    required int bestStreak,
  }) {
    final options = [
      '✅ Хорошая неделя! $checkinsThisWeek чекинов — ты в игре. Стрик $bestStreak дней пока держится. Осталось чуть-чуть до топ-результата.',
      '💪 Стабильность — ключ к победе. $checkinsThisWeek чекинов на этой неделе. Продолжай в том же духе, и стрик сам себя построит.',
      '📈 Прогресс виден! $bestStreak дней стрика — не останавливайся. Следующая неделя может быть ещё лучше.',
    ];
    return options[DateTime.now().second % options.length];
  }

  String _averageMessages({
    required int checkinsThisWeek,
    required int losses,
  }) {
    final options = [
      '⚡ Средний результат: $checkinsThisWeek чекинов. Ты можешь больше! Один пропущенный день — не конец, но тенденция тревожит. Давай исправим это?',
      '🎯 $checkinsThisWeek из 7 — есть над чем работать. Попробуй поставить напоминание на то время, когда обычно не забываешь. Маленький сдвиг — большой результат.',
      '🔍 Анализ говорит: ты пропускаешь чаще к концу недели. Включи «вечерний дедлайн» в настройках — это работает!',
    ];
    return options[DateTime.now().second % options.length];
  }

  String _needsWorkMessages({required int checkinsThisWeek}) {
    final options = [
      '💬 Всего $checkinsThisWeek чекинов за неделю. Не сдавайся — каждый великий воин привычек начинал именно так. Начни с малого: один чекин прямо сейчас.',
      '🌱 Нулевой стрик — это не провал, это чистый лист. Используй «Заморозку» чтобы защитить следующий стрик, если случится форс-мажор.',
      '🚀 Следующая неделя — это твой шанс. Поставь цель: хотя бы 4 чекина из 7. Маленькие победы строят большие.',
    ];
    return options[DateTime.now().second % options.length];
  }

  // ─── Генерация рекомендации ──────────────────────────────────────────────

  String _buildSuggestion({
    required int checkinsThisWeek,
    required int bestStreak,
    required int wins,
    required int losses,
  }) {
    if (checkinsThisWeek >= 7) {
      return 'Попробуй групповую дуэль с 3+ участниками — ты готов к новому уровню сложности!';
    }
    if (bestStreak >= 14) {
      return 'Стрик больше 14 дней? Создай дуэль на 30 дней — ты уже доказал, что можешь.';
    }
    if (losses > wins && checkinsThisWeek < 5) {
      return 'Включи «Умные напоминания» — приложение адаптируется под твой режим дня.';
    }
    if (checkinsThisWeek < 3) {
      return 'Используй Trusted Check-in: подключи Apple Health или Google Fit для автоматических отметок.';
    }
    return 'Пригласи друга в групповую дуэль — соревнование с живыми людьми мотивирует сильнее!';
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  _Performance _classifyPerformance({
    required int checkinsThisWeek,
    required int bestStreak,
    required int wins,
  }) {
    if (checkinsThisWeek == 7 || bestStreak >= 14) return _Performance.excellent;
    if (checkinsThisWeek >= 5 || bestStreak >= 7) return _Performance.good;
    if (checkinsThisWeek >= 3) return _Performance.average;
    return _Performance.needsWork;
  }

  DateTime _weekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }
}

enum _Performance { excellent, good, average, needsWork }
