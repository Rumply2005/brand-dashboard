import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:brand_dashboard/core/database/app_database.dart';
import 'package:brand_dashboard/features/costs/presentation/providers/recipe_provider.dart';
import 'package:brand_dashboard/features/products/presentation/providers/supply_item_provider.dart';

/// Screen that shows full recipe detail with margin calculation.
class RecipeDetailScreen extends ConsumerWidget {
  final int recipeId;
  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeAsync = ref.watch(recipeWithMarginProvider(recipeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Receta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(
              recipeWithMarginProvider(recipeId),
            ),
          ),
        ],
      ),
      body: recipeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Margin Result Card ──
            _MarginResultCard(data: data),
            const SizedBox(height: 24),

            // ── Cost Breakdown ──
            const _SectionTitle(title: 'Desglose de Costos'),
            const SizedBox(height: 12),
            _CostBreakdownCard(data: data, ref: ref),
            const SizedBox(height: 24),

            // ── Supply Items ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionTitle(title: 'Insumos'),
                TextButton.icon(
                  onPressed: () => _showAddItemDialog(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Agregar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (data.items.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Sin insumos agregados',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ...data.items.map((item) => _SupplyItemRow(
                    detail: item,
                    recipeId: recipeId,
                    ref: ref,
                  )),
            const SizedBox(height: 24),

            // ── Fixed Costs ──
            const _SectionTitle(title: 'Costos Fijos'),
            const SizedBox(height: 12),
            _FixedCostsCard(data: data, ref: ref),
          ],
        ),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddSupplyItemForm(ref: ref, recipeId: recipeId),
    );
  }
}

// ── MARGIN RESULT CARD ────────────────────────────────────
class _MarginResultCard extends StatelessWidget {
  final RecipeWithMargin data;
  const _MarginResultCard({required this.data});

  Color get _marginColor {
    if (data.marginPercent >= 30) return Colors.green;
    if (data.marginPercent >= 15) return Colors.orange;
    return Colors.red;
  }

  String get _marginLabel {
    if (data.marginPercent >= 30) return '✅ Excelente';
    if (data.marginPercent >= 15) return '⚠️ Aceptable';
    return '❌ Bajo';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              data.recipe.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ResultItem(
                  label: 'Precio venta',
                  value: '\$${data.recipe.salePrice.toStringAsFixed(2)}',
                  color: Colors.blue,
                ),
                _ResultItem(
                  label: 'Costo total',
                  value: '\$${data.totalCost.toStringAsFixed(2)}',
                  color: Colors.orange,
                ),
                _ResultItem(
                  label: 'Ganancia',
                  value: '\$${data.profit.toStringAsFixed(2)}',
                  color: _marginColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: _marginColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${data.marginPercent.toStringAsFixed(1)}% margen',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _marginColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _marginLabel,
                    style: TextStyle(
                      color: _marginColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── RESULT ITEM ───────────────────────────────────────────
class _ResultItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ResultItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 11),
        ),
      ],
    );
  }
}

// ── SECTION TITLE ─────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// ── COST BREAKDOWN CARD ───────────────────────────────────
class _CostBreakdownCard extends StatelessWidget {
  final RecipeWithMargin data;
  final WidgetRef ref;
  const _CostBreakdownCard({required this.data, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _CostRow(
              label: 'Insumos',
              value: data.totalSupplyCost,
              color: Colors.blue,
            ),
            _CostRow(
              label: 'Mano de obra',
              value: data.recipe.laborCost,
              color: Colors.purple,
            ),
            _CostRow(
              label: 'Empaque',
              value: data.recipe.packagingCost,
              color: Colors.teal,
            ),
            _CostRow(
              label: 'Otros costos',
              value: data.recipe.otherCosts,
              color: Colors.grey,
            ),
            const Divider(),
            _CostRow(
              label: 'TOTAL',
              value: data.totalCost,
              color: Colors.orange,
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}

// ── COST ROW ──────────────────────────────────────────────
class _CostRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool bold;
  const _CostRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ── SUPPLY ITEM ROW ───────────────────────────────────────
class _SupplyItemRow extends ConsumerWidget {
  final RecipeItemDetail detail;
  final int recipeId;
  final WidgetRef ref;
  const _SupplyItemRow({
    required this.detail,
    required this.recipeId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        title: Text(
          detail.supplyItem.name,
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: Text(
          '${detail.item.quantity} ${detail.supplyItem.unit} × '
          '\$${detail.supplyItem.unitCost.toStringAsFixed(2)}',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${detail.subtotal.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _deleteItem(ref),
              child: const Icon(
                Icons.close,
                color: Colors.red,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteItem(WidgetRef ref) {
    ref.read(recipeRepositoryProvider).saveRecipeItems(
      recipeId,
      [], // handled differently — just delete this one item
    );
    // Delete only this item via repository
    ref.read(recipeRepositoryProvider).deleteRecipeItem(detail.item.id);
    ref.invalidate(recipeWithMarginProvider(recipeId));
  }
}

// ── FIXED COSTS CARD ──────────────────────────────────────
class _FixedCostsCard extends ConsumerWidget {
  final RecipeWithMargin data;
  final WidgetRef ref;
  const _FixedCostsCard({required this.data, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _EditableCostRow(
              label: 'Mano de obra',
              value: data.recipe.laborCost,
              onSave: (value) => _updateCost(ref, laborCost: value),
            ),
            const SizedBox(height: 12),
            _EditableCostRow(
              label: 'Empaque',
              value: data.recipe.packagingCost,
              onSave: (value) => _updateCost(ref, packagingCost: value),
            ),
            const SizedBox(height: 12),
            _EditableCostRow(
              label: 'Otros costos',
              value: data.recipe.otherCosts,
              onSave: (value) => _updateCost(ref, otherCosts: value),
            ),
          ],
        ),
      ),
    );
  }

  void _updateCost(
    WidgetRef ref, {
    double? laborCost,
    double? packagingCost,
    double? otherCosts,
  }) {
    ref.read(recipeRepositoryProvider).updateRecipe(
          ProductRecipesCompanion(
            id: Value(data.recipe.id),
            laborCost: laborCost != null
                ? Value(laborCost)
                : const Value.absent(),
            packagingCost: packagingCost != null
                ? Value(packagingCost)
                : const Value.absent(),
            otherCosts: otherCosts != null
                ? Value(otherCosts)
                : const Value.absent(),
            updatedAt: Value(DateTime.now()),
          ),
        );
    ref.invalidate(recipeWithMarginProvider(data.recipe.id));
  }
}

// ── EDITABLE COST ROW ─────────────────────────────────────
class _EditableCostRow extends StatefulWidget {
  final String label;
  final double value;
  final Function(double) onSave;
  const _EditableCostRow({
    required this.label,
    required this.value,
    required this.onSave,
  });

  @override
  State<_EditableCostRow> createState() => _EditableCostRowState();
}

class _EditableCostRowState extends State<_EditableCostRow> {
  late TextEditingController _controller;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(widget.label),
        _editing
            ? SizedBox(
                width: 120,
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(
                    prefixText: '\$ ',
                    isDense: true,
                  ),
                  onSubmitted: (value) {
                    final parsed = double.tryParse(value);
                    if (parsed != null) widget.onSave(parsed);
                    setState(() => _editing = false);
                  },
                ),
              )
            : GestureDetector(
                onTap: () => setState(() => _editing = true),
                child: Row(
                  children: [
                    Text(
                      '\$${widget.value.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit, size: 14, color: Colors.grey),
                  ],
                ),
              ),
      ],
    );
  }
}

// ── ADD SUPPLY ITEM FORM ──────────────────────────────────
class _AddSupplyItemForm extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final int recipeId;
  const _AddSupplyItemForm({
    required this.ref,
    required this.recipeId,
  });

  @override
  ConsumerState<_AddSupplyItemForm> createState() =>
      _AddSupplyItemFormState();
}

class _AddSupplyItemFormState extends ConsumerState<_AddSupplyItemForm> {
  int? _selectedSupplyItemId;
  final _quantityController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedSupplyItemId == null) return;
    final quantity = double.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) return;

    ref.read(recipeRepositoryProvider).addRecipeItem(
          RecipeItemsCompanion.insert(
            recipeId: widget.recipeId,
            supplyItemId: _selectedSupplyItemId!,
            quantity: quantity,
          ),
        );

    ref.invalidate(recipeWithMarginProvider(widget.recipeId));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final supplyItemsAsync = ref.watch(supplyItemsProvider);

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
            'Agregar Insumo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          supplyItemsAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('Error'),
            data: (items) => DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Selecciona un insumo',
              ),
              items: items
                  .map((item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(
                          '${item.name} — \$${item.unitCost}/${item.unit}',
                        ),
                      ))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _selectedSupplyItemId = value),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _quantityController,
            decoration: const InputDecoration(
              labelText: 'Cantidad *',
              hintText: 'ej. 2.5',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: const Text('Agregar a Receta'),
            ),
          ),
        ],
      ),
    );
  }
}