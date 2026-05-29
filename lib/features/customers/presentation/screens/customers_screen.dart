import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;  
import 'package:brand_dashboard/core/database/app_database.dart';
import 'package:brand_dashboard/features/customers/presentation/providers/customer_provider.dart';
import 'customer_sales_screen.dart';

/// Screen that displays all registered customers.
class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
      ),
      body: customersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Text('Error: $error'),
        ),
        data: (customers) => customers.isEmpty
            ? const _EmptyState()
            : _CustomersList(customers: customers),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCustomerForm(context, ref),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  void _showAddCustomerForm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddCustomerForm(ref: ref),
    );
  }
}

// ── EMPTY STATE ───────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Sin clientes registrados',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Toca + para agregar tu primer cliente',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── CUSTOMERS LIST ────────────────────────────────────────
class _CustomersList extends ConsumerWidget {
  final List<Customer> customers;
  const _CustomersList({required this.customers});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        return _CustomerCard(customer: customer, ref: ref);
      },
    );
  }
}

// ── CUSTOMER CARD ─────────────────────────────────────────
class _CustomerCard extends ConsumerWidget {
  final Customer customer;
  final WidgetRef ref;
  const _CustomerCard({
    required this.customer,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(customerSalesProvider(customer.id));
    final totalSales = salesAsync.value?.length ?? 0;
    final pendingPayments = salesAsync.value
            ?.where((s) => s.paymentStatus == 'pending')
            .length ??
        0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerSalesScreen(customer: customer),
          ),
        ),
        onLongPress: () => _confirmDelete(context, ref),
        leading: CircleAvatar(
          child: Text(
            customer.name[0].toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customer.phone != null)
              Text(
                customer.phone!,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            if (customer.notes != null)
              Text(
                customer.notes!,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$totalSales compras',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (pendingPayments > 0)
              Text(
                '$pendingPayments pendientes',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 11,
                ),
              )
            else
              const Text(
                'Al corriente',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar cliente?'),
        content: Text(
          'Se eliminará "${customer.name}" y todas sus compras.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(customerRepositoryProvider)
                  .deleteCustomer(customer.id);
              Navigator.pop(context);
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// ── ADD CUSTOMER FORM ─────────────────────────────────────
class _AddCustomerForm extends StatefulWidget {
  final WidgetRef ref;
  const _AddCustomerForm({required this.ref});

  @override
  State<_AddCustomerForm> createState() => _AddCustomerFormState();
}

class _AddCustomerFormState extends State<_AddCustomerForm> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    widget.ref.read(customerRepositoryProvider).addCustomer(
          CustomersCompanion.insert(
            name: _nameController.text.trim(),
            phone: Value(_phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim()),
            notes: Value(_notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim()),
          ),
        );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nuevo Cliente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre completo *',
                hintText: 'ej. María García',
              ),
              validator: (v) => v == null || v.isEmpty
                  ? 'El nombre es obligatorio'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Teléfono (opcional)',
                hintText: 'ej. 55 1234 5678',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                hintText: 'ej. Cliente frecuente, talla M',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Guardar Cliente'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}