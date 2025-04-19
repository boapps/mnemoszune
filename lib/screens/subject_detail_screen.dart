import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mnemoszune/providers/subject_provider.dart';
import 'package:mnemoszune/providers/quiz_provider.dart';
import 'package:mnemoszune/providers/material_provider.dart';
import 'package:mnemoszune/screens/add_quiz_screen.dart';
import 'package:mnemoszune/screens/quiz_detail_screen.dart';
import 'package:mnemoszune/screens/add_material_screen.dart';
import 'package:mnemoszune/services/llm_service.dart';
import 'package:mnemoszune/services/vector_service.dart';
import 'package:langchain/langchain.dart';

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
  final TextEditingController _questionController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  bool _isAskingQuestion = false;
  String? _questionAnswer;
  String? _questionContext;
  bool _showFabMenu = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _questionController.dispose();
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

  Future<void> _askQuestion(String question) async {
    if (question.trim().isEmpty) {
      return;
    }

    setState(() {
      _isAskingQuestion = true;
      _questionAnswer = null;
    });

    try {
      // Handle the async value properly
      final vectorServiceAsync = ref.read(vectorServiceProvider);
      if (!vectorServiceAsync.hasValue) {
        throw Exception("Vector service is not ready yet");
      }

      final vectorService = vectorServiceAsync.value!;
      final results = await vectorService.similaritySearch(question, k: 3);

      if (results.isNotEmpty) {
        final context = results.map((doc) => doc.pageContent).join('\n\n');

        setState(() {
          _questionContext = context;
          //   _questionAnswer = context;
          //   _isAskingQuestion = false;
        });

        final llmService = ref.read(llmServiceProvider);
        final llm = llmService.getLLM();
        final prompt = PromptTemplate(
          template:
              'Based on the following context, answer the question:\n\n'
              '$context\n\nQuestion: $question\nAnswer:',
          inputVariables: {'context', 'question'},
        );
        final chain = LLMChain(llm: llm, prompt: prompt);
        final answer = await chain.call({
          'context': context,
          'question': question,
        });
        print("answer");
        print(answer['output']);
        print(answer['output']['content']);
        setState(() {
          _questionAnswer = answer['output']['content'];
          _isAskingQuestion = false;
        });
      } else {
        setState(() {
          _questionAnswer =
              "I couldn't find any relevant information for your question.";
          _isAskingQuestion = false;
        });
      }
    } catch (e) {
      setState(() {
        _questionAnswer = "Error finding answer: $e";
        _isAskingQuestion = false;
      });
    }
  }

  void _showQuestionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Ask a Question'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _questionController,
                        decoration: const InputDecoration(
                          hintText: 'What would you like to know?',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      if (_isAskingQuestion)
                        const Center(child: CircularProgressIndicator())
                      else if (_questionAnswer != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Answer:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(_questionAnswer!),
                            ),
                          ],
                        ),
                      if (_questionContext != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Context:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(_questionContext!),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CLOSE'),
                  ),
                  TextButton(
                    onPressed:
                        _isAskingQuestion
                            ? null
                            : () {
                              final question = _questionController.text;
                              setDialogState(() {
                                _isAskingQuestion = true;
                              });
                              _askQuestion(question).then((_) {
                                setDialogState(() {});
                              });
                            },
                    child: const Text('ASK'),
                  ),
                ],
              );
            },
          ),
    );
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showFabMenu) ...[
            FloatingActionButton.small(
              heroTag: 'ask',
              onPressed: () {
                setState(() {
                  _showFabMenu = false;
                  _questionController.clear();
                  _questionAnswer = null;
                });
                _showQuestionDialog();
              },
              tooltip: 'Ask a question',
              child: const Icon(Icons.question_answer),
            ),
            const SizedBox(height: 8),
            FloatingActionButton.small(
              heroTag: 'add',
              onPressed: () {
                setState(() {
                  _showFabMenu = false;
                });
                final currentIndex = _tabController.index;
                if (currentIndex == 0) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              AddQuizScreen(subjectId: widget.subjectId),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              AddMaterialScreen(subjectId: widget.subjectId),
                    ),
                  );
                }
              },
              tooltip: 'Add',
              child: const Icon(Icons.add),
            ),
            const SizedBox(height: 8),
          ],
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _showFabMenu = !_showFabMenu;
              });
            },
            tooltip: _showFabMenu ? 'Close' : 'Menu',
            child: Icon(_showFabMenu ? Icons.close : Icons.menu),
          ),
        ],
      ),
    );
  }
}
