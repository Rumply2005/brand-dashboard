import 'package:drift/drift.dart';
import 'customer_table.dart';
import 'package:brand_dashboard/features/products/data/models/product_variant_table.dart';

/// Represents a sale linking a customer to a product variant.
class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Foreign keys
  IntColumn get customerId => integer()
      .references(Customers, #id)();
  IntColumn get variantId => integer()
      .references(ProductVariants, #id)();

  // Sale details
  RealColumn get salePrice => real()();
  TextColumn get paymentStatus => text()
      .withDefault(const Constant('pending'))();
  DateTimeColumn get saleDate => dateTime()
      .withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)();
}