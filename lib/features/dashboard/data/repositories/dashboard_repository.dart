import 'package:brand_dashboard/core/database/app_database.dart';
import 'package:drift/drift.dart';

/// Repository that aggregates data from multiple tables
/// to power the analytics dashboard.
class DashboardRepository {
  final AppDatabase _db;

  const DashboardRepository(this._db);

  // ── TOTAL REVENUE ──────────────────────────────────────
  /// Returns total revenue from all sales.
  Future<double> getTotalRevenue() async {
    final sales = await _db.select(_db.sales).get();
    return sales.fold<double>(0.0, (sum, sale) => sum + sale.salePrice);
  }

  // ── SALES COUNT ────────────────────────────────────────
  /// Returns total number of sales.
  Future<int> getTotalSales() async {
    final sales = await _db.select(_db.sales).get();
    return sales.length;
  }

  // ── PENDING PAYMENTS ───────────────────────────────────
  /// Returns number of sales with pending payment.
  Future<int> getPendingPayments() async {
    final sales = await (_db.select(_db.sales)
          ..where((s) => s.paymentStatus.equals('pending')))
        .get();
    return sales.length;
  }

  // ── REVENUE BY PRODUCT ─────────────────────────────────
  /// Returns a map of product name → total revenue.
  Future<Map<String, double>> getRevenueByProduct() async {
    final sales = await _db.select(_db.sales).get();
    final variants = await _db.select(_db.productVariants).get();
    final products = await _db.select(_db.productBases).get();

    final Map<String, double> revenueMap = {};

    for (final sale in sales) {
      final variant = variants
          .where((v) => v.id == sale.variantId)
          .firstOrNull;
      if (variant == null) continue;

      final product = products
          .where((p) => p.id == variant.productId)
          .firstOrNull;
      if (product == null) continue;

      revenueMap[product.name] =
          (revenueMap[product.name] ?? 0) + sale.salePrice;
    }

    return revenueMap;
  }

  // ── PAYMENT STATUS DISTRIBUTION ────────────────────────
  /// Returns count of sales per payment status.
  Future<Map<String, int>> getPaymentStatusDistribution() async {
    final sales = await _db.select(_db.sales).get();
    final Map<String, int> distribution = {
      'paid': 0,
      'partial': 0,
      'pending': 0,
    };
    for (final sale in sales) {
      distribution[sale.paymentStatus] =
          (distribution[sale.paymentStatus] ?? 0) + 1;
    }
    return distribution;
  }

  // ── TOP SUPPLY COSTS ───────────────────────────────────
  /// Returns top 5 supply items by unit cost.
  Future<List<SupplyItem>> getTopSupplyCosts() async {
    return (_db.select(_db.supplyItems)
          ..orderBy([
            (s) => OrderingTerm(
                  expression: s.unitCost,
                  mode: OrderingMode.desc,
                )
          ])
          ..limit(5))
        .get();
  }
}