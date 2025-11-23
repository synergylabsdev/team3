import '../../domain/models/meal_plan.dart';
import '../../../../core/database/supabase_client.dart';

class MealPlanRepository {
  Future<MealPlan?> getTodayMeal(String mealType) async {
    final userId = SupabaseClient.auth.currentUser?.id;
    if (userId == null) return null;

    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];

    try {
      final response = await SupabaseClient.from('meal_plans')
          .select('''
            *,
            recipe:recipes(*)
          ''')
          .eq('user_id', userId)
          .eq('planned_date', todayStr)
          .eq('meal_type', mealType)
          .limit(1);

      if (response.isEmpty) return null;

      final responseList = response as List<dynamic>;
      if (responseList.isEmpty) return null;

      final data = responseList.first as Map<String, dynamic>;
      // Flatten recipe data - handle both List and Map
      if (data['recipe'] != null) {
        if (data['recipe'] is List) {
          final recipeList = data['recipe'] as List;
          if (recipeList.isNotEmpty) {
            data['recipe'] = recipeList.first;
          } else {
            data['recipe'] = null;
          }
        } else if (data['recipe'] is Map) {
          // Already a Map, keep it as is
          data['recipe'] = data['recipe'];
        }
      }
      return MealPlan.fromJson(data);
    } catch (e) {
      print('Error fetching today meal: $e');
      return null;
    }
  }

  /// Get all meals for a specific date
  Future<List<MealPlan>> getMealsForDate(DateTime date) async {
    final userId = SupabaseClient.auth.currentUser?.id;
    if (userId == null) return [];

    final dateStr = date.toIso8601String().split('T')[0];

    try {
      final response = await SupabaseClient.from('meal_plans')
          .select('''
            *,
            recipe:recipes(*)
          ''')
          .eq('user_id', userId)
          .eq('planned_date', dateStr);

      if (response.isEmpty) return [];

      final responseList = response as List<dynamic>;
      return responseList.map((item) {
        final data = item as Map<String, dynamic>;
        // Flatten recipe data - handle both List and Map
        if (data['recipe'] != null) {
          if (data['recipe'] is List) {
            final recipeList = data['recipe'] as List;
            if (recipeList.isNotEmpty) {
              data['recipe'] = recipeList.first;
            } else {
              data['recipe'] = null;
            }
          } else if (data['recipe'] is Map) {
            // Already a Map, keep it as is
            data['recipe'] = data['recipe'];
          }
        }
        return MealPlan.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error fetching meals for date: $e');
      return [];
    }
  }

  /// Add a recipe to meal plan
  Future<MealPlan?> addMealPlan({
    required String recipeId,
    required DateTime plannedDate,
    required String mealType,
  }) async {
    final userId = SupabaseClient.auth.currentUser?.id;
    if (userId == null) return null;

    final dateStr = plannedDate.toIso8601String().split('T')[0];

    try {
      final response = await SupabaseClient.from('meal_plans')
          .insert({
            'user_id': userId,
            'recipe_id': recipeId,
            'planned_date': dateStr,
            'meal_type': mealType,
            'is_completed': false,
          })
          .select('''
            *,
            recipe:recipes(*)
          ''')
          .single();

      final data = response as Map<String, dynamic>;
      // Flatten recipe data - handle both List and Map
      if (data['recipe'] != null) {
        if (data['recipe'] is List) {
          final recipeList = data['recipe'] as List;
          if (recipeList.isNotEmpty) {
            data['recipe'] = recipeList.first;
          } else {
            data['recipe'] = null;
          }
        } else if (data['recipe'] is Map) {
          // Already a Map, keep it as is
          data['recipe'] = data['recipe'];
        }
      }
      return MealPlan.fromJson(data);
    } catch (e) {
      print('Error adding meal plan: $e');
      return null;
    }
  }

  /// Remove a meal plan
  Future<bool> removeMealPlan(String mealPlanId) async {
    final userId = SupabaseClient.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await SupabaseClient.from(
        'meal_plans',
      ).delete().eq('id', mealPlanId).eq('user_id', userId);
      return true;
    } catch (e) {
      print('Error removing meal plan: $e');
      return false;
    }
  }

  /// Mark meal as completed
  Future<bool> markMealCompleted(String mealPlanId, bool isCompleted) async {
    final userId = SupabaseClient.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await SupabaseClient.from('meal_plans')
          .update({'is_completed': isCompleted})
          .eq('id', mealPlanId)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      print('Error marking meal completed: $e');
      return false;
    }
  }

  /// Get meals for a specific date and meal type
  Future<List<MealPlan>> getMealsForDateAndType(
    DateTime date,
    String mealType,
  ) async {
    final userId = SupabaseClient.auth.currentUser?.id;
    if (userId == null) return [];

    final dateStr = date.toIso8601String().split('T')[0];

    try {
      final response = await SupabaseClient.from('meal_plans')
          .select('''
            *,
            recipe:recipes(*)
          ''')
          .eq('user_id', userId)
          .eq('planned_date', dateStr)
          .eq('meal_type', mealType);

      if (response.isEmpty) return [];

      final responseList = response as List<dynamic>;
      return responseList.map((item) {
        final data = item as Map<String, dynamic>;
        // Flatten recipe data - handle both List and Map
        if (data['recipe'] != null) {
          if (data['recipe'] is List) {
            final recipeList = data['recipe'] as List;
            if (recipeList.isNotEmpty) {
              data['recipe'] = recipeList.first;
            } else {
              data['recipe'] = null;
            }
          } else if (data['recipe'] is Map) {
            // Already a Map, keep it as is
            data['recipe'] = data['recipe'];
          }
        }
        return MealPlan.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error fetching meals for date and type: $e');
      return [];
    }
  }
}
