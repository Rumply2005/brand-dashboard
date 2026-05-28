import 'package:drift/drift.dart';

/// Drift table definition for supply items (raw materials/inputs).
/// Designed to be generic and business-agnostic for future scalability.
/// Current UI context: textile/fashion brand inputs.
class SupplyItems extends Table {
  // Auto-incremented primary key
  IntColumn get id => integer().autoIncrement()();

  // Display name of the supply item (e.g., "Linen fabric")
  TextColumn get name => text().withLength(min: 1, max: 100)();

  // Unit of measurement (e.g., "meter", "kg", "piece")
  TextColumn get unit => text().withLength(min: 1, max: 20)();

  // Cost per unit in local currency
  RealColumn get unitCost => real()();

  // Optional supplier name for reference
  TextColumn get supplier => text().nullable()();

  // Audit timestamps
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)();
}