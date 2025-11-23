class MealPlan {
  final String id;
  final String userId;
  final String recipeId;
  final DateTime plannedDate;
  final String mealType; // 'breakfast', 'lunch', 'dinner', 'snack'
  final bool isCompleted;
  final Map<String, dynamic>? recipe; // Joined recipe data

  MealPlan({
    required this.id,
    required this.userId,
    required this.recipeId,
    required this.plannedDate,
    required this.mealType,
    required this.isCompleted,
    this.recipe,
  });

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    return MealPlan(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      recipeId: json['recipe_id'] as String,
      plannedDate: DateTime.parse(json['planned_date'] as String),
      mealType: json['meal_type'] as String,
      isCompleted: json['is_completed'] as bool? ?? false,
      recipe: json['recipe'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'recipe_id': recipeId,
      'planned_date': plannedDate.toIso8601String().split('T')[0],
      'meal_type': mealType,
      'is_completed': isCompleted,
    };
  }
}

