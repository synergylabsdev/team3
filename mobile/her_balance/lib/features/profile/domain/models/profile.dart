class Profile {
  final String id;
  final String? email;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPremium;
  final String? subscriptionStatus;
  final String? subscriptionPlanId;
  final int avgCycleLength;
  final int avgPeriodLength;
  final DateTime? lastPeriodStart;
  final bool lunarSyncEnabled;
  final String measurementUnit;
  final bool showBibleVerses;
  final Map<String, dynamic> notificationPreferences;

  Profile({
    required this.id,
    this.email,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    required this.isPremium,
    this.subscriptionStatus,
    this.subscriptionPlanId,
    required this.avgCycleLength,
    required this.avgPeriodLength,
    this.lastPeriodStart,
    required this.lunarSyncEnabled,
    required this.measurementUnit,
    required this.showBibleVerses,
    required this.notificationPreferences,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'user',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isPremium: json['is_premium'] as bool? ?? false,
      subscriptionStatus: json['subscription_status'] as String?,
      subscriptionPlanId: json['subscription_plan_id'] as String?,
      avgCycleLength: json['avg_cycle_length'] as int? ?? 28,
      avgPeriodLength: json['avg_period_length'] as int? ?? 7,
      lastPeriodStart: json['last_period_start'] != null
          ? DateTime.parse(json['last_period_start'] as String)
          : null,
      lunarSyncEnabled: json['lunar_sync_enabled'] as bool? ?? false,
      measurementUnit: json['measurement_unit'] as String? ?? 'US',
      showBibleVerses: json['show_bible_verses'] as bool? ?? false,
      notificationPreferences:
          json['notification_preferences'] as Map<String, dynamic>? ??
              {'phase_change': true, 'meal_reminders': true, 'log_reminders': true},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_premium': isPremium,
      'subscription_status': subscriptionStatus,
      'subscription_plan_id': subscriptionPlanId,
      'avg_cycle_length': avgCycleLength,
      'avg_period_length': avgPeriodLength,
      'last_period_start': lastPeriodStart?.toIso8601String(),
      'lunar_sync_enabled': lunarSyncEnabled,
      'measurement_unit': measurementUnit,
      'show_bible_verses': showBibleVerses,
      'notification_preferences': notificationPreferences,
    };
  }
}

