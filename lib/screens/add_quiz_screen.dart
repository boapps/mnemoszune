import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mnemoszune/providers/quiz_provider.dart';

class AddQuizScreen extends ConsumerStatefulWidget {
  final int subjectId;

  const AddQuizScreen({super.key, required this.subjectId});

  @override
  ConsumerState<AddQuizScreen> createState() => _AddQuizScreenState();
}

class _AddQuizScreenState extends ConsumerState<AddQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Quiz'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Quiz Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a quiz title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await ref
                        .read(quizNotifierProvider.notifier)
                        .addQuiz(
                          _titleController.text,
                          _descriptionController.text.isEmpty
                              ? null
                              : _descriptionController.text,
                          widget.subjectId,
                        );
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child:
                    ref.watch(quizNotifierProvider).isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Save Quiz'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
