import 'package:drift/drift.dart';
import 'package:brand_dashboard/core/database/app_database.dart';

/// Repository that handles all CRUD operations for SupplyItems.
/// This is the ONLY layer that communicates directly with the database.
class SupplyItemRepository {
  final AppDatabase _db;

  const SupplyItemRepository(this._db);

  // ── READ ──────────────────────────────────────────────
  Stream<List<SupplyItem>> watchAllItems() {
    return (_db.select(_db.supplyItems)
          ..orderBy([
            (item) => OrderingTerm(
                  expression: item.unitCost,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch();
  }

  // ── CREATE ─────────────────────────────────────────────
  Future<void> addItem(SupplyItemsCompanion item) {
    return _db.into(_db.supplyItems).insert(item);
  }

  // ── UPDATE ─────────────────────────────────────────────
  Future<void> updateItem(SupplyItemsCompanion item) {
    return (_db.update(_db.supplyItems)
          ..where((row) => row.id.equals(item.id.value)))
        .write(item);
  }

  // ── DELETE ─────────────────────────────────────────────
  Future<void> deleteItem(int id) {
    return (_db.delete(_db.supplyItems)
          ..where((row) => row.id.equals(id)))
        .go();
  }
}