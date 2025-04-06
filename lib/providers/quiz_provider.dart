import 'package:drift/drift.dart';
import 'package:riverpod/riverpod.dart';
import 'package:mnemoszune/database/database.dart';
import 'package:mnemoszune/providers/database_provider.dart';
import 'package:mnemoszune/models/quiz.dart' as model;

final quizzesForSubjectProvider = StreamProvider.family<List<model.Quiz>, int>((
  ref,
  subjectId,
) {
  final database = ref.watch(databaseProvider);
  final query = database.select(database.quizzes);
  query.where((tbl) => tbl.subjectId.equals(subjectId));

  return query.watch().map(
    (rows) =>
        rows
            .map(
              (row) => model.Quiz(
                id: row.id,
                title: row.title,
                description: row.description,
                subjectId: row.subjectId,
                createdAt: row.createdAt,
              ),
            )
            .toList(),
  );
});

final quizProvider = StreamProvider.family<model.Quiz, int>((ref, id) async* {
  final database = ref.watch(databaseProvider);
  yield await database.getQuizById(id);
});

class QuizNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase database;

  QuizNotifier(this.database) : super(const AsyncValue.data(null));

  Future<void> addQuiz(String title, String? description, int subjectId) async {
    state = const AsyncValue.loading();
    try {
      await database.insertQuiz(
        QuizzesCompanion(
          title: Value(title),
          description: Value(description),
          subjectId: Value(subjectId),
          createdAt: Value(DateTime.now()),
        ),
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateQuiz(int id, String title, String? description) async {
    state = const AsyncValue.loading();
    try {
      await database.updateQuiz(
        QuizzesCompanion(
          id: Value(id),
          title: Value(title),
          description: Value(description),
        ),
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteQuiz(int id) async {
    state = const AsyncValue.loading();
    try {
      await database.deleteQuiz(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final quizNotifierProvider =
    StateNotifierProvider<QuizNotifier, AsyncValue<void>>((ref) {
      final database = ref.watch(databaseProvider);
      return QuizNotifier(database);
    });
