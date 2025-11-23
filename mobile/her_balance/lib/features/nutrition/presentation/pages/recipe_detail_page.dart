import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/recipes/data/repositories/recipe_repository.dart';
import '../../../../features/recipes/domain/models/recipe.dart';
import '../widgets/date_meal_picker_modal.dart';

class RecipeDetailPage extends StatefulWidget {
  final String recipeId;

  const RecipeDetailPage({super.key, required this.recipeId});

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  final _recipeRepository = RecipeRepository();
  Recipe? _recipe;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  Future<void> _loadRecipe() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final recipe = await _recipeRepository.getRecipeById(widget.recipeId);
      setState(() {
        _recipe = recipe;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading recipe: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_recipe == null) return;
    final newFavoriteStatus = await _recipeRepository.toggleFavorite(_recipe!.id);
    setState(() {
      _recipe!.isFavorite = newFavoriteStatus;
    });
  }

  Future<void> _showDateMealPicker() async {
    if (_recipe == null) return;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DateMealPickerModal(recipe: _recipe!),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe added to meal plan!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_recipe == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
        ),
        body: const Center(child: Text('Recipe not found')),
      );
    }

    final recipe = _recipe!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.backgroundColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: recipe.imageUrl != null
                  ? Image.network(
                      recipe.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppTheme.backgroundColor,
                          child: Icon(Icons.restaurant, size: 64, color: AppTheme.inactiveColor),
                        );
                      },
                    )
                  : Container(
                      color: AppTheme.backgroundColor,
                      child: Icon(Icons.restaurant, size: 64, color: AppTheme.inactiveColor),
                    ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          recipe.title,
                          style: GoogleFonts.tinos(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: recipe.isFavorite ? AppTheme.primaryColor : AppTheme.inactiveColor,
                            ),
                            onPressed: _toggleFavorite,
                          ),
                          IconButton(
                            icon: Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                            onPressed: _showDateMealPicker,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Phase Tags and Prep Time
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...recipe.phaseTags.map((phase) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: phase.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${phase.name} Phase',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: phase.color,
                            ),
                          ),
                        );
                      }),
                      if (recipe.prepTimeMinutes != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time, size: 14, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                '${recipe.prepTimeMinutes} mins',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Nutrition Info
                  Text(
                    'Nutrition',
                    style: GoogleFonts.tinos(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNutritionItem('${recipe.calories.toInt()}', 'Calories'),
                        _buildNutritionItem('${recipe.protein.toInt()}g', 'Protein'),
                        _buildNutritionItem('${recipe.carbs.toInt()}g', 'Carbs'),
                        _buildNutritionItem('${recipe.fat.toInt()}g', 'Fat'),
                        _buildNutritionItem('${recipe.fiber.toInt()}g', 'Fiber'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ingredients
                  Text(
                    'Ingredients',
                    style: GoogleFonts.tinos(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: recipe.ingredients.isEmpty
                        ? Text(
                            'No ingredients listed',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: recipe.ingredients.map((ingredient) {
                              final name = ingredient['name'] as String? ?? '';
                              final amount = ingredient['amount'];
                              final unit = ingredient['unit'] as String? ?? '';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        amount != null && unit.isNotEmpty
                                            ? '$amount $unit $name'
                                            : name,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Instructions
                  Text(
                    'Instructions',
                    style: GoogleFonts.tinos(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: recipe.instructions != null && recipe.instructions!.isNotEmpty
                        ? Text(
                            recipe.instructions!,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                              height: 1.5,
                            ),
                          )
                        : Text(
                            'No instructions available',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

