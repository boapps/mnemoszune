import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mnemoszune/providers/subject_provider.dart';
import 'package:mnemoszune/screens/subject_detail_screen.dart';
import 'package:mnemoszune/screens/add_subject_screen.dart';
import 'package:mnemoszune/screens/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mnemoszune'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: subjectsAsync.when(
        data: (subjects) {
          if (subjects.isEmpty) {
            return const Center(
              child: Text('No subjects yet. Add your first subject!'),
            );
          }

          return ListView.builder(
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return ListTile(
                title: Text(subject.name),
                subtitle:
                    subject.description != null
                        ? Text(subject.description!)
                        : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              SubjectDetailScreen(subjectId: subject.id),
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
                            title: const Text('Delete Subject'),
                            content: const Text(
                              'Are you sure you want to delete this subject? All associated quizzes and materials will also be deleted.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('CANCEL'),
                              ),
                              TextButton(
                                onPressed: () {
                                  ref
                                      .read(subjectNotifierProvider.notifier)
                                      .deleteSubject(subject.id);
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
            (error, stack) =>
                Center(child: Text('Error loading subjects: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddSubjectScreen()),
          );
        },
        tooltip: 'Add Subject',
        child: const Icon(Icons.add),
      ),
    );
  }
}
