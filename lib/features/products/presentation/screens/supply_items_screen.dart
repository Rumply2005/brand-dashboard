import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:brand_dashboard/core/database/app_database.dart';
import 'package:brand_dashboard/features/products/presentation/providers/supply_item_provider.dart';

/// Main screen for managing supply items.
/// Implements US-001, US-002, US-003, US-004.
class SupplyItemsScreen extends ConsumerWidget {
  const SupplyItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(supplyItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Costos de Insumos'),
      ),
      body: itemsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Text('Error: $error'),
        ),
        data: (items) => items.isEmpty
            ? const _EmptyState()
            : _ItemsList(items: items),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemForm(context, ref, item: null),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Opens the bottom sheet form.
  /// If [item] is null → create mode.
  /// If [item] has value → edit mode.
  static void _showItemForm(
    BuildContext context,
    WidgetRef ref, {
    required SupplyItem? item,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ItemForm(ref: ref, item: item),
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
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Sin insumos registrados',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Toca + para agregar tu primer insumo',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── ITEMS LIST ───────────────────────────────────────────
class _ItemsList extends ConsumerWidget {
  final List<SupplyItem> items;
  const _ItemsList({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _ItemCard(item: item, ref: ref);
      },
    );
  }
}

// ── ITEM CARD ─────────────────────────────────────────────
class _ItemCard extends StatelessWidget {
  final SupplyItem item;
  final WidgetRef ref;
  const _ItemCard({required this.item, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        // Tap → edit
        onTap: () => SupplyItemsScreen._showItemForm(
          context,
          ref,
          item: item,
        ),
        // Long press → delete
        onLongPress: () => _confirmDelete(context),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${item.unit} · ${item.supplier ?? "Sin proveedor"}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            // Edit hint
            const Text(
              'Toca para editar · Mantén para eliminar',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${item.unitCost.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'por ${item.unit}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar insumo?'),
        content: Text(
          '¿Remover "${item.name}" de tu lista?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(supplyItemRepositoryProvider)
                  .deleteItem(item.id);
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

// ── ITEM FORM (Create & Edit) ─────────────────────────────
class _ItemForm extends StatefulWidget {
  final WidgetRef ref;
  final SupplyItem? item; // null = create, not null = edit

  const _ItemForm({required this.ref, required this.item});

  @override
  State<_ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends State<_ItemForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _unitController;
  late final TextEditingController _costController;
  late final TextEditingController _supplierController;

  // True if editing an existing item
  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    // Pre-fill fields if editing
    _nameController = TextEditingController(
      text: widget.item?.name ?? '',
    );
    _unitController = TextEditingController(
      text: widget.item?.unit ?? '',
    );
    _costController = TextEditingController(
      text: widget.item?.unitCost.toString() ?? '',
    );
    _supplierController = TextEditingController(
      text: widget.item?.supplier ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _costController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final repository = widget.ref.read(supplyItemRepositoryProvider);

    if (_isEditing) {
      // UPDATE existing item
      repository.updateItem(
        SupplyItemsCompanion(
          id: Value(widget.item!.id),
          name: Value(_nameController.text.trim()),
          unit: Value(_unitController.text.trim()),
          unitCost: Value(double.parse(_costController.text)),
          supplier: Value(
            _supplierController.text.trim().isEmpty
                ? null
                : _supplierController.text.trim(),
          ),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } else {
      // CREATE new item
      repository.addItem(
        SupplyItemsCompanion.insert(
          name: _nameController.text.trim(),
          unit: _unitController.text.trim(),
          unitCost: double.parse(_costController.text),
          supplier: Value(
            _supplierController.text.trim().isEmpty
                ? null
                : _supplierController.text.trim(),
          ),
        ),
      );
    }

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
            // Title changes based on mode
            Text(
              _isEditing ? 'Editar Insumo' : 'Nuevo Insumo',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del insumo *',
                hintText: 'ej. Tela de lino',
              ),
              validator: (v) => v == null || v.isEmpty
                  ? 'El nombre es obligatorio'
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                      labelText: 'Unidad *',
                      hintText: 'ej. metro',
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? 'Requerido'
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _costController,
                    decoration: const InputDecoration(
                      labelText: 'Costo por unidad *',
                      hintText: '0.00',
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
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _supplierController,
              decoration: const InputDecoration(
                labelText: 'Proveedor (opcional)',
                hintText: 'ej. Textiles García',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: Text(
                  _isEditing ? 'Guardar Cambios' : 'Guardar Insumo',
                ),
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}