class Concept {
  final int id;
  final String concept;

  Concept({required this.id, required this.concept});

  factory Concept.fromMap(Map<String, dynamic> m) => Concept(
        id: (m['id'] as num).toInt(),
        concept: (m['concept'] ?? '').toString(),
      );
}