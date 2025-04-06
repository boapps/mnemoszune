import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mnemoszune/providers/exercise_provider.dart';
import 'package:mnemoszune/models/exercise.dart';

class AddExerciseScreen extends ConsumerStatefulWidget {
  final int quizId;

  const AddExerciseScreen({super.key, required this.quizId});

  @override
  ConsumerState<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends ConsumerState<AddExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  final _optionsControllers = <TextEditingController>[];

  ExerciseType _exerciseType = ExerciseType.questionAnswer;

  @override
  void initState() {
    super.initState();
    // Add two option controllers by default for multiple choice
    _addOptionController();
    _addOptionController();
  }

  void _addOptionController() {
    _optionsControllers.add(TextEditingController());
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    for (var controller in _optionsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Exercise'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Exercise type selection
              const Text(
                'Exercise Type:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<ExerciseType>(
                      title: const Text('Question/Answer'),
                      value: ExerciseType.questionAnswer,
                      groupValue: _exerciseType,
                      onChanged: (ExerciseType? value) {
                        setState(() {
                          _exerciseType = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<ExerciseType>(
                      title: const Text('Multiple Choice'),
                      value: ExerciseType.multipleChoice,
                      groupValue: _exerciseType,
                      onChanged: (ExerciseType? value) {
                        setState(() {
                          _exerciseType = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Question
              TextFormField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a question';
                  }
                  return null;
                },
                maxLines: 3,
              ),
              const SizedBox(height: 16.0),

              // Answer
              TextFormField(
                controller: _answerController,
                decoration: const InputDecoration(
                  labelText: 'Answer',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the answer';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Multiple choice options
              if (_exerciseType == ExerciseType.multipleChoice) ...[
                const Text(
                  'Options (the answer should be included in the options):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),

                // Options list
                ...List.generate(_optionsControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _optionsControllers[index],
                            decoration: InputDecoration(
                              labelText: 'Option ${index + 1}',
                              border: const OutlineInputBorder(),
                            ),
                            validator:
                                _exerciseType == ExerciseType.multipleChoice
                                    ? (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter an option';
                                      }
                                      return null;
                                    }
                                    : null,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed:
                              _optionsControllers.length <= 2
                                  ? null
                                  : () {
                                    setState(() {
                                      _optionsControllers.removeAt(index);
                                    });
                                  },
                        ),
                      ],
                    ),
                  );
                }),

                // Add option button
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _addOptionController();
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Option'),
                ),
              ],

              const SizedBox(height: 24.0),

              // Save button
              ElevatedButton(
                onPressed:
                    ref.watch(exerciseNotifierProvider).isLoading
                        ? null
                        : () async {
                          if (_formKey.currentState!.validate()) {
                            if (_exerciseType == ExerciseType.multipleChoice) {
                              final options =
                                  _optionsControllers
                                      .map(
                                        (controller) => controller.text.trim(),
                                      )
                                      .where((text) => text.isNotEmpty)
                                      .toList();

                              if (!options.contains(
                                _answerController.text.trim(),
                              )) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'The answer must be included in the options',
                                    ),
                                  ),
                                );
                                return;
                              }

                              await ref
                                  .read(exerciseNotifierProvider.notifier)
                                  .addMultipleChoiceExercise(
                                    widget.quizId,
                                    _questionController.text,
                                    _answerController.text,
                                    options,
                                  );
                            } else {
                              await ref
                                  .read(exerciseNotifierProvider.notifier)
                                  .addQuestionAnswerExercise(
                                    widget.quizId,
                                    _questionController.text,
                                    _answerController.text,
                                  );
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          }
                        },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child:
                    ref.watch(exerciseNotifierProvider).isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Save Exercise'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
