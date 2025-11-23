import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/enums/cycle_phase.dart';
import '../../../../../../features/recipes/data/repositories/recipe_repository.dart';
import '../../../../../../features/recipes/domain/models/recipe.dart';
import '../recipe_detail_page.dart';
import '../../widgets/date_meal_picker_modal.dart';

class NutritionCookbookTab extends StatefulWidget {
  const NutritionCookbookTab({super.key});

  @override
  State<NutritionCookbookTab> createState() => _NutritionCookbookTabState();
}

class _NutritionCookbookTabState extends State<NutritionCookbookTab> {
  final _recipeRepository = RecipeRepository();
  final _searchController = TextEditingController();

  List<Recipe> _recipes = [];
  List<Recipe> _filteredRecipes = [];
  bool _isLoading = true;

  CyclePhase? _selectedPhase;
  String? _selectedMealType;
  bool _favoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void refresh() {
    _loadRecipes();
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  Future<void> _loadRecipes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _recipes = await _recipeRepository.getRecipes(
        phaseFilter: _selectedPhase,
        mealTypeFilter: _selectedMealType,
        favoritesOnly: _favoritesOnly ? true : null,
      );
      _applyFilters();
    } catch (e) {
      print('Error loading recipes: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      final searchQuery = _searchController.text.toLowerCase();
      _filteredRecipes = _recipes.where((recipe) {
        final matchesSearch =
            searchQuery.isEmpty ||
            recipe.title.toLowerCase().contains(searchQuery) ||
            (recipe.description?.toLowerCase().contains(searchQuery) ?? false);
        return matchesSearch;
      }).toList();
    });
  }

  Future<void> _toggleFavorite(Recipe recipe) async {
    final newFavoriteStatus = await _recipeRepository.toggleFavorite(recipe.id);
    setState(() {
      recipe.isFavorite = newFavoriteStatus;
    });
    _loadRecipes(); // Reload to update favorites filter
  }

  Future<void> _showDateMealPicker(Recipe recipe) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DateMealPickerModal(recipe: recipe),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe added to meal plan!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(20),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search recipes...',
              prefixIcon: Icon(Icons.search, color: AppTheme.inactiveColor),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),

        // Filters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Phase Filter
              Row(
                children: [
                  Expanded(
                    child: _buildFilterChip(
                      label: 'Phase: ${_selectedPhase?.name ?? "All"}',
                      isSelected: _selectedPhase != null,
                      onTap: () => _showPhaseFilter(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterChip(
                      label:
                          'Meal: ${_selectedMealType?.capitalize() ?? "All"}',
                      isSelected: _selectedMealType != null,
                      onTap: () => _showMealTypeFilter(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterChip(
                      label: 'Recipe: ${_favoritesOnly ? "Fav" : "All"}',
                      isSelected: _favoritesOnly,
                      onTap: () => _showRecipeFilter(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Recipes Grid
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredRecipes.isEmpty
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                    itemCount: _filteredRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = _filteredRecipes[index];
                      return _buildRecipeCard(recipe);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.inactiveColor,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.inactiveColor,
            ),
          ],
        ),
      ),
    );
  }

  void _showPhaseFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('All Phases'),
                onTap: () {
                  setState(() {
                    _selectedPhase = null;
                  });
                  Navigator.pop(context);
                  _loadRecipes();
                },
              ),
              ...CyclePhase.values.map((phase) {
                return ListTile(
                  title: Text(phase.name),
                  onTap: () {
                    setState(() {
                      _selectedPhase = phase;
                    });
                    Navigator.pop(context);
                    _loadRecipes();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showMealTypeFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('All Meals'),
                onTap: () {
                  setState(() {
                    _selectedMealType = null;
                  });
                  Navigator.pop(context);
                  _loadRecipes();
                },
              ),
              ListTile(
                title: const Text('Breakfast'),
                onTap: () {
                  setState(() {
                    _selectedMealType = 'breakfast';
                  });
                  Navigator.pop(context);
                  _loadRecipes();
                },
              ),
              ListTile(
                title: const Text('Lunch'),
                onTap: () {
                  setState(() {
                    _selectedMealType = 'lunch';
                  });
                  Navigator.pop(context);
                  _loadRecipes();
                },
              ),
              ListTile(
                title: const Text('Dinner'),
                onTap: () {
                  setState(() {
                    _selectedMealType = 'dinner';
                  });
                  Navigator.pop(context);
                  _loadRecipes();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRecipeFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('All'),
                onTap: () {
                  setState(() {
                    _favoritesOnly = false;
                  });
                  Navigator.pop(context);
                  _loadRecipes();
                },
              ),
              ListTile(
                title: const Text('Favorites'),
                onTap: () {
                  setState(() {
                    _favoritesOnly = true;
                  });
                  Navigator.pop(context);
                  _loadRecipes();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailPage(recipeId: recipe.id),
          ),
        ).then((_) => _loadRecipes());
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: recipe.imageUrl != null
                    ? Image.network(
                        recipe.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppTheme.backgroundColor,
                            child: Icon(
                              Icons.restaurant,
                              color: AppTheme.inactiveColor,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: AppTheme.backgroundColor,
                        child: Icon(
                          Icons.restaurant,
                          color: AppTheme.inactiveColor,
                        ),
                      ),
              ),
            ),
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            recipe.title,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${recipe.calories.toInt()} cal • ${recipe.protein.toInt()}g protein',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          icon: Icon(
                            recipe.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: recipe.isFavorite
                                ? AppTheme.primaryColor
                                : AppTheme.inactiveColor,
                            size: 18,
                          ),
                          onPressed: () => _toggleFavorite(recipe),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          icon: Icon(
                            Icons.calendar_today,
                            color: AppTheme.primaryColor,
                            size: 18,
                          ),
                          onPressed: () => _showDateMealPicker(recipe),
                        ),
                      ],
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
