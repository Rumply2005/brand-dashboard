import 'package:drift/drift.dart';

/// Represents the base product model.
/// Example: "Playera Oversize", "Pantalón Recto"
class ProductBases extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)();
}