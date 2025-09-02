class ChallengeVW {
  final int id;
  final String userId; // auth.users.id
  final String title;
  final String concept;
  final String artConstraint;
  final String? description;
  final String? resultPic;
  final DateTime? insertedAt;
  final DateTime? updatedAt;
  // join user
  final String username;
  final String? profilePic;
  final String? bio;

  // Costruttore
  ChallengeVW({
    required this.id,
    required this.userId,
    required this.title,
    required this.concept,
    required this.artConstraint,
    this.description,
    this.resultPic,
    this.insertedAt,
    this.updatedAt,
    required this.username,
    this.profilePic,
    this.bio,
  });

  factory ChallengeVW.fromMap(Map<String, dynamic> m) {
    DateTime? _dt(v) => v == null ? null : DateTime.tryParse(v.toString());
    String _s(v) => v?.toString() ?? '';
    String? _sn(v) => v?.toString();
    return ChallengeVW(
      id: (m['id'] as num).toInt(),
      userId: _s(m['user_id']),
      title: _s(m['title']),
      concept: _s(m['concept']),
      artConstraint: _s(m['art_constraint']),
      description: _sn(m['description']),
      resultPic: _sn(m['result_pic']),
      insertedAt: _dt(m['inserted_at']),
      updatedAt: _dt(m['updated_at']),
      username: _s(m['username']),
      profilePic: _sn(m['profile_pic']),
      bio: _sn(m['bio']),
    );
  }
}