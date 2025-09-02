class UserProfileVW {
  final String id;
  final String username;
  final String? profilePic;
  final int createdCount;
  final int completedCount;

  UserProfileVW({
    required this.id,
    required this.username,
    this.profilePic,
    required this.createdCount,
    required this.completedCount,
  });

  factory UserProfileVW.fromMap(Map<String, dynamic> m) => UserProfileVW(
        id: m['id'].toString(),
        username: (m['username'] ?? '').toString(),
        profilePic: m['profile_pic']?.toString(),
        createdCount: (m['created_count'] as num).toInt(),
        completedCount: (m['completed_count'] as num).toInt(),
      );
}