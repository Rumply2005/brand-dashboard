import 'package:drift/drift.dart';

/// Represents a saved product recipe with cost breakdown.
class ProductRecipes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get salePrice => real()();
  RealColumn get laborCost => real().withDefault(const Constant(0.0))();
  RealColumn get packagingCost => real().withDefault(const Constant(0.0))();
  RealColumn get otherCosts => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)();
}