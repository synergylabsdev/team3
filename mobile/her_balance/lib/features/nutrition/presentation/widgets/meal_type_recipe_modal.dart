import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/recipes/data/repositories/recipe_repository.dart';
import '../../../../features/recipes/domain/models/recipe.dart';
import '../../../../features/meal_planning/data/repositories/meal_plan_repository.dart';
import '../../../../features/meal_planning/domain/models/meal_plan.dart';

class MealTypeRecipeModal extends StatefulWidget {
  final DateTime date;
  final String mealType;
  final List<MealPlan> existingMeals;

  const MealTypeRecipeModal({
    super.key,
    required this.date,
    required this.mealType,
    required this.existingMeals,
  });

  @override
  State<MealTypeRecipeModal> createState() => _MealTypeRecipeModalState();
}

class _MealTypeRecipeModalState extends State<MealTypeRecipeModal> {
  final _recipeRepository = RecipeRepository();
  final _mealPlanRepository = MealPlanRepository();
  List<Recipe> _recipes = [];
  bool _isLoading = true;
  Set<String> _selectedRecipeIds = {}; // Track selected recipes locally
  Set<String> _originalSelectedIds = {}; // Track original selections

  @override
  void initState() {
    super.initState();
    // Initialize with existing meals
    _originalSelectedIds = widget.existingMeals.map((m) => m.recipeId).toSet();
    _selectedRecipeIds = Set.from(_originalSelectedIds);
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _recipes = await _recipeRepository.getRecipes(
        mealTypeFilter: widget.mealType,
      );
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading recipes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isMealSelected(String recipeId) {
    return _selectedRecipeIds.contains(recipeId);
  }

  void _toggleMeal(Recipe recipe) {
    setState(() {
      if (_selectedRecipeIds.contains(recipe.id)) {
        _selectedRecipeIds.remove(recipe.id);
      } else {
        _selectedRecipeIds.add(recipe.id);
      }
    });
  }

  Future<void> _confirmChanges() async {
    try {
      // Find recipes to add (in selected but not in original)
      final toAdd = _selectedRecipeIds.difference(_originalSelectedIds);
      // Find recipes to remove (in original but not in selected)
      final toRemove = _originalSelectedIds.difference(_selectedRecipeIds);

      // Add new meals
      for (final recipeId in toAdd) {
        await _mealPlanRepository.addMealPlan(
          recipeId: recipeId,
          plannedDate: widget.date,
          mealType: widget.mealType,
        );
      }

      // Remove meals
      for (final recipeId in toRemove) {
        final mealPlan = widget.existingMeals.firstWhere((m) => m.recipeId == recipeId);
        await _mealPlanRepository.removeMealPlan(mealPlan.id);
      }

      Navigator.pop(context, true);
    } catch (e) {
      print('Error saving meal plan changes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving changes')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.inactiveColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your recipes for ${widget.mealType.capitalize()}',
                  style: GoogleFonts.tinos(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppTheme.textPrimary),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ),
          ),
          // Recipes Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _recipes.isEmpty
                    ? Center(
                        child: Text(
                          'No recipes found',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(20),
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: _recipes.length,
                          itemBuilder: (context, index) {
                            final recipe = _recipes[index];
                            final isSelected = _isMealSelected(recipe.id);
                            return _buildRecipeCard(recipe, isSelected);
                          },
                        ),
                      ),
          ),
          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppTheme.bloomColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.bloomColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirmChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Confirm',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleMeal(recipe),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.inactiveColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: recipe.imageUrl != null
                        ? Image.network(
                            recipe.imageUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppTheme.backgroundColor,
                                child: Icon(Icons.restaurant, color: AppTheme.inactiveColor),
                              );
                            },
                          )
                        : Container(
                            color: AppTheme.backgroundColor,
                            child: Icon(Icons.restaurant, color: AppTheme.inactiveColor),
                          ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      '${recipe.calories.toInt()} cal • ${recipe.protein.toInt()}g protein',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

