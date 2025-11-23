import '../../domain/models/workout_plan.dart';
import '../../../../core/database/supabase_client.dart';

class WorkoutPlanRepository {
  /// Get workout plan for a specific date
  Future<WorkoutPlan?> getWorkoutForDate(DateTime date) async {
    final userId = SupabaseClient.auth.currentUser?.id;
    if (userId == null) return null;

    final dateStr = date.toIso8601String().split('T')[0];

    try {
      final response = await SupabaseClient.from('workout_plans')
          .select()
          .eq('user_id', userId)
          .eq('planned_date', dateStr)
          .maybeSingle();

      if (response == null) return null;
      return WorkoutPlan.fromJson(response);
    } catch (e) {
      print('Error fetching workout for date: $e');
      return null;
    }
  }

  /// Get workout plans for a date range (week)
  Future<List<WorkoutPlan>> getWorkoutsForWeek(DateTime weekStart) async {
    final userId = SupabaseClient.auth.currentUser?.id;
    if (userId == null) return [];

    final weekEnd = weekStart.add(const Duration(days: 6));
    final startStr = weekStart.toIso8601String().split('T')[0];
    final endStr = weekEnd.toIso8601String().split('T')[0];

    try {
      final response = await SupabaseClient.from('workout_plans')
          .select()
          .eq('user_id', userId)
          .gte('planned_date', startStr)
          .lte('planned_date', endStr)
          .order('planned_date');

      if (response.isEmpty) return [];

      final responseList = response;
      return responseList
          .map((item) => WorkoutPlan.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching workouts for week: $e');
      return [];
    }
  }

  /// Upsert workout plan for a date
  Future<WorkoutPlan> upsertWorkoutPlan({
    required DateTime plannedDate,
    String? activity,
    int? durationMinutes,
    String? videoLink,
    bool isRestDay = false,
  }) async {
    final userId = SupabaseClient.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final dateStr = plannedDate.toIso8601String().split('T')[0];

    final data = <String, dynamic>{
      'user_id': userId,
      'planned_date': dateStr,
      'activity': activity,
      'duration_minutes': durationMinutes,
      'video_link': videoLink,
      'is_rest_day': isRestDay,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      final response = await SupabaseClient.from('workout_plans')
          .upsert(data, onConflict: 'user_id,planned_date')
          .select()
          .single();

      return WorkoutPlan.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error upserting workout plan: $e');
      rethrow;
    }
  }

  /// Mark workout as completed
  Future<bool> markWorkoutCompleted(String workoutPlanId, bool isCompleted) async {
    final userId = SupabaseClient.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await SupabaseClient.from('workout_plans')
          .update({
            'is_completed': isCompleted,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', workoutPlanId)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      print('Error marking workout completed: $e');
      return false;
    }
  }

  /// Delete workout plan
  Future<bool> deleteWorkoutPlan(String workoutPlanId) async {
    final userId = SupabaseClient.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await SupabaseClient.from('workout_plans')
          .delete()
          .eq('id', workoutPlanId)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      print('Error deleting workout plan: $e');
      return false;
    }
  }

  /// Save multiple workout plans for a week
  Future<void> saveWeekWorkoutPlans(List<WorkoutPlan> plans) async {
    final userId = SupabaseClient.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    try {
      // Delete existing plans for the week dates
      if (plans.isNotEmpty) {
        final dates = plans.map((p) => p.plannedDate.toIso8601String().split('T')[0]).toList();
        for (final date in dates) {
          await SupabaseClient.from('workout_plans')
              .delete()
              .eq('user_id', userId)
              .eq('planned_date', date);
        }
      }

      // Insert new plans
      final dataList = plans.map((plan) => {
        'user_id': userId,
        'planned_date': plan.plannedDate.toIso8601String().split('T')[0],
        'activity': plan.activity,
        'duration_minutes': plan.durationMinutes,
        'video_link': plan.videoLink,
        'is_rest_day': plan.isRestDay,
        'is_completed': false,
      }).toList();

      if (dataList.isNotEmpty) {
        await SupabaseClient.from('workout_plans').insert(dataList);
      }
    } catch (e) {
      print('Error saving week workout plans: $e');
      rethrow;
    }
  }
}

