class WorkoutPlan {
  final String id;
  final String userId;
  final DateTime plannedDate;
  final String? activity;
  final int? durationMinutes;
  final String? videoLink;
  final bool isRestDay;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkoutPlan({
    required this.id,
    required this.userId,
    required this.plannedDate,
    this.activity,
    this.durationMinutes,
    this.videoLink,
    required this.isRestDay,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      plannedDate: DateTime.parse(json['planned_date'] as String),
      activity: json['activity'] as String?,
      durationMinutes: json['duration_minutes'] as int?,
      videoLink: json['video_link'] as String?,
      isRestDay: json['is_rest_day'] as bool? ?? false,
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'planned_date': plannedDate.toIso8601String().split('T')[0],
      'activity': activity,
      'duration_minutes': durationMinutes,
      'video_link': videoLink,
      'is_rest_day': isRestDay,
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

