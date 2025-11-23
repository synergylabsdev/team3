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
          .maybeSingle();

      if (response == null) return null;
      
      final data = response as Map<String, dynamic>;
      // Flatten recipe data
      if (data['recipe'] != null && (data['recipe'] as List).isNotEmpty) {
        data['recipe'] = (data['recipe'] as List).first;
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

      return (response as List).map((item) {
        final data = item as Map<String, dynamic>;
        // Flatten recipe data
        if (data['recipe'] != null && (data['recipe'] as List).isNotEmpty) {
          data['recipe'] = (data['recipe'] as List).first;
        }
        return MealPlan.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error fetching meals for date: $e');
      return [];
    }
  }
}
