import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';

/// Global provider that exposes the single AppDatabase instance.
/// Using [Provider] because the database instance never changes —
/// it's created once and reused throughout the app lifecycle.
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();

  // Dispose the database connection when the provider is destroyed
  ref.onDispose(() => database.close());

  return database;
});