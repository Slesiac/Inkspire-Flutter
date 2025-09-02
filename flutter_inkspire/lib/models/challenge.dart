class Challenge {
  final int id;
  final String userProfileId;
  final String title;
  final String concept;
  final String artConstraint;
  final String? description;
  final String? resultPic;
  final DateTime? insertedAt;
  final DateTime? updatedAt;

  // Costruttore che distingue tra campi obbligatori e facoltativi
  Challenge({
    required this.id,
    required this.userProfileId,
    required this.title,
    required this.concept,
    required this.artConstraint,
    this.description,
    this.resultPic,
    this.insertedAt,
    this.updatedAt,
  });

  factory Challenge.fromMap(Map<String, dynamic> m) {
    String _s(dynamic v) => v?.toString() ?? '';
    String? _sn(dynamic v) => v?.toString();
    final ins = m['inserted_at'];
    final upd = m['updated_at'];
    return Challenge(
      id: (m['id'] as num).toInt(),
      userProfileId: _s(m['user_profile_id']),
      title: _s(m['title']),
      concept: _s(m['concept']),
      artConstraint: _s(m['art_constraint']),
      description: _sn(m['description']),
      resultPic: _sn(m['result_pic']),
      insertedAt: ins == null ? null : DateTime.tryParse(ins.toString()),
      updatedAt: upd == null ? null : DateTime.tryParse(upd.toString()),
    );
  }

  Map<String, dynamic> toInsert() => {
        'user_profile_id': userProfileId,
        'title': title,
        'concept': concept,
        'art_constraint': artConstraint,
        if (description != null) 'description': description,
        if (resultPic != null) 'result_pic': resultPic,
      };

  Map<String, dynamic> toUpdate() => {
        'title': title,
        'concept': concept,
        'art_constraint': artConstraint,
        'description': description,
        'result_pic': resultPic,
      };
}