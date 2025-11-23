import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../meal_planning/data/repositories/meal_plan_repository.dart';
import '../../../meal_planning/domain/models/meal_plan.dart';
import '../widgets/meal_type_recipe_modal.dart';

class MealPlanPage extends StatefulWidget {
  const MealPlanPage({super.key});

  @override
  State<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends State<MealPlanPage> {
  final _mealPlanRepository = MealPlanRepository();
  DateTime _selectedDate = DateTime.now();
  List<MealPlan> _meals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final meals = await _mealPlanRepository.getMealsForDate(_selectedDate);
      setState(() {
        _meals = meals;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading meals: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<MealPlan> _getMealsForType(String mealType) {
    return _meals.where((meal) => meal.mealType == mealType).toList();
  }

  Future<void> _navigateDate(int days) async {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    await _loadMeals();
  }

  Future<void> _showMealTypeModal(String mealType) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MealTypeRecipeModal(
        date: _selectedDate,
        mealType: mealType,
        existingMeals: _getMealsForType(mealType),
      ),
    );

    if (result == true) {
      _loadMeals();
    }
  }

  Future<void> _removeMeal(MealPlan mealPlan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Meal'),
        content: const Text('Are you sure you want to remove this meal from your plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _mealPlanRepository.removeMealPlan(mealPlan.id);
      _loadMeals();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Your Meal Plan',
          style: GoogleFonts.tinos(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // Date Navigation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: AppTheme.primaryColor),
                  onPressed: () => _navigateDate(-1),
                ),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: AppTheme.primaryColor),
                  onPressed: () => _navigateDate(1),
                ),
              ],
            ),
          ),

          // Meals List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildMealSection('breakfast', 'Breakfast'),
                      const SizedBox(height: 16),
                      _buildMealSection('lunch', 'Lunch'),
                      const SizedBox(height: 16),
                      _buildMealSection('dinner', 'Dinner'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSection(String mealType, String label) {
    final meals = _getMealsForType(mealType);

    return GestureDetector(
      onTap: () => _showMealTypeModal(mealType),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Icon(Icons.add, color: AppTheme.primaryColor),
              ],
            ),
            const SizedBox(height: 12),
            if (meals.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, size: 16, color: AppTheme.inactiveColor),
                    const SizedBox(width: 8),
                    Text(
                      'No recipe yet',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...meals.map((meal) {
                final recipe = meal.recipe;
                if (recipe == null) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipe['title'] as String? ?? 'Unknown',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if (recipe['description'] != null)
                              Text(
                                recipe['description'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 20, color: AppTheme.inactiveColor),
                        onPressed: () => _removeMeal(meal),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}


