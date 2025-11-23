import '../../../../core/enums/cycle_phase.dart';

class Recipe {
  final String id;
  final String? createdBy;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? sourceUrl;
  final int servings;
  final int? prepTimeMinutes;
  final String? instructions;
  final List<CyclePhase> phaseTags;
  final List<Map<String, dynamic>> ingredients;
  final Map<String, dynamic> nutritionSummary;
  final double? aiConfidenceScore;
  final String? aiSuggestions;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? mealType; // 'breakfast', 'lunch', 'dinner', 'snack'
  bool isFavorite; // Computed based on user's favorites

  Recipe({
    required this.id,
    this.createdBy,
    required this.title,
    this.description,
    this.imageUrl,
    this.sourceUrl,
    required this.servings,
    this.prepTimeMinutes,
    this.instructions,
    required this.phaseTags,
    required this.ingredients,
    required this.nutritionSummary,
    this.aiConfidenceScore,
    this.aiSuggestions,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
    this.mealType,
    this.isFavorite = false,
  });

  factory Recipe.fromJson(Map<String, dynamic> json, {bool isFavorite = false}) {
    // Parse phase_tags array
    List<CyclePhase> phaseTags = [];
    if (json['phase_tags'] != null) {
      final tags = json['phase_tags'] as List<dynamic>;
      phaseTags = tags
          .map((tag) => CyclePhase.fromString(tag as String?))
          .toList();
    }

    // Parse ingredients
    List<Map<String, dynamic>> ingredients = [];
    if (json['ingredients'] != null) {
      final ingList = json['ingredients'] as List<dynamic>;
      ingredients = ingList
          .map((ing) => ing as Map<String, dynamic>)
          .toList();
    }

    // Parse nutrition summary
    Map<String, dynamic> nutritionSummary = {};
    if (json['nutrition_summary'] != null) {
      nutritionSummary = json['nutrition_summary'] as Map<String, dynamic>;
    }

    return Recipe(
      id: json['id'] as String,
      createdBy: json['created_by'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      sourceUrl: json['source_url'] as String?,
      servings: json['servings'] as int? ?? 1,
      prepTimeMinutes: json['prep_time_minutes'] as int?,
      instructions: json['instructions'] as String?,
      phaseTags: phaseTags,
      ingredients: ingredients,
      nutritionSummary: nutritionSummary,
      aiConfidenceScore: (json['ai_confidence_score'] as num?)?.toDouble(),
      aiSuggestions: json['ai_suggestions'] as String?,
      isPublic: json['is_public'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      mealType: json['meal_type'] as String?,
      isFavorite: isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_by': createdBy,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'source_url': sourceUrl,
      'servings': servings,
      'prep_time_minutes': prepTimeMinutes,
      'instructions': instructions,
      'phase_tags': phaseTags.map((p) => p.toDbString()).toList(),
      'ingredients': ingredients,
      'nutrition_summary': nutritionSummary,
      'ai_confidence_score': aiConfidenceScore,
      'ai_suggestions': aiSuggestions,
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'meal_type': mealType,
    };
  }

  // Helper getters for nutrition
  double get calories => (nutritionSummary['calories'] as num?)?.toDouble() ?? 0.0;
  double get protein => (nutritionSummary['protein'] as num?)?.toDouble() ?? 0.0;
  double get carbs => (nutritionSummary['carbs'] as num?)?.toDouble() ?? 0.0;
  double get fat => (nutritionSummary['fat'] as num?)?.toDouble() ?? 0.0;
  double get fiber => (nutritionSummary['fiber'] as num?)?.toDouble() ?? 0.0;
}

