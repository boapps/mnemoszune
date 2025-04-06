import 'package:riverpod/riverpod.dart';
import 'package:mnemoszune/database/database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(() => database.close());
  return database;
});
