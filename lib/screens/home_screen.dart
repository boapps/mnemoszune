import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mnemoszune/providers/subject_provider.dart';
import 'package:mnemoszune/screens/subject_detail_screen.dart';
import 'package:mnemoszune/screens/add_subject_screen.dart';
import 'package:mnemoszune/screens/settings_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: "Import moodle",
            onPressed: () {
              _showMoodleUrlDialog(context);
            },
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

  void _showMoodleUrlDialog(BuildContext context) {
    final TextEditingController urlController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Moodle URL'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: urlController,
              decoration: const InputDecoration(
                hintText: 'https://edu.vik.bme.hu/',
                labelText: 'Moodle URL',
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a URL';
                }

                // Simple URL validation
                final Uri? uri = Uri.tryParse(value);
                if (uri == null ||
                    !uri.isAbsolute ||
                    (!uri.scheme.startsWith('http'))) {
                  return 'Please enter a valid URL starting with http:// or https://';
                }
                return null;
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(context);

                  final url = urlController.text.trim();
                  try {
                    final uri = Uri.parse(url);
                    final loginUrl = uri.replace(
                      path: '/admin/tool/mobile/launch.php',
                      query:
                          'service=moodle_mobile_app&passport=12345&urlscheme=mnemoszune',
                    );
                    if (!await launchUrl(
                      loginUrl,
                      mode: LaunchMode.externalApplication,
                    )) {
                      _showErrorDialog(context, 'Could not launch $url');
                    }
                  } catch (e) {
                    _showErrorDialog(context, 'Error launching URL: $e');
                  }
                }
              },
              child: const Text('OPEN'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
