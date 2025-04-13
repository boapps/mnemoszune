import 'dart:io';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:mnemoszune/models/subject.dart' as model;
import 'package:mnemoszune/models/quiz.dart' as model;
import 'package:mnemoszune/models/exercise.dart' as model;
import 'package:mnemoszune/models/material.dart' as model;

part 'database.g.dart';

class Subjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

class Quizzes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get subjectId => integer().references(Subjects, #id)();
  DateTimeColumn get createdAt => dateTime()();
}

class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get quizId => integer().references(Quizzes, #id)();
  TextColumn get question => text()();
  TextColumn get answer => text()();
  TextColumn get type => text()(); // 'questionAnswer' or 'multipleChoice'
  TextColumn get options =>
      text().nullable()(); // JSON string of options for multiple choice
}

class Materials extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get subjectId => integer().references(Subjects, #id)();
  TextColumn get filePath => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isVectorized => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [Subjects, Quizzes, Exercises, Materials])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Subject operations
  Future<List<model.Subject>> getAllSubjects() async {
    final results = await select(subjects).get();
    return results
        .map(
          (row) => model.Subject(
            id: row.id,
            name: row.name,
            description: row.description,
            createdAt: row.createdAt,
          ),
        )
        .toList();
  }

  Future<model.Subject> getSubjectById(int id) async {
    final row =
        await (select(subjects)..where((s) => s.id.equals(id))).getSingle();
    return model.Subject(
      id: row.id,
      name: row.name,
      description: row.description,
      createdAt: row.createdAt,
    );
  }

  Future<int> insertSubject(SubjectsCompanion entry) =>
      into(subjects).insert(entry);
  Future<bool> updateSubject(SubjectsCompanion entry) =>
      update(subjects).replace(entry);
  Future<int> deleteSubject(int id) =>
      (delete(subjects)..where((s) => s.id.equals(id))).go();

  // Quiz operations
  Future<List<model.Quiz>> getQuizzesForSubject(int subjectId) async {
    final results =
        await (select(quizzes)
          ..where((q) => q.subjectId.equals(subjectId))).get();
    return results
        .map(
          (row) => model.Quiz(
            id: row.id,
            title: row.title,
            description: row.description,
            subjectId: row.subjectId,
            createdAt: row.createdAt,
          ),
        )
        .toList();
  }

  Future<model.Quiz> getQuizById(int id) async {
    final row =
        await (select(quizzes)..where((q) => q.id.equals(id))).getSingle();
    return model.Quiz(
      id: row.id,
      title: row.title,
      description: row.description,
      subjectId: row.subjectId,
      createdAt: row.createdAt,
    );
  }

  Future<int> insertQuiz(QuizzesCompanion entry) => into(quizzes).insert(entry);
  Future<bool> updateQuiz(QuizzesCompanion entry) =>
      update(quizzes).replace(entry);
  Future<int> deleteQuiz(int id) =>
      (delete(quizzes)..where((q) => q.id.equals(id))).go();

  // Exercise operations
  Future<List<model.Exercise>> getExercisesForQuiz(int quizId) async {
    final results =
        await (select(exercises)..where((e) => e.quizId.equals(quizId))).get();
    return results
        .map(
          (row) => model.Exercise(
            id: row.id,
            quizId: row.quizId,
            question: row.question,
            answer: row.answer,
            type:
                row.type == 'multipleChoice'
                    ? model.ExerciseType.multipleChoice
                    : model.ExerciseType.questionAnswer,
            options:
                row.options != null
                    ? (jsonDecode(row.options!) as List<dynamic>).cast<String>()
                    : null,
          ),
        )
        .toList();
  }

  Stream<List<model.Exercise>> watchExercisesForQuiz(int quizId) {
    return (select(exercises)
      ..where((e) => e.quizId.equals(quizId))).watch().map(
      (rows) =>
          rows
              .map(
                (row) => model.Exercise(
                  id: row.id,
                  quizId: row.quizId,
                  question: row.question,
                  answer: row.answer,
                  type:
                      row.type == 'multipleChoice'
                          ? model.ExerciseType.multipleChoice
                          : model.ExerciseType.questionAnswer,
                  options:
                      row.options != null
                          ? (jsonDecode(row.options!) as List<dynamic>)
                              .cast<String>()
                          : null,
                ),
              )
              .toList(),
    );
  }

  Future<int> insertExercise(ExercisesCompanion entry) =>
      into(exercises).insert(entry);
  Future<bool> updateExercise(ExercisesCompanion entry) =>
      update(exercises).replace(entry);
  Future<int> deleteExercise(int id) =>
      (delete(exercises)..where((e) => e.id.equals(id))).go();

  // Material operations
  Future<List<model.StudyMaterial>> getMaterialsForSubject(
    int subjectId,
  ) async {
    final results =
        await (select(materials)
          ..where((m) => m.subjectId.equals(subjectId))).get();
    return results
        .map(
          (row) => model.StudyMaterial(
            id: row.id,
            title: row.title,
            description: row.description,
            subjectId: row.subjectId,
            filePath: row.filePath,
            createdAt: row.createdAt,
          ),
        )
        .toList();
  }

  Stream<List<model.StudyMaterial>> watchMaterialsForSubject(int subjectId) {
    return (select(materials)
      ..where((m) => m.subjectId.equals(subjectId))).watch().map(
      (rows) =>
          rows
              .map(
                (row) => model.StudyMaterial(
                  id: row.id,
                  title: row.title,
                  description: row.description,
                  subjectId: row.subjectId,
                  filePath: row.filePath,
                  createdAt: row.createdAt,
                ),
              )
              .toList(),
    );
  }

  Future<List<model.StudyMaterial>> getMaterialsByIds(List<int> ids) async {
    final query = select(materials)..where((tbl) => tbl.id.isIn(ids));
    final results = await query.get();
    return results
        .map(
          (row) => model.StudyMaterial(
            id: row.id,
            title: row.title,
            description: row.description,
            subjectId: row.subjectId,
            filePath: row.filePath,
            createdAt: row.createdAt,
            isVectorized: row.isVectorized,
          ),
        )
        .toList();
  }

  Future<int> insertMaterial(MaterialsCompanion entry) =>
      into(materials).insert(entry);
  Future<bool> updateMaterial(MaterialsCompanion entry) =>
      update(materials).replace(entry);
  Future<int> deleteMaterial(int id) =>
      (delete(materials)..where((m) => m.id.equals(id))).go();

  Future<void> markMaterialAsVectorized(int id) async {
    await (update(materials)..where(
      (m) => m.id.equals(id),
    )).write(MaterialsCompanion(isVectorized: const Value(true)));
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'mnemoszune.sqlite'));
    return NativeDatabase(file);
  });
}
