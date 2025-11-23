import '../../domain/models/daily_log.dart';
import '../../../../core/database/supabase_client.dart';
import '../../../../core/enums/cycle_phase.dart';

class DailyLogRepository {
  Future<DailyLog?> getTodayLog() async {
    final userId = SupabaseClient.auth.currentUser?.id;
    if (userId == null) return null;

    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];

    try {
      final response = await SupabaseClient.from('daily_logs')
          .select()
          .eq('user_id', userId)
          .eq('log_date', todayStr)
          .maybeSingle();

      if (response == null) return null;
      return DailyLog.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching today log: $e');
      return null;
    }
  }

  Future<DailyLog> upsertDailyLog({
    required DateTime logDate,
    CyclePhase? recordedPhase,
    int? stepCount,
    bool? workoutCompleted,
    String? workoutNotes,
    List<String>? symptoms,
    double? totalCalories,
    double? totalProtein,
    double? totalFat,
    double? totalCarbs,
    double? totalFiber,
  }) async {
    final userId = SupabaseClient.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final logDateStr = logDate.toIso8601String().split('T')[0];

    final data = <String, dynamic>{
      'user_id': userId,
      'log_date': logDateStr,
    };

    if (recordedPhase != null) {
      data['recorded_phase'] = recordedPhase.toDbString();
    }
    if (stepCount != null) {
      data['step_count'] = stepCount;
    }
    if (workoutCompleted != null) {
      data['workout_completed'] = workoutCompleted;
    }
    if (workoutNotes != null) {
      data['workout_notes'] = workoutNotes;
    }
    if (symptoms != null) {
      data['symptoms'] = symptoms;
    }
    if (totalCalories != null) {
      data['total_calories'] = totalCalories;
    }
    if (totalProtein != null) {
      data['total_protein'] = totalProtein;
    }
    if (totalFat != null) {
      data['total_fat'] = totalFat;
    }
    if (totalCarbs != null) {
      data['total_carbs'] = totalCarbs;
    }
    if (totalFiber != null) {
      data['total_fiber'] = totalFiber;
    }

    final response = await SupabaseClient.from('daily_logs')
        .upsert(data, onConflict: 'user_id,log_date')
        .select()
        .single();

    return DailyLog.fromJson(response as Map<String, dynamic>);
  }

  Future<void> updateSymptoms(DateTime logDate, List<String> symptoms) async {
    await upsertDailyLog(
      logDate: logDate,
      symptoms: symptoms,
    );
  }

  /// Calculates and updates daily nutrition totals from completed meal plans
  /// This method accepts nutrition totals calculated externally to avoid circular dependencies
  Future<void> updateNutritionTotals({
    required DateTime logDate,
    double? totalCalories,
    double? totalProtein,
    double? totalFat,
    double? totalCarbs,
    double? totalFiber,
  }) async {
    await upsertDailyLog(
      logDate: logDate,
      totalCalories: totalCalories,
      totalProtein: totalProtein,
      totalFat: totalFat,
      totalCarbs: totalCarbs,
      totalFiber: totalFiber,
    );
  }
}
