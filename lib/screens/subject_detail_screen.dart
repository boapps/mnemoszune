import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mnemoszune/providers/subject_provider.dart';
import 'package:mnemoszune/providers/quiz_provider.dart';
import 'package:mnemoszune/providers/material_provider.dart';
import 'package:mnemoszune/screens/add_quiz_screen.dart';
import 'package:mnemoszune/screens/quiz_detail_screen.dart';
import 'package:mnemoszune/screens/add_material_screen.dart';

class SubjectDetailScreen extends ConsumerStatefulWidget {
  final int subjectId;

  const SubjectDetailScreen({super.key, required this.subjectId});

  @override
  ConsumerState<SubjectDetailScreen> createState() =>
      _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends ConsumerState<SubjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjectAsync = ref.watch(subjectProvider(widget.subjectId));
    final quizzesAsync = ref.watch(quizzesForSubjectProvider(widget.subjectId));
    final materialsAsync = ref.watch(
      materialsForSubjectProvider(widget.subjectId),
    );

    return Scaffold(
      appBar: AppBar(
        title: subjectAsync.when(
          data: (subject) => Text(subject.name),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Subject'),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(
            context,
          ).colorScheme.onPrimary.withOpacity(0.6),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.quiz), text: 'Quizzes'),
            Tab(icon: Icon(Icons.book), text: 'Materials'),
          ],
        ),
      ),
      body: subjectAsync.when(
        data: (subject) {
          return TabBarView(
            controller: _tabController,
            children: [
              // Quizzes tab
              quizzesAsync.when(
                data: (quizzes) {
                  if (quizzes.isEmpty) {
                    return const Center(
                      child: Text('No quizzes yet. Add your first quiz!'),
                    );
                  }

                  return ListView.builder(
                    itemCount: quizzes.length,
                    itemBuilder: (context, index) {
                      final quiz = quizzes[index];
                      return ListTile(
                        title: Text(quiz.title),
                        subtitle:
                            quiz.description != null
                                ? Text(quiz.description!)
                                : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      QuizDetailScreen(quizId: quiz.id),
                            ),
                          );
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('Delete Quiz'),
                                    content: const Text(
                                      'Are you sure you want to delete this quiz?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('CANCEL'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          ref
                                              .read(
                                                quizNotifierProvider.notifier,
                                              )
                                              .deleteQuiz(quiz.id);
                                          Navigator.pop(context);
                                        },
                                        child: const Text('DELETE'),
                                      ),
                                    ],
                                  ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, _) =>
                        Center(child: Text('Error loading quizzes: $error')),
              ),

              // Materials tab
              materialsAsync.when(
                data: (materials) {
                  if (materials.isEmpty) {
                    return const Center(
                      child: Text('No materials yet. Add your first material!'),
                    );
                  }

                  return ListView.builder(
                    itemCount: materials.length,
                    itemBuilder: (context, index) {
                      final material = materials[index];
                      return ListTile(
                        title: Text(material.title),
                        subtitle:
                            material.description != null
                                ? Text(material.description!)
                                : null,
                        leading: const Icon(Icons.insert_drive_file),
                        onTap: () {
                          // Show file or open file
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Opening ${material.title}'),
                            ),
                          );
                          // Add file opening logic here
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('Delete Material'),
                                    content: const Text(
                                      'Are you sure you want to delete this material?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('CANCEL'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          ref
                                              .read(
                                                materialNotifierProvider
                                                    .notifier,
                                              )
                                              .deleteMaterial(material.id);
                                          Navigator.pop(context);
                                        },
                                        child: const Text('DELETE'),
                                      ),
                                    ],
                                  ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, _) =>
                        Center(child: Text('Error loading materials: $error')),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, _) => Center(child: Text('Error loading subject: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final currentIndex = _tabController.index;
          if (currentIndex == 0) {
            // Quizzes tab
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => AddQuizScreen(subjectId: widget.subjectId),
              ),
            );
          } else {
            // Materials tab
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => AddMaterialScreen(subjectId: widget.subjectId),
              ),
            );
          }
        },
        tooltip: 'Add',
        child: const Icon(Icons.add),
      ),
    );
  }
}
