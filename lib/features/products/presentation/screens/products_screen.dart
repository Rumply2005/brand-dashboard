import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value; 
import 'package:brand_dashboard/core/database/app_database.dart';
import 'package:brand_dashboard/features/products/presentation/providers/product_provider.dart';
import 'variants_screen.dart';

/// Screen that displays all base products.
/// Each product can have multiple variants (colors/sizes).
class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Productos'),
      ),
      body: productsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Text('Error: $error'),
        ),
        data: (products) => products.isEmpty
            ? const _EmptyState()
            : _ProductsList(products: products),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddProductForm(ref: ref),
    );
  }
}

// ── EMPTY STATE ──────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.checkroom_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Sin productos registrados',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Toca + para agregar tu primer modelo',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── PRODUCTS LIST ─────────────────────────────────────────
class _ProductsList extends ConsumerWidget {
  final List<ProductBase> products;
  const _ProductsList({required this.products});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _ProductCard(product: product, ref: ref);
      },
    );
  }
}

// ── PRODUCT CARD ──────────────────────────────────────────
class _ProductCard extends ConsumerWidget {
  final ProductBase product;
  final WidgetRef ref;
  const _ProductCard({required this.product, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch variants count in real time
    final variantsAsync = ref.watch(variantsProvider(product.id));

    final totalVariants = variantsAsync.value?.length ?? 0;
    final soldVariants =
        variantsAsync.value?.where((v) => v.isSold).length ?? 0;
    final availableVariants = totalVariants - soldVariants;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VariantsScreen(product: product),
          ),
        ),
        onLongPress: () => _confirmDelete(context, ref),
        leading: const CircleAvatar(
          child: Icon(Icons.checkroom),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          product.description ?? 'Sin descripción',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$availableVariants disponibles',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$soldVariants vendidas',
              style: const TextStyle(
                color: Colors.grey,
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
        title: const Text('¿Eliminar producto?'),
        content: Text(
          'Se eliminará "${product.name}" y todas sus variantes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(productRepositoryProvider)
                  .deleteProduct(product.id);
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

// ── ADD PRODUCT FORM ──────────────────────────────────────
class _AddProductForm extends StatefulWidget {
  final WidgetRef ref;
  const _AddProductForm({required this.ref});

  @override
  State<_AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends State<_AddProductForm> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    widget.ref.read(productRepositoryProvider).addProduct(
          ProductBasesCompanion.insert(
            name: _nameController.text.trim(),
            description:
                Value(_descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim()),
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
              'Nuevo Modelo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del modelo *',
                hintText: 'ej. Playera Oversize',
              ),
              validator: (v) => v == null || v.isEmpty
                  ? 'El nombre es obligatorio'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                hintText: 'ej. Corte relajado, tela de algodón',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Guardar Modelo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}