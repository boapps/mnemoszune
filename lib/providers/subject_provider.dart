import 'package:drift/drift.dart';
import 'package:riverpod/riverpod.dart';
import 'package:mnemoszune/database/database.dart';
import 'package:mnemoszune/providers/database_provider.dart';
import 'package:mnemoszune/models/subject.dart' as model;

final subjectsProvider = StreamProvider<List<model.Subject>>((ref) {
  final database = ref.watch(databaseProvider);
  return database
      .select(database.subjects)
      .watch()
      .map(
        (rows) =>
            rows
                .map(
                  (row) => model.Subject(
                    id: row.id,
                    name: row.name,
                    description: row.description,
                    createdAt: row.createdAt,
                  ),
                )
                .toList(),
      );
});

final subjectProvider = StreamProvider.family<model.Subject, int>((
  ref,
  id,
) async* {
  final database = ref.watch(databaseProvider);
  yield await database.getSubjectById(id);
});

class SubjectNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase database;

  SubjectNotifier(this.database) : super(const AsyncValue.data(null));

  Future<void> addSubject(String name, String? description) async {
    state = const AsyncValue.loading();
    try {
      await database.insertSubject(
        SubjectsCompanion(
          name: Value(name),
          description: Value(description),
          createdAt: Value(DateTime.now()),
        ),
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSubject(int id, String name, String? description) async {
    state = const AsyncValue.loading();
    try {
      await database.updateSubject(
        SubjectsCompanion(
          id: Value(id),
          name: Value(name),
          description: Value(description),
        ),
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteSubject(int id) async {
    state = const AsyncValue.loading();
    try {
      await database.deleteSubject(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final subjectNotifierProvider =
    StateNotifierProvider<SubjectNotifier, AsyncValue<void>>((ref) {
      final database = ref.watch(databaseProvider);
      return SubjectNotifier(database);
    });
