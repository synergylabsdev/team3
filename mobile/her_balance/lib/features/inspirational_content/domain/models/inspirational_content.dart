import '../../../../core/enums/cycle_phase.dart';

class InspirationalContent {
  final String id;
  final String contentText;
  final String? sourceReference;
  final String contentType; // 'bible_verse' or 'wellness_tip'
  final CyclePhase? targetPhase;
  final bool isActive;
  final DateTime createdAt;

  InspirationalContent({
    required this.id,
    required this.contentText,
    this.sourceReference,
    required this.contentType,
    this.targetPhase,
    required this.isActive,
    required this.createdAt,
  });

  factory InspirationalContent.fromJson(Map<String, dynamic> json) {
    return InspirationalContent(
      id: json['id'] as String,
      contentText: json['content_text'] as String,
      sourceReference: json['source_reference'] as String?,
      contentType: json['content_type'] as String,
      targetPhase: json['target_phase'] != null
          ? CyclePhase.fromString(json['target_phase'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content_text': contentText,
      'source_reference': sourceReference,
      'content_type': contentType,
      'target_phase': targetPhase?.toDbString(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

