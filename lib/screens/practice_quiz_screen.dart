import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mnemoszune/models/exercise.dart';
import 'package:mnemoszune/providers/exercise_provider.dart';
import 'package:mnemoszune/providers/quiz_provider.dart';
import 'dart:math';

class PracticeQuizScreen extends ConsumerStatefulWidget {
  final int quizId;

  const PracticeQuizScreen({super.key, required this.quizId});

  @override
  ConsumerState<PracticeQuizScreen> createState() => _PracticeQuizScreenState();
}

class _PracticeQuizScreenState extends ConsumerState<PracticeQuizScreen> {
  int _currentExerciseIndex = 0;
  final List<Exercise> _exercises = [];
  bool _showAnswer = false;
  String? _selectedAnswer;
  int _correctAnswers = 0;
  bool _quizCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExercises();
    });
  }

  void _loadExercises() async {
    final exercisesAsync = ref.read(exercisesForQuizProvider(widget.quizId));

    exercisesAsync.whenData((exercises) {
      setState(() {
        _exercises.clear();
        for (final exercise in exercises) {
          _exercises.add(exercise);
        }
        // Shuffle exercises for practice
        _exercises.shuffle(Random());
      });
    });
  }

  void _nextQuestion() {
    setState(() {
      if (_currentExerciseIndex < _exercises.length - 1) {
        _currentExerciseIndex++;
        _showAnswer = false;
        _selectedAnswer = null;
      } else {
        _quizCompleted = true;
      }
    });
  }

  void _checkAnswer(String answer) {
    final currentExercise = _exercises[_currentExerciseIndex];

    setState(() {
      _selectedAnswer = answer;
      _showAnswer = true;

      if (answer.trim().toLowerCase() ==
          currentExercise.answer.trim().toLowerCase()) {
        _correctAnswers++;
      }
    });
  }

  Widget _buildQuestionAnswerExercise(Exercise exercise) {
    final textController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(exercise.question, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),

        if (!_showAnswer) ...[
          TextField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: 'Your Answer',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                _checkAnswer(value);
              }
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                _checkAnswer(textController.text);
              }
            },
            child: const Text('Check Answer'),
          ),
        ] else ...[
          Card(
            color:
                _selectedAnswer!.trim().toLowerCase() ==
                        exercise.answer.trim().toLowerCase()
                    ? Colors.green.shade100
                    : Colors.red.shade100,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your answer: $_selectedAnswer',
                    style: TextStyle(
                      color:
                          _selectedAnswer!.trim().toLowerCase() ==
                                  exercise.answer.trim().toLowerCase()
                              ? Colors.green.shade900
                              : Colors.red.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Correct answer: ${exercise.answer}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _nextQuestion,
            child: Text(
              _currentExerciseIndex < _exercises.length - 1
                  ? 'Next Question'
                  : 'Finish Quiz',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMultipleChoiceExercise(Exercise exercise) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(exercise.question, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),

        ...?exercise.options?.map(
          (option) => RadioListTile<String>(
            title: Text(option),
            value: option,
            groupValue: _selectedAnswer,
            onChanged: _showAnswer ? null : (value) => _checkAnswer(value!),
            tileColor:
                _showAnswer
                    ? option.trim().toLowerCase() ==
                            exercise.answer.trim().toLowerCase()
                        ? Colors.green.shade100
                        : _selectedAnswer == option
                        ? Colors.red.shade100
                        : null
                    : null,
          ),
        ),

        if (_showAnswer) ...[
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _nextQuestion,
            child: Text(
              _currentExerciseIndex < _exercises.length - 1
                  ? 'Next Question'
                  : 'Finish Quiz',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompletionScreen() {
    final percentage = (_correctAnswers / _exercises.length * 100).round();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Quiz Completed!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          Text(
            'Score: $_correctAnswers / ${_exercises.length}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text('$percentage%', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Return to Quiz'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizAsync = ref.watch(quizProvider(widget.quizId));

    return Scaffold(
      appBar: AppBar(
        title: quizAsync.when(
          data: (quiz) => Text('Practice: ${quiz.title}'),
          loading: () => const Text('Loading Quiz...'),
          error: (_, __) => const Text('Practice Quiz'),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            _exercises.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _quizCompleted
                ? _buildCompletionScreen()
                : SingleChildScrollView(
                  child:
                      _exercises[_currentExerciseIndex].type ==
                              ExerciseType.multipleChoice
                          ? _buildMultipleChoiceExercise(
                            _exercises[_currentExerciseIndex],
                          )
                          : _buildQuestionAnswerExercise(
                            _exercises[_currentExerciseIndex],
                          ),
                ),
      ),
    );
  }
}
