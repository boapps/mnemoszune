import 'package:drift/drift.dart';
import 'package:riverpod/riverpod.dart';
import 'package:mnemoszune/database/database.dart';
import 'package:mnemoszune/providers/database_provider.dart';
import 'package:mnemoszune/models/material.dart' as model;
import 'package:mnemoszune/services/vector_service.dart';

final materialsForSubjectProvider =
    StreamProvider.family<List<model.StudyMaterial>, int>((ref, subjectId) {
      final database = ref.watch(databaseProvider);
      return database.watchMaterialsForSubject(subjectId);
    });

class MaterialNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase database;
  final VectorService vectorService;

  MaterialNotifier(this.database, this.vectorService)
    : super(const AsyncValue.data(null));

  Future<void> addMaterial(
    String title,
    String? description,
    int subjectId,
    String filePath,
  ) async {
    state = const AsyncValue.loading();
    try {
      // First insert the material to get its ID
      final materialId = await database.insertMaterial(
        MaterialsCompanion(
          title: Value(title),
          description: Value(description),
          subjectId: Value(subjectId),
          filePath: Value(filePath),
          createdAt: Value(DateTime.now()),
          isVectorized: Value(false), // Initially not vectorized
        ),
      );

      // Now process the document for vector storage
      try {
        await vectorService.processAndStoreDocument(materialId, filePath);

        // Update material to mark it as vectorized
        await database.markMaterialAsVectorized(materialId);
      } catch (e, s) {
        // Log the error but don't fail the whole operation
        print('Error processing document for vector storage: $e');
        print('Stack trace: $s');
        // Material is still added but not vectorized
      }

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

  Future<List<model.StudyMaterial>> searchMaterialsByContent(
    String query,
  ) async {
    try {
      // Search for similar documents in the vector store
      final results = await vectorService.similaritySearch(query);

      // Extract material IDs from the search results
      final materialIds =
          results
              .map((doc) => doc.metadata['materialId'] as int?)
              .where((id) => id != null)
              .map((id) => id as int)
              .toSet();

      // Fetch the actual materials from the database
      if (materialIds.isEmpty) {
        return [];
      }

      // Return materials that match the IDs from vector search
      return await database.getMaterialsByIds(materialIds.toList());
    } catch (e) {
      print('Error searching materials by content: $e');
      return [];
    }
  }
}

final materialNotifierProvider = StateNotifierProvider<
  MaterialNotifier,
  AsyncValue<void>
>((ref) {
  final database = ref.watch(databaseProvider);
  final vectorService = ref.watch(vectorServiceProvider).valueOrNull;

  // If vectorService is not ready yet, return a placeholder that shows loading state
  if (vectorService == null) {
    return MaterialNotifier(
      database,
      throw UnimplementedError('VectorService is not initialized yet'),
    );
  }

  return MaterialNotifier(database, vectorService);
});
