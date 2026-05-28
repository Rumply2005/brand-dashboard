import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brand_dashboard/core/database/app_database.dart';
import 'package:brand_dashboard/core/database/database_provider.dart';
import 'package:brand_dashboard/features/products/data/repositories/product_repository.dart';

/// Provides the ProductRepository instance.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return ProductRepository(database);
});

/// Streams all base products in real time.
final productsProvider = StreamProvider<List<ProductBase>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.watchAllProducts();
});

/// Streams all variants for a specific product.
/// Requires a productId parameter.
final variantsProvider = StreamProvider.family<List<ProductVariant>, int>(
  (ref, productId) {
    final repository = ref.watch(productRepositoryProvider);
    return repository.watchVariants(productId);
  },
);