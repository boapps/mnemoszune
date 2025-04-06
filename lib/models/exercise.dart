enum ExerciseType { questionAnswer, multipleChoice }

class Exercise {
  final int id;
  final int quizId;
  final String question;
  final String answer;
  final ExerciseType type;
  final List<String>? options;

  Exercise({
    required this.id,
    required this.quizId,
    required this.question,
    required this.answer,
    required this.type,
    this.options,
  });
}
