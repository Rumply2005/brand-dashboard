import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:brand_dashboard/core/database/app_database.dart';
import 'package:brand_dashboard/features/customers/presentation/providers/customer_provider.dart';
import 'package:brand_dashboard/features/products/presentation/providers/product_provider.dart';

/// Screen that displays all sales for a specific customer.
class CustomerSalesScreen extends ConsumerWidget {
  final Customer customer;
  const CustomerSalesScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(customerSalesProvider(customer.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: salesAsync.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (sales) {
              final paid =
                  sales.where((s) => s.paymentStatus == 'paid').length;
              final pending =
                  sales.where((s) => s.paymentStatus == 'pending').length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${sales.length} compras · $paid pagadas · $pending pendientes',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      body: salesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Text('Error: $error'),
        ),
        data: (sales) => sales.isEmpty
            ? const _EmptyState()
            : _SalesList(sales: sales),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSaleForm(context, ref),
        child: const Icon(Icons.add_shopping_cart),
      ),
    );
  }

  void _showAddSaleForm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddSaleForm(
        ref: ref,
        customerId: customer.id,
      ),
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
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Sin compras registradas',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Toca + para registrar una compra',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── SALES LIST ────────────────────────────────────────────
class _SalesList extends StatelessWidget {
  final List<Sale> sales;
  const _SalesList({required this.sales});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sales.length,
      itemBuilder: (context, index) {
        return _SaleCard(sale: sales[index]);
      },
    );
  }
}

// ── SALE CARD ─────────────────────────────────────────────
class _SaleCard extends ConsumerWidget {
  final Sale sale;
  const _SaleCard({required this.sale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get variant info to show product name
    final variantsAsync = ref.watch(variantsProvider(sale.variantId));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onLongPress: () => _confirmDelete(context, ref),
        leading: CircleAvatar(
          backgroundColor: _paymentColor(sale.paymentStatus)
              .withOpacity(0.2),
          child: Icon(
            _paymentIcon(sale.paymentStatus),
            color: _paymentColor(sale.paymentStatus),
            size: 20,
          ),
        ),
        title: Text(
          '\$${sale.salePrice.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _formatDate(sale.saleDate),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            if (sale.notes != null)
              Text(
                sale.notes!,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        trailing: _PaymentStatusButton(sale: sale, ref: ref),
      ),
    );
  }

  Color _paymentColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  IconData _paymentIcon(String status) {
    switch (status) {
      case 'paid':
        return Icons.check_circle;
      case 'partial':
        return Icons.timelapse;
      default:
        return Icons.pending;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar venta?'),
        content: const Text(
          '¿Eliminar este registro de compra?',
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
                  .deleteSale(sale.id);
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

// ── PAYMENT STATUS BUTTON ─────────────────────────────────
class _PaymentStatusButton extends StatelessWidget {
  final Sale sale;
  final WidgetRef ref;
  const _PaymentStatusButton({
    required this.sale,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showStatusMenu(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: _statusColor().withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _statusLabel(),
          style: TextStyle(
            color: _statusColor(),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _statusColor() {
    switch (sale.paymentStatus) {
      case 'paid':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  String _statusLabel() {
    switch (sale.paymentStatus) {
      case 'paid':
        return '✅ Pagado';
      case 'partial':
        return '🕐 Abono';
      default:
        return '⏳ Pendiente';
    }
  }

  void _showStatusMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estado del pago',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _StatusOption(
              label: '✅ Pagado',
              color: Colors.green,
              onTap: () {
                ref
                    .read(customerRepositoryProvider)
                    .updatePaymentStatus(sale.id, 'paid');
                Navigator.pop(context);
              },
            ),
            _StatusOption(
              label: '🕐 Abono parcial',
              color: Colors.orange,
              onTap: () {
                ref
                    .read(customerRepositoryProvider)
                    .updatePaymentStatus(sale.id, 'partial');
                Navigator.pop(context);
              },
            ),
            _StatusOption(
              label: '⏳ Pendiente',
              color: Colors.red,
              onTap: () {
                ref
                    .read(customerRepositoryProvider)
                    .updatePaymentStatus(sale.id, 'pending');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── STATUS OPTION ─────────────────────────────────────────
class _StatusOption extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _StatusOption({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── ADD SALE FORM ─────────────────────────────────────────
class _AddSaleForm extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final int customerId;
  const _AddSaleForm({
    required this.ref,
    required this.customerId,
  });

  @override
  ConsumerState<_AddSaleForm> createState() => _AddSaleFormState();
}

class _AddSaleFormState extends ConsumerState<_AddSaleForm> {
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int? _selectedVariantId;
  String _paymentStatus = 'pending';

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVariantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un producto'),
        ),
      );
      return;
    }

    ref.read(customerRepositoryProvider).addSale(
          SalesCompanion.insert(
            customerId: widget.customerId,
            variantId: _selectedVariantId!,
            salePrice: double.parse(_priceController.text),
            paymentStatus: Value(_paymentStatus),
            notes: Value(_notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim()),
          ),
        );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registrar Compra',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Product selector
              productsAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Error cargando productos'),
                data: (products) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: products.map((product) {
                    final variantsAsync =
                        ref.watch(variantsProvider(product.id));
                    return variantsAsync.when(
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                      data: (variants) {
                        final available = variants
                            .where((v) => !v.isSold)
                            .toList();
                        if (available.isEmpty) return const SizedBox();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                product.name,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ...available.map((variant) => RadioListTile(
                                  value: variant.id,
                                  groupValue: _selectedVariantId,
                                  onChanged: (value) => setState(
                                    () => _selectedVariantId = value,
                                  ),
                                  title: Text(
                                    '#${variant.variantNumber} · ${variant.color ?? "Sin color"}',
                                  ),
                                  subtitle: variant.additionals != null
                                      ? Text(variant.additionals!)
                                      : null,
                                )),
                          ],
                        );
                      },
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Precio de venta *',
                  hintText: '0.00',
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (double.tryParse(v) == null) {
                    return 'Número inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Payment status selector
              const Text(
                'Estado del pago',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _PaymentChip(
                    label: 'Pagado',
                    value: 'paid',
                    selected: _paymentStatus == 'paid',
                    color: Colors.green,
                    onTap: () =>
                        setState(() => _paymentStatus = 'paid'),
                  ),
                  const SizedBox(width: 8),
                  _PaymentChip(
                    label: 'Abono',
                    value: 'partial',
                    selected: _paymentStatus == 'partial',
                    color: Colors.orange,
                    onTap: () =>
                        setState(() => _paymentStatus = 'partial'),
                  ),
                  const SizedBox(width: 8),
                  _PaymentChip(
                    label: 'Pendiente',
                    value: 'pending',
                    selected: _paymentStatus == 'pending',
                    color: Colors.red,
                    onTap: () =>
                        setState(() => _paymentStatus = 'pending'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  hintText: 'ej. Pedido especial, entrega a domicilio',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('Registrar Compra'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── PAYMENT CHIP ──────────────────────────────────────────
class _PaymentChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _PaymentChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.3)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? Border.all(color: color, width: 1.5)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : Colors.grey,
            fontSize: 12,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}