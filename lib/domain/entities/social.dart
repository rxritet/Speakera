/// Социальные функции (друзья, чат).
class Friend {
  const Friend({
    required this.id,
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.level,
    required this.totalWins,
    this.isOnline = false,
    this.lastActiveAt,
    this.friendSince,
    this.totalDuelsTogether = 0,
    this.winsAgainstMe = 0,
    this.lossesAgainstMe = 0,
  });

  final String id;
  final String userId;
  final String username;
  final String avatarUrl;
  final int level;
  final int totalWins;
  final bool isOnline;
  final DateTime? lastActiveAt;
  final DateTime? friendSince;
  final int totalDuelsTogether;
  final int winsAgainstMe;
  final int lossesAgainstMe;

  String get statusLabel {
    if (isOnline) return 'Онлайн';
    if (lastActiveAt == null) return 'Был(а) недавно';
    final diff = DateTime.now().difference(lastActiveAt!);
    if (diff.inMinutes < 5) return 'Был(а) только что';
    if (diff.inHours < 1) return 'Был(а) ${diff.inMinutes} мин. назад';
    if (diff.inDays < 1) return 'Был(а) ${diff.inHours} ч. назад';
    return 'Был(а) ${diff.inDays} дн. назад';
  }
}

/// Запрос в друзья.
class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUsername,
    required this.fromAvatar,
    required this.createdAt,
  });

  final String id;
  final String fromUserId;
  final String fromUsername;
  final String fromAvatar;
  final DateTime createdAt;
}

/// Сообщение в чате дуэли.
class DuelMessage {
  const DuelMessage({
    required this.id,
    required this.duelId,
    required this.senderId,
    required this.senderName,
    required this.messageType,
    this.text,
    this.emoji,
    this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String duelId;
  final String senderId;
  final String senderName;
  final DuelMessageType messageType;
  final String? text;
  final String? emoji;
  final DateTime? createdAt;
  final bool isRead;
}

enum DuelMessageType {
  text,
  emoji,
  quick('Быстрое'),
  system('Системное');

  const DuelMessageType([this.label = '']);
  final String label;
}

/// Быстрые сообщения для чата.
class QuickMessage {
  const QuickMessage({
    required this.id,
    required this.text,
    required this.emoji,
    this.category = QuickMessageCategory.general,
  });

  final String id;
  final String text;
  final String emoji;
  final QuickMessageCategory category;

  static const List<QuickMessage> presets = [
    QuickMessage(id: 'gg', text: 'GG!', emoji: '🎮', category: QuickMessageCategory.general),
    QuickMessage(id: 'good_luck', text: 'Удачи!', emoji: '🍀', category: QuickMessageCategory.general),
    QuickMessage(id: 'nice', text: 'Красава!', emoji: '🔥', category: QuickMessageCategory.general),
    QuickMessage(id: 'come_on', text: 'Давай!', emoji: '💪', category: QuickMessageCategory.motivation),
    QuickMessage(id: 'almost', text: 'Почти!', emoji: '😅', category: QuickMessageCategory.motivation),
    QuickMessage(id: 'ready', text: 'Готов!', emoji: '✅', category: QuickMessageCategory.status),
    QuickMessage(id: 'waiting', text: 'Жду...', emoji: '⏳', category: QuickMessageCategory.status),
    QuickMessage(id: 'sorry', text: 'Извини', emoji: '🙏', category: QuickMessageCategory.apology),
  ];
}

enum QuickMessageCategory {
  general('Общие'),
  motivation('Поддержка'),
  status('Статус'),
  apology('Извинения');

  const QuickMessageCategory(this.label);
  final String label;
}

/// Рекомендация соперника.
class OpponentRecommendation {
  const OpponentRecommendation({
    required this.userId,
    required this.username,
    required this.level,
    required this.totalWins,
    required this.winRate,
    required this.commonHabits,
    this.matchScore = 0,
  });

  final String userId;
  final String username;
  final int level;
  final int totalWins;
  final double winRate;
  final List<String> commonHabits;
  final int matchScore;

  String get difficultyLabel {
    if (winRate < 40) return 'Лёгкий';
    if (winRate < 60) return 'Средний';
    return 'Сложный';
  }
}
