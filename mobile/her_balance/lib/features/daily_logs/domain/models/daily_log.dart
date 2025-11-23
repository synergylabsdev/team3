import '../../../../core/enums/cycle_phase.dart';

class DailyLog {
  final String id;
  final String userId;
  final DateTime logDate;
  final CyclePhase? recordedPhase;
  final int stepCount;
  final bool workoutCompleted;
  final String? workoutNotes;
  final List<String> symptoms;
  final double? totalCalories;
  final double? totalProtein;
  final double? totalFat;
  final double? totalCarbs;
  final double? totalFiber;

  DailyLog({
    required this.id,
    required this.userId,
    required this.logDate,
    this.recordedPhase,
    required this.stepCount,
    required this.workoutCompleted,
    this.workoutNotes,
    required this.symptoms,
    this.totalCalories,
    this.totalProtein,
    this.totalFat,
    this.totalCarbs,
    this.totalFiber,
  });

  factory DailyLog.fromJson(Map<String, dynamic> json) {
    return DailyLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      logDate: DateTime.parse(json['log_date'] as String),
      recordedPhase: json['recorded_phase'] != null
          ? CyclePhase.fromString(json['recorded_phase'] as String)
          : null,
      stepCount: json['step_count'] as int? ?? 0,
      workoutCompleted: json['workout_completed'] as bool? ?? false,
      workoutNotes: json['workout_notes'] as String?,
      symptoms: (json['symptoms'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      totalCalories: (json['total_calories'] as num?)?.toDouble(),
      totalProtein: (json['total_protein'] as num?)?.toDouble(),
      totalFat: (json['total_fat'] as num?)?.toDouble(),
      totalCarbs: (json['total_carbs'] as num?)?.toDouble(),
      totalFiber: (json['total_fiber'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'log_date': logDate.toIso8601String().split('T')[0],
      'recorded_phase': recordedPhase?.toDbString(),
      'step_count': stepCount,
      'workout_completed': workoutCompleted,
      'workout_notes': workoutNotes,
      'symptoms': symptoms,
      'total_calories': totalCalories,
      'total_protein': totalProtein,
      'total_fat': totalFat,
      'total_carbs': totalCarbs,
      'total_fiber': totalFiber,
    };
  }
}

