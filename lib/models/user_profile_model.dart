class UserProfile {
  final String displayName;
  final String? avatarPath; // local file path

  const UserProfile({
    this.displayName = 'ผู้ใช้',
    this.avatarPath,
  });

  UserProfile copyWith({String? displayName, String? avatarPath, bool clearAvatar = false}) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
    );
  }
}
