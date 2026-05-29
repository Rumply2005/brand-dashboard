import 'package:drift/drift.dart';
import 'package:brand_dashboard/core/database/app_database.dart';

/// Repository that handles all operations for Customers and Sales.
class CustomerRepository {
  final AppDatabase _db;

  const CustomerRepository(this._db);

  // ── CUSTOMERS — READ ───────────────────────────────────
  /// Streams all customers ordered by name.
  Stream<List<Customer>> watchAllCustomers() {
    return (_db.select(_db.customers)
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch();
  }

  // ── CUSTOMERS — CREATE ─────────────────────────────────
  Future<void> addCustomer(CustomersCompanion customer) {
    return _db.into(_db.customers).insert(customer);
  }

  // ── CUSTOMERS — DELETE ─────────────────────────────────
  /// Deletes a customer and all their sales.
  Future<void> deleteCustomer(int customerId) async {
    await (_db.delete(_db.sales)
          ..where((s) => s.customerId.equals(customerId)))
        .go();
    await (_db.delete(_db.customers)
          ..where((c) => c.id.equals(customerId)))
        .go();
  }

  // ── SALES — READ ───────────────────────────────────────
  /// Streams all sales for a specific customer.
  Stream<List<Sale>> watchCustomerSales(int customerId) {
    return (_db.select(_db.sales)
          ..where((s) => s.customerId.equals(customerId))
          ..orderBy([(s) => OrderingTerm.desc(s.saleDate)]))
        .watch();
  }

  // ── SALES — CREATE ─────────────────────────────────────
  Future<void> addSale(SalesCompanion sale) {
    return _db.into(_db.sales).insert(sale);
  }

  // ── SALES — UPDATE PAYMENT ─────────────────────────────
  /// Updates the payment status of a sale.
  Future<void> updatePaymentStatus(int saleId, String status) {
    return (_db.update(_db.sales)
          ..where((s) => s.id.equals(saleId)))
        .write(SalesCompanion(
          paymentStatus: Value(status),
        ));
  }

  // ── SALES — DELETE ─────────────────────────────────────
  Future<void> deleteSale(int saleId) {
    return (_db.delete(_db.sales)
          ..where((s) => s.id.equals(saleId)))
        .go();
  }
}