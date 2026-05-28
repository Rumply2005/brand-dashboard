import 'package:drift/drift.dart';
import 'package:brand_dashboard/core/database/app_database.dart';

/// Repository that handles all operations for Products and Variants.
class ProductRepository {
  final AppDatabase _db;

  const ProductRepository(this._db);

  // ── PRODUCT BASE — READ ────────────────────────────────
  /// Streams all base products ordered by name.
  Stream<List<ProductBase>> watchAllProducts() {
    return (_db.select(_db.productBases)
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch();
  }

  // ── PRODUCT BASE — CREATE ──────────────────────────────
  /// Creates a new base product.
  Future<void> addProduct(ProductBasesCompanion product) {
    return _db.into(_db.productBases).insert(product);
  }

  // ── PRODUCT BASE — DELETE ──────────────────────────────
  /// Deletes a base product and all its variants.
  Future<void> deleteProduct(int productId) async {
    // Delete variants first (child records)
    await (_db.delete(_db.productVariants)
          ..where((v) => v.productId.equals(productId)))
        .go();
    // Then delete the base product
    await (_db.delete(_db.productBases)
          ..where((p) => p.id.equals(productId)))
        .go();
  }

  // ── VARIANTS — READ ────────────────────────────────────
  /// Streams all variants for a specific product.
  Stream<List<ProductVariant>> watchVariants(int productId) {
    return (_db.select(_db.productVariants)
          ..where((v) => v.productId.equals(productId))
          ..orderBy([(v) => OrderingTerm.asc(v.variantNumber)]))
        .watch();
  }

  // ── VARIANTS — CREATE ──────────────────────────────────
  /// Adds a new variant with auto-incremented variant number.
  Future<void> addVariant({
    required int productId,
    String? color,
    String? additionals,
  }) async {
    // Count existing variants to auto-generate the number
    final existing = await (_db.select(_db.productVariants)
          ..where((v) => v.productId.equals(productId)))
        .get();

    final nextNumber = existing.length + 1;

    await _db.into(_db.productVariants).insert(
          ProductVariantsCompanion.insert(
            productId: productId,
            variantNumber: nextNumber,
            color: Value(color),
            additionals: Value(additionals),
          ),
        );
  }

  // ── VARIANTS — MARK AS SOLD ────────────────────────────
  /// Marks a variant as sold with the current timestamp.
  Future<void> markAsSold(int variantId) {
    return (_db.update(_db.productVariants)
          ..where((v) => v.id.equals(variantId)))
        .write(ProductVariantsCompanion(
          isSold: const Value(true),
          soldAt: Value(DateTime.now()),
        ));
  }

  // ── VARIANTS — MARK AS AVAILABLE ──────────────────────
  /// Reverts a variant back to available status.
  Future<void> markAsAvailable(int variantId) {
    return (_db.update(_db.productVariants)
          ..where((v) => v.id.equals(variantId)))
        .write(const ProductVariantsCompanion(
          isSold: Value(false),
          soldAt: Value(null),
        ));
  }

  // ── VARIANTS — DELETE ──────────────────────────────────
  /// Deletes a single variant.
  Future<void> deleteVariant(int variantId) {
    return (_db.delete(_db.productVariants)
          ..where((v) => v.id.equals(variantId)))
        .go();
  }
}