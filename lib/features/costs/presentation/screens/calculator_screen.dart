import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brand_dashboard/core/database/app_database.dart';
import 'package:brand_dashboard/features/costs/presentation/providers/recipe_provider.dart';
import 'recipe_detail_screen.dart';

/// Screen that lists all saved product recipes.
class CalculatorScreen extends ConsumerWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora'),
      ),
      body: recipesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Text('Error: $error'),
        ),
        data: (recipes) => recipes.isEmpty
            ? const _EmptyState()
            : _RecipesList(recipes: recipes),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecipeForm(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddRecipeForm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddRecipeForm(ref: ref),
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
          Icon(Icons.calculate_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Sin recetas guardadas',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Toca + para crear tu primera receta',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── RECIPES LIST ──────────────────────────────────────────
class _RecipesList extends ConsumerWidget {
  final List<ProductRecipe> recipes;
  const _RecipesList({required this.recipes});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        return _RecipeCard(recipe: recipes[index], ref: ref);
      },
    );
  }
}

// ── RECIPE CARD ───────────────────────────────────────────
class _RecipeCard extends ConsumerWidget {
  final ProductRecipe recipe;
  final WidgetRef ref;
  const _RecipeCard({required this.recipe, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marginAsync = ref.watch(recipeWithMarginProvider(recipe.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
          ),
        ),
        onLongPress: () => _confirmDelete(context, ref),
        leading: const CircleAvatar(
          child: Icon(Icons.calculate),
        ),
        title: Text(
          recipe.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Venta: \$${recipe.salePrice.toStringAsFixed(2)}',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: marginAsync.when(
          loading: () => const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (_, __) => const Icon(Icons.error, color: Colors.red),
          data: (data) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${data.marginPercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _marginColor(data.marginPercent),
                ),
              ),
              Text(
                'margen',
                style: TextStyle(
                  color: _marginColor(data.marginPercent),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _marginColor(double margin) {
    if (margin >= 30) return Colors.green;
    if (margin >= 15) return Colors.orange;
    return Colors.red;
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar receta?'),
        content: Text('¿Eliminar la receta "${recipe.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(recipeRepositoryProvider)
                  .deleteRecipe(recipe.id);
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

// ── ADD RECIPE FORM ───────────────────────────────────────
class _AddRecipeForm extends StatefulWidget {
  final WidgetRef ref;
  const _AddRecipeForm({required this.ref});

  @override
  State<_AddRecipeForm> createState() => _AddRecipeFormState();
}

class _AddRecipeFormState extends State<_AddRecipeForm> {
  final _nameController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _salePriceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    widget.ref.read(recipeRepositoryProvider).addRecipe(
          ProductRecipesCompanion.insert(
            name: _nameController.text.trim(),
            salePrice: double.parse(_salePriceController.text),
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
              'Nueva Receta',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la receta *',
                hintText: 'ej. Playera Oversize Blanca',
              ),
              validator: (v) => v == null || v.isEmpty
                  ? 'El nombre es obligatorio'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _salePriceController,
              decoration: const InputDecoration(
                labelText: 'Precio de venta *',
                hintText: '0.00',
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requerido';
                if (double.tryParse(v) == null) return 'Número inválido';
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Crear Receta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}