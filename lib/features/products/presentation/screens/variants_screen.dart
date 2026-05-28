import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brand_dashboard/core/database/app_database.dart';
import 'package:brand_dashboard/features/products/presentation/providers/product_provider.dart';

/// Screen that displays all variants of a specific base product.
/// Each variant has a color, additionals, and sold status.
class VariantsScreen extends ConsumerWidget {
  final ProductBase product;
  const VariantsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variantsAsync = ref.watch(variantsProvider(product.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: variantsAsync.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (variants) {
              final sold = variants.where((v) => v.isSold).length;
              final available = variants.length - sold;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '$available disponibles · $sold vendidas',
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
      body: variantsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Text('Error: $error'),
        ),
        data: (variants) => variants.isEmpty
            ? const _EmptyState()
            : _VariantsList(variants: variants),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddVariantDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddVariantDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddVariantForm(
        ref: ref,
        productId: product.id,
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
            Icons.palette_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Sin variantes registradas',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Toca + para agregar una variante',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── VARIANTS LIST ─────────────────────────────────────────
class _VariantsList extends StatelessWidget {
  final List<ProductVariant> variants;
  const _VariantsList({required this.variants});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: variants.length,
      itemBuilder: (context, index) {
        return _VariantCard(variant: variants[index]);
      },
    );
  }
}

// ── VARIANT CARD ──────────────────────────────────────────
class _VariantCard extends ConsumerWidget {
  final ProductVariant variant;
  const _VariantCard({required this.variant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onLongPress: () => _confirmDelete(context, ref),
        leading: CircleAvatar(
          backgroundColor: variant.isSold
              ? Colors.green.withOpacity(0.2)
              : Colors.blue.withOpacity(0.2),
          child: Text(
            '#${variant.variantNumber}',
            style: TextStyle(
              color: variant.isSold ? Colors.green : Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          variant.color ?? 'Sin color especificado',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: variant.additionals != null
            ? Text(
                variant.additionals!,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: _SoldToggle(variant: variant, ref: ref),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar variante?'),
        content: Text(
          '¿Eliminar variante #${variant.variantNumber}?',
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
                  .deleteVariant(variant.id);
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

// ── SOLD TOGGLE ───────────────────────────────────────────
class _SoldToggle extends StatelessWidget {
  final ProductVariant variant;
  final WidgetRef ref;
  const _SoldToggle({required this.variant, required this.ref});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _toggleSold(),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: variant.isSold
              ? Colors.green.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          variant.isSold ? '✅ Vendida' : '⬜ Stock',
          style: TextStyle(
            color: variant.isSold ? Colors.green : Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _toggleSold() {
    final repository = ref.read(productRepositoryProvider);
    if (variant.isSold) {
      repository.markAsAvailable(variant.id);
    } else {
      repository.markAsSold(variant.id);
    }
  }
}

// ── ADD VARIANT FORM ──────────────────────────────────────
class _AddVariantForm extends StatefulWidget {
  final WidgetRef ref;
  final int productId;
  const _AddVariantForm({
    required this.ref,
    required this.productId,
  });

  @override
  State<_AddVariantForm> createState() => _AddVariantFormState();
}

class _AddVariantFormState extends State<_AddVariantForm> {
  final _colorController = TextEditingController();
  final _additionalsController = TextEditingController();

  @override
  void dispose() {
    _colorController.dispose();
    _additionalsController.dispose();
    super.dispose();
  }

  void _submit() {
    widget.ref.read(productRepositoryProvider).addVariant(
          productId: widget.productId,
          color: _colorController.text.trim().isEmpty
              ? null
              : _colorController.text.trim(),
          additionals: _additionalsController.text.trim().isEmpty
              ? null
              : _additionalsController.text.trim(),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nueva Variante',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _colorController,
            decoration: const InputDecoration(
              labelText: 'Color (opcional)',
              hintText: 'ej. Blanco, Negro, Beige',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _additionalsController,
            decoration: const InputDecoration(
              labelText: 'Adicionales (opcional)',
              hintText: 'ej. Bordado en manga, talla XL',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: const Text('Agregar Variante'),
            ),
          ),
        ],
      ),
    );
  }
}