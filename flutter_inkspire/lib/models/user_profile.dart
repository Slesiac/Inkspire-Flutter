class UserProfile {
  final String id; // auth.users.id
  final String username;
  final String? profilePic;
  final String? bio;

  UserProfile({
    required this.id,
    required this.username,
    this.profilePic,
    this.bio,
  });

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
        id: m['id'].toString(),
        username: (m['username'] ?? '').toString(),
        profilePic: m['profile_pic']?.toString(),
        bio: m['bio']?.toString(),
      );
}