class StudyMaterial {
  final int id;
  final String title;
  final String? description;
  final int subjectId;
  final String filePath;
  final DateTime createdAt;
  final bool isVectorized;

  StudyMaterial({
    required this.id,
    required this.title,
    this.description,
    required this.subjectId,
    required this.filePath,
    required this.createdAt,
    this.isVectorized = false,
  });
}
