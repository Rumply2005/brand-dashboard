import 'package:drift/drift.dart';
import 'product_base_table.dart';

/// Represents a specific variant of a base product.
/// Example: "Playera Oversize #1 - Color: Blanco"
class ProductVariants extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Foreign key → links to the parent ProductBase
  IntColumn get productId => integer()
      .references(ProductBases, #id)();

  // Auto-incremented per product (handled in repository)
  IntColumn get variantNumber => integer()();

  TextColumn get color => text().nullable()();
  TextColumn get additionals => text().nullable()();

  // Sales status
  BoolColumn get isSold => boolean()
      .withDefault(const Constant(false))();
  DateTimeColumn get soldAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)();
}