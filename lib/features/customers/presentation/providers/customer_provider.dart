import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brand_dashboard/core/database/app_database.dart';
import 'package:brand_dashboard/core/database/database_provider.dart';
import 'package:brand_dashboard/features/customers/data/repositories/customer_repository.dart';

/// Provides the CustomerRepository instance.
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return CustomerRepository(database);
});

/// Streams all customers in real time.
final customersProvider = StreamProvider<List<Customer>>((ref) {
  final repository = ref.watch(customerRepositoryProvider);
  return repository.watchAllCustomers();
});

/// Streams all sales for a specific customer.
final customerSalesProvider =
    StreamProvider.family<List<Sale>, int>((ref, customerId) {
  final repository = ref.watch(customerRepositoryProvider);
  return repository.watchCustomerSales(customerId);
});
