import 'package:drift/drift.dart';
import 'package:brand_dashboard/core/database/app_database.dart';

/// Repository that handles all CRUD operations for ProductRecipes.
class RecipeRepository {
  final AppDatabase _db;
  const RecipeRepository(this._db);

  // ── RECIPES — READ ─────────────────────────────────────
  Stream<List<ProductRecipe>> watchAllRecipes() {
    return (_db.select(_db.productRecipes)
          ..orderBy([(r) => OrderingTerm.desc(r.updatedAt)]))
        .watch();
  }

  // ── RECIPES — CREATE ───────────────────────────────────
  Future<int> addRecipe(ProductRecipesCompanion recipe) {
    return _db.into(_db.productRecipes).insert(recipe);
  }

  // ── RECIPES — UPDATE ───────────────────────────────────
  Future<void> updateRecipe(ProductRecipesCompanion recipe) {
    return (_db.update(_db.productRecipes)
          ..where((r) => r.id.equals(recipe.id.value)))
        .write(recipe);
  }

  // ── RECIPES — DELETE ───────────────────────────────────
  Future<void> deleteRecipe(int recipeId) async {
    await (_db.delete(_db.recipeItems)
          ..where((i) => i.recipeId.equals(recipeId)))
        .go();
    await (_db.delete(_db.productRecipes)
          ..where((r) => r.id.equals(recipeId)))
        .go();
  }

  // ── RECIPE ITEMS — READ ────────────────────────────────
  Future<List<RecipeItem>> getRecipeItems(int recipeId) {
    return (_db.select(_db.recipeItems)
          ..where((i) => i.recipeId.equals(recipeId)))
        .get();
  }

  // ── RECIPE ITEMS — SAVE ────────────────────────────────
  /// Replaces all items of a recipe with a new list.
  Future<void> saveRecipeItems(
    int recipeId,
    List<RecipeItemsCompanion> items,
  ) async {
    // Delete existing items
    await (_db.delete(_db.recipeItems)
          ..where((i) => i.recipeId.equals(recipeId)))
        .go();
    // Insert new items
    for (final item in items) {
      await _db.into(_db.recipeItems).insert(item);
    }
  }
  // ── RECIPE ITEMS — ADD ─────────────────────────────────
  Future<void> addRecipeItem(RecipeItemsCompanion item) {
    return _db.into(_db.recipeItems).insert(item);
  }

  // ── RECIPE ITEMS — DELETE ONE ──────────────────────────
  Future<void> deleteRecipeItem(int itemId) {
    return (_db.delete(_db.recipeItems)
          ..where((i) => i.id.equals(itemId)))
        .go();
  }
}