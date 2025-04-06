import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mnemoszune/providers/quiz_provider.dart';
import 'package:mnemoszune/providers/exercise_provider.dart';
import 'package:mnemoszune/screens/add_exercise_screen.dart';
import 'package:mnemoszune/screens/practice_quiz_screen.dart';
import 'package:mnemoszune/models/exercise.dart';

class QuizDetailScreen extends ConsumerWidget {
  final int quizId;

  const QuizDetailScreen({super.key, required this.quizId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizAsync = ref.watch(quizProvider(quizId));
    final exercisesAsync = ref.watch(exercisesForQuizProvider(quizId));

    return Scaffold(
      appBar: AppBar(
        title: quizAsync.when(
          data: (quiz) => Text(quiz.title),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Quiz'),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          exercisesAsync.maybeWhen(
            data:
                (exercises) =>
                    exercises.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.play_arrow),
                          tooltip: 'Practice Quiz',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        PracticeQuizScreen(quizId: quizId),
                              ),
                            );
                          },
                        )
                        : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: quizAsync.when(
              data:
                  (quiz) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (quiz.description != null) ...[
                        Text(
                          'Description:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(quiz.description!),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        'Exercises:',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
              loading: () => const CircularProgressIndicator(),
              error: (error, _) => Text('Error loading quiz: $error'),
            ),
          ),
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                if (exercises.isEmpty) {
                  return const Center(
                    child: Text('No exercises yet. Add your first exercise!'),
                  );
                }

                return ListView.builder(
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      child: Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    exercise.type == ExerciseType.multipleChoice
                                        ? Icons.checklist
                                        : Icons.question_answer,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      exercise.question,
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      ref
                                          .read(
                                            exerciseNotifierProvider.notifier,
                                          )
                                          .deleteExercise(exercise.id);
                                    },
                                  ),
                                ],
                              ),
                              const Divider(),
                              Text(
                                'Answer: ${exercise.answer}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (exercise.type ==
                                      ExerciseType.multipleChoice &&
                                  exercise.options != null) ...[
                                const SizedBox(height: 8),
                                const Text('Options:'),
                                ...exercise.options!
                                    .map(
                                      (option) => Padding(
                                        padding: const EdgeInsets.only(
                                          left: 16.0,
                                          top: 4.0,
                                        ),
                                        child: Text('• $option'),
                                      ),
                                    )
                                    .toList(),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, _) =>
                      Center(child: Text('Error loading exercises: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddExerciseScreen(quizId: quizId),
            ),
          );
        },
        tooltip: 'Add Exercise',
        child: const Icon(Icons.add),
      ),
    );
  }
}
