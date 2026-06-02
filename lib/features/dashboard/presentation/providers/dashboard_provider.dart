import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brand_dashboard/core/database/app_database.dart';
import 'package:brand_dashboard/core/database/database_provider.dart';
import 'package:brand_dashboard/features/dashboard/data/repositories/dashboard_repository.dart';

/// Dashboard summary data model.
class DashboardSummary {
  final double totalRevenue;
  final int totalSales;
  final int pendingPayments;
  final Map<String, double> revenueByProduct;
  final Map<String, int> paymentDistribution;
  final List<SupplyItem> topSupplyCosts;

  const DashboardSummary({
    required this.totalRevenue,
    required this.totalSales,
    required this.pendingPayments,
    required this.revenueByProduct,
    required this.paymentDistribution,
    required this.topSupplyCosts,
  });
}

/// Provides the DashboardRepository instance.
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return DashboardRepository(database);
});

/// Loads all dashboard data in a single provider.
final dashboardProvider = FutureProvider<DashboardSummary>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);

  final results = await Future.wait([
    repo.getTotalRevenue(),
    repo.getTotalSales(),
    repo.getPendingPayments(),
    repo.getRevenueByProduct(),
    repo.getPaymentStatusDistribution(),
    repo.getTopSupplyCosts(),
  ]);

  return DashboardSummary(
    totalRevenue: results[0] as double,
    totalSales: results[1] as int,
    pendingPayments: results[2] as int,
    revenueByProduct: results[3] as Map<String, double>,
    paymentDistribution: results[4] as Map<String, int>,
    topSupplyCosts: results[5] as List<SupplyItem>,
  );
});