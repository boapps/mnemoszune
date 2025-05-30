class Subject {
  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;

  Subject({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });
}
