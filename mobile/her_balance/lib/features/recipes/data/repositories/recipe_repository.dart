import '../../domain/models/recipe.dart';
import '../../../../core/database/supabase_client.dart';
import '../../../../core/enums/cycle_phase.dart';

class RecipeRepository {
  /// Get all recipes with optional filters
  Future<List<Recipe>> getRecipes({
    String? searchQuery,
    CyclePhase? phaseFilter,
    String? mealTypeFilter,
    bool? favoritesOnly,
  }) async {
    final userId = SupabaseClient.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      var query = SupabaseClient.from('recipes')
          .select()
          .eq('is_public', true)
          .or('created_by.is.null,created_by.eq.$userId');

      // Apply search filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('title', '%$searchQuery%');
      }

      // Apply phase filter
      if (phaseFilter != null) {
        query = query.contains('phase_tags', [phaseFilter.toDbString()]);
      }

      // Apply meal type filter
      if (mealTypeFilter != null && mealTypeFilter.isNotEmpty) {
        query = query.eq('meal_type', mealTypeFilter);
      }

      final response = await query.order('created_at', ascending: false);

      if (response.isEmpty) return [];

      final recipes = (response as List).map((item) {
        return Recipe.fromJson(item as Map<String, dynamic>);
      }).toList();

      // Get user's favorite recipe IDs
      final favoriteIds = await _getFavoriteRecipeIds(userId);

      // Mark favorites
      for (var i = 0; i < recipes.length; i++) {
        recipes[i].isFavorite = favoriteIds.contains(recipes[i].id);
      }

      // Filter by favorites if requested
      if (favoritesOnly == true) {
        return recipes.where((r) => r.isFavorite).toList();
      }

      return recipes;
    } catch (e) {
      print('Error fetching recipes: $e');
      return [];
    }
  }

  /// Get a single recipe by ID
  Future<Recipe?> getRecipeById(String recipeId) async {
    final userId = SupabaseClient.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await SupabaseClient.from('recipes')
          .select()
          .eq('id', recipeId)
          .eq('is_public', true)
          .or('created_by.is.null,created_by.eq.$userId')
          .maybeSingle();

      if (response == null) return null;

      final recipe = Recipe.fromJson(response as Map<String, dynamic>);
      
      // Check if favorite
      final favoriteIds = await _getFavoriteRecipeIds(userId);
      recipe.isFavorite = favoriteIds.contains(recipe.id);
      return recipe;
    } catch (e) {
      print('Error fetching recipe: $e');
      return null;
    }
  }

  /// Get user's favorite recipe IDs
  Future<Set<String>> _getFavoriteRecipeIds(String userId) async {
    try {
      final response = await SupabaseClient.from('favorite_recipes')
          .select('recipe_id')
          .eq('user_id', userId);

      if (response.isEmpty) return {};

      return (response as List<dynamic>)
          .map((item) => (item as Map<String, dynamic>)['recipe_id'] as String)
          .toSet();
    } catch (e) {
      print('Error fetching favorite recipe IDs: $e');
      return {};
    }
  }

  /// Toggle favorite status for a recipe
  Future<bool> toggleFavorite(String recipeId) async {
    final userId = SupabaseClient.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      // Check if already favorite
      final existing = await SupabaseClient.from('favorite_recipes')
          .select()
          .eq('user_id', userId)
          .eq('recipe_id', recipeId)
          .maybeSingle();

      if (existing != null) {
        // Remove from favorites
        await SupabaseClient.from('favorite_recipes')
            .delete()
            .eq('user_id', userId)
            .eq('recipe_id', recipeId);
        return false;
      } else {
        // Add to favorites
        await SupabaseClient.from('favorite_recipes').insert({
          'user_id': userId,
          'recipe_id': recipeId,
        });
        return true;
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      return false;
    }
  }

  /// Check if recipe is favorite
  Future<bool> isFavorite(String recipeId) async {
    final userId = SupabaseClient.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final response = await SupabaseClient.from('favorite_recipes')
          .select()
          .eq('user_id', userId)
          .eq('recipe_id', recipeId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking favorite: $e');
      return false;
    }
  }
}

