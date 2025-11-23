class Cycle {
  final String id;
  final String userId;
  final DateTime startDate;
  final DateTime? endDate;
  final int? cycleLengthDays;
  final DateTime createdAt;

  Cycle({
    required this.id,
    required this.userId,
    required this.startDate,
    this.endDate,
    this.cycleLengthDays,
    required this.createdAt,
  });

  factory Cycle.fromJson(Map<String, dynamic> json) {
    return Cycle(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      cycleLengthDays: json['cycle_length_days'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'cycle_length_days': cycleLengthDays,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isActive => endDate == null;
}

