import 'package:drift/drift.dart';
import 'package:riverpod/riverpod.dart';
import 'package:mnemoszune/database/database.dart';
import 'package:mnemoszune/providers/database_provider.dart';
import 'package:mnemoszune/models/material.dart' as model;

final materialsForSubjectProvider =
    StreamProvider.family<List<model.StudyMaterial>, int>((ref, subjectId) {
      final database = ref.watch(databaseProvider);
      return database.watchMaterialsForSubject(subjectId);
    });

class MaterialNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase database;

  MaterialNotifier(this.database) : super(const AsyncValue.data(null));

  Future<void> addMaterial(
    String title,
    String? description,
    int subjectId,
    String filePath,
  ) async {
    state = const AsyncValue.loading();
    try {
      await database.insertMaterial(
        MaterialsCompanion(
          title: Value(title),
          description: Value(description),
          subjectId: Value(subjectId),
          filePath: Value(filePath),
          createdAt: Value(DateTime.now()),
        ),
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateMaterial(int id, String title, String? description) async {
    state = const AsyncValue.loading();
    try {
      await database.updateMaterial(
        MaterialsCompanion(
          id: Value(id),
          title: Value(title),
          description: Value(description),
        ),
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteMaterial(int id) async {
    state = const AsyncValue.loading();
    try {
      await database.deleteMaterial(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final materialNotifierProvider =
    StateNotifierProvider<MaterialNotifier, AsyncValue<void>>((ref) {
      final database = ref.watch(databaseProvider);
      return MaterialNotifier(database);
    });
