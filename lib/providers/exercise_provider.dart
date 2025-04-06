import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:riverpod/riverpod.dart';
import 'package:mnemoszune/database/database.dart';
import 'package:mnemoszune/providers/database_provider.dart';
import 'package:mnemoszune/models/exercise.dart' as model;

final exercisesForQuizProvider =
    StreamProvider.family<List<model.Exercise>, int>((ref, quizId) {
      final database = ref.watch(databaseProvider);
      return database.watchExercisesForQuiz(quizId);
    });

class ExerciseNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase database;

  ExerciseNotifier(this.database) : super(const AsyncValue.data(null));

  Future<void> addQuestionAnswerExercise(
    int quizId,
    String question,
    String answer,
  ) async {
    state = const AsyncValue.loading();
    try {
      await database.insertExercise(
        ExercisesCompanion(
          quizId: Value(quizId),
          question: Value(question),
          answer: Value(answer),
          type: const Value('questionAnswer'),
        ),
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addMultipleChoiceExercise(
    int quizId,
    String question,
    String answer,
    List<String> options,
  ) async {
    state = const AsyncValue.loading();
    try {
      await database.insertExercise(
        ExercisesCompanion(
          quizId: Value(quizId),
          question: Value(question),
          answer: Value(answer),
          type: const Value('multipleChoice'),
          options: Value(jsonEncode(options)),
        ),
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateExercise(
    int id,
    String question,
    String answer,
    model.ExerciseType type,
    List<String>? options,
  ) async {
    state = const AsyncValue.loading();
    try {
      await database.updateExercise(
        ExercisesCompanion(
          id: Value(id),
          question: Value(question),
          answer: Value(answer),
          type: Value(
            type == model.ExerciseType.multipleChoice
                ? 'multipleChoice'
                : 'questionAnswer',
          ),
          options:
              options != null ? Value(jsonEncode(options)) : const Value(null),
        ),
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteExercise(int id) async {
    state = const AsyncValue.loading();
    try {
      await database.deleteExercise(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final exerciseNotifierProvider =
    StateNotifierProvider<ExerciseNotifier, AsyncValue<void>>((ref) {
      final database = ref.watch(databaseProvider);
      return ExerciseNotifier(database);
    });
