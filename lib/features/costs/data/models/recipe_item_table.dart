import 'package:drift/drift.dart';
import 'product_recipe_table.dart';
import 'package:brand_dashboard/features/products/data/models/supply_item_table.dart';

/// Represents a supply item used in a product recipe with quantity.
class RecipeItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get recipeId => integer()
      .references(ProductRecipes, #id)();
  IntColumn get supplyItemId => integer()
      .references(SupplyItems, #id)();
  RealColumn get quantity => real()();
}