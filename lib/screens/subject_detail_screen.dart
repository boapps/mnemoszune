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
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchMaterials(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await ref
          .read(materialNotifierProvider.notifier)
          .searchMaterialsByContent(query);

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Search error: $e')));
    }
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
          return Column(
            children: [
              _tabController.index == 1
                  ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search in materials...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon:
                            _searchController.text.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchResults = [];
                                    });
                                  },
                                )
                                : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onSubmitted: (value) {
                        _searchMaterials(value);
                      },
                    ),
                  )
                  : const SizedBox.shrink(),
              _isSearching
                  ? const LinearProgressIndicator()
                  : const SizedBox(height: 4),
              Expanded(
                child:
                    _tabController.index == 1 && _searchResults.isNotEmpty
                        ? ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final material = _searchResults[index];
                            return ListTile(
                              title: Text(material.title),
                              subtitle:
                                  material.description != null
                                      ? Text(material.description!)
                                      : null,
                              leading: const Icon(Icons.insert_drive_file),
                              trailing:
                                  material.isVectorized
                                      ? const Icon(
                                        Icons.search,
                                        color: Colors.green,
                                      )
                                      : null,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Opening ${material.title}'),
                                  ),
                                );
                              },
                            );
                          },
                        )
                        : TabBarView(
                          controller: _tabController,
                          children: [
                            quizzesAsync.when(
                              data: (quizzes) {
                                if (quizzes.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'No quizzes yet. Add your first quiz!',
                                    ),
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
                                                (context) => QuizDetailScreen(
                                                  quizId: quiz.id,
                                                ),
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
                                                  title: const Text(
                                                    'Delete Quiz',
                                                  ),
                                                  content: const Text(
                                                    'Are you sure you want to delete this quiz?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            context,
                                                          ),
                                                      child: const Text(
                                                        'CANCEL',
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        ref
                                                            .read(
                                                              quizNotifierProvider
                                                                  .notifier,
                                                            )
                                                            .deleteQuiz(
                                                              quiz.id,
                                                            );
                                                        Navigator.pop(context);
                                                      },
                                                      child: const Text(
                                                        'DELETE',
                                                      ),
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
                              loading:
                                  () => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                              error:
                                  (error, _) => Center(
                                    child: Text(
                                      'Error loading quizzes: $error',
                                    ),
                                  ),
                            ),
                            materialsAsync.when(
                              data: (materials) {
                                if (materials.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'No materials yet. Add your first material!',
                                    ),
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
                                      leading: const Icon(
                                        Icons.insert_drive_file,
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (material.isVectorized)
                                            const Padding(
                                              padding: EdgeInsets.only(
                                                right: 8.0,
                                              ),
                                              child: Tooltip(
                                                message: 'Searchable',
                                                child: Icon(
                                                  Icons.manage_search,
                                                  color: Colors.green,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (context) => AlertDialog(
                                                      title: const Text(
                                                        'Delete Material',
                                                      ),
                                                      content: const Text(
                                                        'Are you sure you want to delete this material?',
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed:
                                                              () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                  ),
                                                          child: const Text(
                                                            'CANCEL',
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            ref
                                                                .read(
                                                                  materialNotifierProvider
                                                                      .notifier,
                                                                )
                                                                .deleteMaterial(
                                                                  material.id,
                                                                );
                                                            Navigator.pop(
                                                              context,
                                                            );
                                                          },
                                                          child: const Text(
                                                            'DELETE',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Opening ${material.title}',
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                              loading:
                                  () => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                              error:
                                  (error, _) => Center(
                                    child: Text(
                                      'Error loading materials: $error',
                                    ),
                                  ),
                            ),
                          ],
                        ),
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => AddQuizScreen(subjectId: widget.subjectId),
              ),
            );
          } else {
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
