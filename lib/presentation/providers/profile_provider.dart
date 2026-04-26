import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/profile.dart';
import 'core_providers.dart';

sealed class ProfileState {
  const ProfileState();
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  const ProfileLoaded(this.profile);
  final UserProfile profile;
}

class ProfileError extends ProfileState {
  const ProfileError(this.message);
  final String message;
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._ref) : super(const ProfileInitial());

  final Ref _ref;

  static const _bioKey = 'profile_bio';
  static const _favoriteHabitKey = 'profile_favorite_habit';
  static const _avatarEmojiKey = 'profile_avatar_emoji';
  static const _avatarUrlKey = 'profile_avatar_url';
  static const _localAvatarBase64Key = 'profile_local_avatar_base64';

  Future<void> load() async {
    state = const ProfileLoading();
    try {
      final remoteProfile = await _ref.read(profileRemoteDSProvider).getMyProfile();
      state = ProfileLoaded(await _mergeWithLocalOverrides(remoteProfile));
    } on Failure catch (e) {
      if (e is NetworkFailure) {
        final storage = _ref.read(secureStorageProvider);
        final userId = await storage.read(key: kUserIdKey) ?? 'guest';
        final username = await storage.read(key: kUsernameKey) ?? 'Guest';
        final fallback = UserProfile(
          id: userId,
          username: username,
          wins: 0,
          losses: 0,
        );
        state = ProfileLoaded(await _mergeWithLocalOverrides(fallback));
        return;
      }
      state = ProfileError(e.message);
    } catch (e) {
      state = ProfileError(e.toString());
    }
  }

  Future<void> saveEdits({
    required String username,
    required String bio,
    required String favoriteHabit,
    required String avatarEmoji,
    required String avatarUrl,
    String? localAvatarBase64,
  }) async {
    final current = state;
    if (current is! ProfileLoaded) return;

    final storage = _ref.read(secureStorageProvider);
    final updatedProfile = current.profile.copyWith(
      username: username.trim().isEmpty ? current.profile.username : username.trim(),
      bio: bio.trim().isEmpty ? null : bio.trim(),
      favoriteHabit: favoriteHabit.trim().isEmpty ? null : favoriteHabit.trim(),
      avatarEmoji:
          avatarEmoji.trim().isEmpty ? current.profile.avatarEmoji : avatarEmoji.trim(),
      avatarUrl: avatarUrl.trim().isEmpty ? null : avatarUrl.trim(),
      localAvatarBase64: localAvatarBase64 ?? current.profile.localAvatarBase64,
    );

    await storage.write(key: kUsernameKey, value: updatedProfile.username);
    await storage.write(key: _bioKey, value: updatedProfile.bio ?? '');
    await storage.write(
      key: _favoriteHabitKey,
      value: updatedProfile.favoriteHabit ?? '',
    );
    await storage.write(key: _avatarEmojiKey, value: updatedProfile.avatarEmoji);
    await storage.write(key: _avatarUrlKey, value: updatedProfile.avatarUrl ?? '');
    await storage.write(
      key: _localAvatarBase64Key,
      value: updatedProfile.localAvatarBase64 ?? '',
    );

    state = ProfileLoaded(updatedProfile);

    try {
      await _ref.read(firestoreStoreProvider).upsertProfile(
            updatedProfile.copyWith(localAvatarBase64: null),
          );
    } catch (_) {
      // Local edits remain available even if mirror sync is unavailable.
    }
  }

  Future<UserProfile> _mergeWithLocalOverrides(UserProfile profile) async {
    final storage = _ref.read(secureStorageProvider);
    return profile.copyWith(
      username: await storage.read(key: kUsernameKey) ?? profile.username,
      bio: _readOptionalOverride(await storage.read(key: _bioKey)) ?? profile.bio,
      favoriteHabit:
          _readOptionalOverride(await storage.read(key: _favoriteHabitKey)) ??
              profile.favoriteHabit,
      avatarEmoji: await storage.read(key: _avatarEmojiKey) ?? profile.avatarEmoji,
      avatarUrl:
          _readOptionalOverride(await storage.read(key: _avatarUrlKey)) ??
              profile.avatarUrl,
      localAvatarBase64:
          _readOptionalOverride(await storage.read(key: _localAvatarBase64Key)) ??
              profile.localAvatarBase64,
    );
  }

  String? _readOptionalOverride(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref);
});
