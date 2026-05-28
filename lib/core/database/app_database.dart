import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:brand_dashboard/features/products/data/models/supply_item_table.dart';
import 'package:brand_dashboard/features/products/data/models/product_base_table.dart';
import 'package:brand_dashboard/features/products/data/models/product_variant_table.dart';

part 'app_database.g.dart';

/// Central database class for the Brand Dashboard application.
/// Version 2 adds ProductBases and ProductVariants tables.
@DriftDatabase(tables: [
  SupplyItems,
  ProductBases,
  ProductVariants,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      // Migration from v1 to v2: add new product tables
      if (from < 2) {
        await migrator.createTable(productBases);
        await migrator.createTable(productVariants);
      }
    },
  );
}

/// Opens the SQLite connection using the device's documents directory.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(
      p.join(dbFolder.path, 'brand_dashboard.sqlite'),
    );
    return NativeDatabase.createInBackground(file);
  });
}