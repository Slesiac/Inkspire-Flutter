class ArtConstraint {
  final int id;
  final String artConstraint;

  ArtConstraint({required this.id, required this.artConstraint});

  factory ArtConstraint.fromMap(Map<String, dynamic> m) => ArtConstraint(
        id: (m['id'] as num).toInt(),
        artConstraint: (m['art_constraint'] ?? '').toString(),
      );
}