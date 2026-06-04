import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brand_dashboard/core/database/app_database.dart';
import 'package:brand_dashboard/core/database/database_provider.dart';
import 'package:brand_dashboard/features/costs/data/repositories/recipe_repository.dart';
import 'package:brand_dashboard/features/products/presentation/providers/supply_item_provider.dart';

/// Provides the RecipeRepository instance.
final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return RecipeRepository(database);
});

/// Streams all saved recipes in real time.
final recipesProvider = StreamProvider<List<ProductRecipe>>((ref) {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.watchAllRecipes();
});

/// Data class that holds a recipe with its calculated margins.
class RecipeWithMargin {
  final ProductRecipe recipe;
  final List<RecipeItemDetail> items;
  final double totalSupplyCost;
  final double totalCost;
  final double profit;
  final double marginPercent;

  const RecipeWithMargin({
    required this.recipe,
    required this.items,
    required this.totalSupplyCost,
    required this.totalCost,
    required this.profit,
    required this.marginPercent,
  });
}

/// Holds a recipe item with its supply item details.
class RecipeItemDetail {
  final RecipeItem item;
  final SupplyItem supplyItem;
  final double subtotal;

  const RecipeItemDetail({
    required this.item,
    required this.supplyItem,
    required this.subtotal,
  });
}

/// Loads a specific recipe with full margin calculation.
final recipeWithMarginProvider =
    FutureProvider.family<RecipeWithMargin, int>((ref, recipeId) async {
  final repository = ref.watch(recipeRepositoryProvider);
  final allSupplyItems = await ref.watch(
    supplyItemsProvider.future,
  );

  final recipes = await repository.watchAllRecipes().first;
  final recipe = recipes.firstWhere((r) => r.id == recipeId);
  final items = await repository.getRecipeItems(recipeId);

  // Build detailed items with subtotals
  final detailedItems = items.map((item) {
    final supplyItem = allSupplyItems.firstWhere(
      (s) => s.id == item.supplyItemId,
    );
    return RecipeItemDetail(
      item: item,
      supplyItem: supplyItem,
      subtotal: supplyItem.unitCost * item.quantity,
    );
  }).toList();

  // Calculate totals
  final totalSupplyCost = detailedItems.fold<double>(
    0.0,
    (sum, d) => sum + d.subtotal,
  );
  final totalCost = totalSupplyCost +
      recipe.laborCost +
      recipe.packagingCost +
      recipe.otherCosts;
  final profit = recipe.salePrice - totalCost;
  final marginPercent = recipe.salePrice > 0
      ? (profit / recipe.salePrice) * 100
      : 0.0;

  return RecipeWithMargin(
    recipe: recipe,
    items: detailedItems,
    totalSupplyCost: totalSupplyCost,
    totalCost: totalCost,
    profit: profit,
    marginPercent: marginPercent,
  );
});