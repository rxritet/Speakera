const _profileUnset = Object();

class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    this.email,
    required this.wins,
    required this.losses,
    this.badges = const [],
    this.bio,
    this.favoriteHabit,
    this.avatarEmoji = '🔥',
    this.avatarUrl,
    this.localAvatarBase64,
  });

  final String id;
  final String username;
  final String? email;
  final int wins;
  final int losses;
  final List<ProfileBadge> badges;
  final String? bio;
  final String? favoriteHabit;
  final String avatarEmoji;
  final String? avatarUrl;
  final String? localAvatarBase64;

  UserProfile copyWith({
    String? id,
    String? username,
    String? email,
    int? wins,
    int? losses,
    List<ProfileBadge>? badges,
    Object? bio = _profileUnset,
    Object? favoriteHabit = _profileUnset,
    String? avatarEmoji,
    Object? avatarUrl = _profileUnset,
    Object? localAvatarBase64 = _profileUnset,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      badges: badges ?? this.badges,
      bio: identical(bio, _profileUnset) ? this.bio : bio as String?,
      favoriteHabit: identical(favoriteHabit, _profileUnset)
          ? this.favoriteHabit
          : favoriteHabit as String?,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      avatarUrl:
          identical(avatarUrl, _profileUnset) ? this.avatarUrl : avatarUrl as String?,
      localAvatarBase64: identical(localAvatarBase64, _profileUnset)
          ? this.localAvatarBase64
          : localAvatarBase64 as String?,
    );
  }
}

class ProfileBadge {
  const ProfileBadge({required this.badgeType, required this.earnedAt});

  final String badgeType;
  final DateTime earnedAt;
}
