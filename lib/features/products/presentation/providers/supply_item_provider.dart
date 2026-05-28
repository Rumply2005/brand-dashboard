import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brand_dashboard/core/database/app_database.dart';
import 'package:brand_dashboard/core/database/database_provider.dart';
import 'package:brand_dashboard/features/products/data/repositories/supply_item_repository.dart';

/// Provides the SupplyItemRepository instance.
/// Depends on databaseProvider to get the AppDatabase.
final supplyItemRepositoryProvider = Provider<SupplyItemRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return SupplyItemRepository(database);
});

/// Streams the list of all supply items in real time.
/// Automatically updates the UI when data changes in the database.
final supplyItemsProvider = StreamProvider<List<SupplyItem>>((ref) {
  final repository = ref.watch(supplyItemRepositoryProvider);
  return repository.watchAllItems();
});