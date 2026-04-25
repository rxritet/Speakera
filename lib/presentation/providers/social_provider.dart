import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/firebase/habitduel_firestore_store.dart';
import '../../domain/entities/social.dart';
import 'core_providers.dart';

// ─── State ─────────────────────────────────────────────────────────────────

sealed class FriendsState {
  const FriendsState();
}

class FriendsLoading extends FriendsState {
  const FriendsLoading();
}

class FriendsLoaded extends FriendsState {
  const FriendsLoaded({
    required this.friends,
    required this.requests,
    required this.recommendations,
  });
  final List<Friend> friends;
  final List<FriendRequest> requests;
  final List<OpponentRecommendation> recommendations;
}

class FriendsError extends FriendsState {
  const FriendsError(this.message);
  final String message;
}

// ─── Notifier ──────────────────────────────────────────────────────────────

class SocialNotifier extends StateNotifier<FriendsState> {
  SocialNotifier(this._store, this._storage) : super(const FriendsLoading());

  final HabitDuelFirestoreStore _store;
  final FlutterSecureStorage _storage;

  Future<void> load() async {
    state = const FriendsLoading();
    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId == null || userId.isEmpty) {
        state = const FriendsLoaded(friends: [], requests: [], recommendations: []);
        return;
      }

      final friends = await _store.readFriends(userId);
      final requests = await _store.readFriendRequests(userId);
      final recommendations = await _store.readOpponentRecommendations(userId);

      state = FriendsLoaded(
        friends: friends ?? [],
        requests: requests ?? [],
        recommendations: recommendations ?? [],
      );
    } catch (e) {
      state = FriendsError(e.toString());
    }
  }

  Future<void> sendFriendRequest(String targetUserId) async {
    try {
      await _store.sendFriendRequest(
        fromUserId: await _storage.read(key: 'user_id') ?? '',
        toUserId: targetUserId,
      );
      await load();
    } catch (e) {
      state = FriendsError(e.toString());
    }
  }

  Future<void> acceptFriendRequest(String requestId, String fromUserId) async {
    try {
      await _store.acceptFriendRequest(requestId: requestId);
      await load();
    } catch (e) {
      state = FriendsError(e.toString());
    }
  }

  Future<void> declineFriendRequest(String requestId) async {
    try {
      await _store.declineFriendRequest(requestId: requestId);
      await load();
    } catch (e) {
      state = FriendsError(e.toString());
    }
  }

  Future<void> removeFriend(String friendId) async {
    try {
      await _store.removeFriend(friendId: friendId);
      await load();
    } catch (e) {
      state = FriendsError(e.toString());
    }
  }
}

final socialProvider = StateNotifierProvider<SocialNotifier, FriendsState>((ref) {
  return SocialNotifier(
    ref.watch(firestoreStoreProvider),
    ref.watch(secureStorageProvider),
  );
});

// ─── Chat State ────────────────────────────────────────────────────────────

sealed class ChatState {
  const ChatState();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatLoaded extends ChatState {
  const ChatLoaded({required this.messages, required this.duelId});
  final List<DuelMessage> messages;
  final String duelId;
}

class ChatError extends ChatState {
  const ChatError(this.message);
  final String message;
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._store) : super(const ChatLoading());
  final HabitDuelFirestoreStore _store;

  Future<void> loadChat(String duelId) async {
    state = const ChatLoading();
    try {
      final messages = await _store.readDuelMessages(duelId);
      state = ChatLoaded(messages: messages ?? [], duelId: duelId);
    } catch (e) {
      state = ChatError(e.toString());
    }
  }

  Future<void> sendMessage(String duelId, String text, String senderId, String senderName) async {
    try {
      await _store.sendDuelMessage(
        duelId: duelId,
        senderId: senderId,
        senderName: senderName,
        text: text,
      );
      await loadChat(duelId);
    } catch (e) {
      state = ChatError(e.toString());
    }
  }

  Future<void> sendEmoji(String duelId, String emoji, String senderId, String senderName) async {
    try {
      await _store.sendDuelMessage(
        duelId: duelId,
        senderId: senderId,
        senderName: senderName,
        emoji: emoji,
      );
      await loadChat(duelId);
    } catch (e) {
      state = ChatError(e.toString());
    }
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref.watch(firestoreStoreProvider));
});
