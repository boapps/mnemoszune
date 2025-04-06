class Quiz {
  final int id;
  final String title;
  final String? description;
  final int subjectId;
  final DateTime createdAt;

  Quiz({
    required this.id,
    required this.title,
    this.description,
    required this.subjectId,
    required this.createdAt,
  });
}
