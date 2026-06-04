import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:brand_dashboard/features/products/data/models/supply_item_table.dart';
import 'package:brand_dashboard/features/products/data/models/product_base_table.dart';
import 'package:brand_dashboard/features/products/data/models/product_variant_table.dart';
import 'package:brand_dashboard/features/customers/data/models/customer_table.dart';
import 'package:brand_dashboard/features/customers/data/models/sale_table.dart';
import 'package:brand_dashboard/features/costs/data/models/product_recipe_table.dart';
import 'package:brand_dashboard/features/costs/data/models/recipe_item_table.dart';

part 'app_database.g.dart';

/// Central database — Brand Dashboard
/// v1 → SupplyItems
/// v2 → ProductBases, ProductVariants
/// v3 → Customers, Sales
/// v4 → ProductRecipes, RecipeItems
@DriftDatabase(tables: [
  SupplyItems,
  ProductBases,
  ProductVariants,
  Customers,
  Sales,
  ProductRecipes,
  RecipeItems,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(productBases);
        await migrator.createTable(productVariants);
      }
      if (from < 3) {
        await migrator.createTable(customers);
        await migrator.createTable(sales);
      }
      if (from < 4) {
        await migrator.createTable(productRecipes);
        await migrator.createTable(recipeItems);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(
      p.join(dbFolder.path, 'brand_dashboard.sqlite'),
    );
    return NativeDatabase.createInBackground(file);
  });
}