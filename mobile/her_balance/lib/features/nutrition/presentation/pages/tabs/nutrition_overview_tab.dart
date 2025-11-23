import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/enums/cycle_phase.dart';
import '../../../../../../core/utils/cycle_calculator.dart';
import '../../../../../../features/profile/data/repositories/profile_repository.dart';
import '../../../../../../features/meal_planning/data/repositories/meal_plan_repository.dart';
import '../../../../../../features/meal_planning/domain/models/meal_plan.dart';
import '../../../../../../features/daily_logs/data/repositories/daily_log_repository.dart';
import '../meal_plan_page.dart';

class NutritionOverviewTab extends StatefulWidget {
  const NutritionOverviewTab({super.key});

  @override
  State<NutritionOverviewTab> createState() => _NutritionOverviewTabState();
}

class _NutritionOverviewTabState extends State<NutritionOverviewTab> {
  final _profileRepository = ProfileRepository();
  final _mealPlanRepository = MealPlanRepository();
  final _dailyLogRepository = DailyLogRepository();

  CyclePhase? _currentPhase;
  List<dynamic> _todayMeals = [];
  List<MealPlan> _todayMealPlans = []; // Store meal plans to track completion
  Set<String> _loggedMealIds = {}; // Track logged meal IDs
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void refresh() {
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current phase
      final profile = await _profileRepository.getCurrentUserProfile();
      if (profile != null) {
        final cyclePhase = CycleCalculator.calculatePhase(
          profile.lastPeriodStart,
          profile.avgCycleLength,
        );
        _currentPhase = cyclePhase ?? CyclePhase.root;
      }

      // Get today's meals
      final today = DateTime.now();
      final meals = await _mealPlanRepository.getMealsForDate(today);
      _todayMealPlans = meals;
      _todayMeals = meals
          .map((m) => m.recipe)
          .whereType<Map<String, dynamic>>()
          .toList();

      // Track which meals are already completed/logged
      _loggedMealIds = meals
          .where((m) => m.isCompleted)
          .map((m) => m.recipeId)
          .toSet();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading nutrition overview: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getNutritionFocusText(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.root:
        return 'Your menstrual phase is your body\'s winter. Choose iron-rich, warming foods like soups, stews, leafy greens, and pasture-raised proteins. Hydrate deeply and avoid excess sugar and caffeine.';
      case CyclePhase.bloom:
        return 'During your Bloom phase, focus on fresh, energizing foods. Include plenty of vegetables, lean proteins, and complex carbs to support rising energy levels.';
      case CyclePhase.shine:
        return 'Your Shine phase is peak energy time! Fuel with nutrient-dense meals, healthy fats, and antioxidant-rich foods. This is the perfect time for vibrant salads and energizing smoothies.';
      case CyclePhase.harvest:
        return 'During your Harvest phase, support your body with complex carbs, magnesium-rich foods, and healthy fats. Focus on grounding, comforting meals that stabilize blood sugar.';
    }
  }

  Future<void> _logMeal(
    Map<String, dynamic> recipe, {
    String? mealPlanId,
  }) async {
    try {
      final recipeId = recipe['id'] as String?;
      if (recipeId == null) return;

      // Check if already logged
      if (_loggedMealIds.contains(recipeId)) {
        return;
      }

      final nutrition = recipe['nutrition_summary'] as Map<String, dynamic>?;
      if (nutrition == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nutrition information not available'),
            ),
          );
        }
        return;
      }

      final today = DateTime.now();
      final todayLog = await _dailyLogRepository.getTodayLog();

      final currentCalories = todayLog?.totalCalories ?? 0.0;
      final currentProtein = todayLog?.totalProtein ?? 0.0;
      final currentCarbs = todayLog?.totalCarbs ?? 0.0;
      final currentFat = todayLog?.totalFat ?? 0.0;
      final currentFiber = todayLog?.totalFiber ?? 0.0;

      final mealCalories = (nutrition['calories'] as num?)?.toDouble() ?? 0.0;
      final mealProtein = (nutrition['protein'] as num?)?.toDouble() ?? 0.0;
      final mealCarbs = (nutrition['carbs'] as num?)?.toDouble() ?? 0.0;
      final mealFat = (nutrition['fat'] as num?)?.toDouble() ?? 0.0;
      final mealFiber = (nutrition['fiber'] as num?)?.toDouble() ?? 0.0;

      await _dailyLogRepository.updateNutritionTotals(
        logDate: today,
        totalCalories: currentCalories + mealCalories,
        totalProtein: currentProtein + mealProtein,
        totalCarbs: currentCarbs + mealCarbs,
        totalFat: currentFat + mealFat,
        totalFiber: currentFiber + mealFiber,
      );

      // Mark meal plan as completed if mealPlanId is provided
      if (mealPlanId != null) {
        await _mealPlanRepository.markMealCompleted(mealPlanId, true);
      }

      // Update state to mark meal as logged
      setState(() {
        _loggedMealIds.add(recipeId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meal logged successfully!')),
        );
      }
    } catch (e) {
      print('Error logging meal: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error logging meal')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nutrition Focus Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.eco, color: Colors.white, size: 32),
                const SizedBox(height: 12),
                Text(
                  'Nutrition Focus',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.gildaDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _getNutritionFocusText(_currentPhase ?? CyclePhase.root),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Daily Meal Plan Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Meal Plan',
                textAlign: TextAlign.center,
                style: GoogleFonts.gildaDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF4A4A4A),
                  height: 28 / 18, // line-height: 28px / font-size: 18px
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MealPlanPage(),
                    ),
                  ).then((_) => _loadData());
                },
                icon: Icon(Icons.edit, size: 16, color: AppTheme.primaryColor),
                label: Text(
                  'Edit Plan',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Today's meals
          if (_todayMeals.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'No meals planned for today',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            )
          else
            ..._todayMealPlans.map((mealPlan) {
              final meal = mealPlan.recipe;
              if (meal == null) return const SizedBox.shrink();
              return _buildMealCard(
                meal,
                isFromPlan: true,
                mealPlanId: mealPlan.id,
                recipeId: mealPlan.recipeId,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMealCard(
    Map<String, dynamic> meal, {
    required bool isFromPlan,
    String? mealPlanId,
    String? recipeId,
  }) {
    final title = meal['title'] as String? ?? 'Unknown';
    final description =
        meal['description'] as String? ??
        'Perfect for your ${_currentPhase?.name.toLowerCase() ?? "current"} phase.';
    final imageUrl = meal['image_url'] as String?;
    final isLogged = recipeId != null && _loggedMealIds.contains(recipeId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Image
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: AppTheme.backgroundColor,
                    child: Icon(
                      Icons.restaurant,
                      color: AppTheme.inactiveColor,
                    ),
                  );
                },
              ),
            )
          else
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.restaurant, color: AppTheme.inactiveColor),
            ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLogged
                        ? null
                        : () => _logMeal(meal, mealPlanId: mealPlanId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLogged
                          ? AppTheme.inactiveColor
                          : AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: AppTheme.inactiveColor,
                    ),
                    child: Text(
                      isLogged ? 'Logged' : 'Log Meal',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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
}
