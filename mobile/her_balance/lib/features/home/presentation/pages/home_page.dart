import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/enums/cycle_phase.dart';
import '../../../../../core/utils/cycle_calculator.dart';
import '../../../../../shared/widgets/period_modal.dart';
import '../../../../../shared/widgets/quick_actions_modal.dart';
import '../../../daily_logs/presentation/pages/log_symptoms_page.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../../profile/domain/models/profile.dart';
import '../../../cycle/data/repositories/cycle_repository.dart';
import '../../../daily_logs/data/repositories/daily_log_repository.dart';
import '../../../daily_logs/domain/models/daily_log.dart';
import '../../../inspirational_content/data/repositories/inspirational_content_repository.dart';
import '../../../inspirational_content/domain/models/inspirational_content.dart';
import '../../../meal_planning/data/repositories/meal_plan_repository.dart';
import '../../../meal_planning/domain/models/meal_plan.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _profileRepository = ProfileRepository();
  final _cycleRepository = CycleRepository();
  final _dailyLogRepository = DailyLogRepository();
  final _inspirationalContentRepository = InspirationalContentRepository();
  final _mealPlanRepository = MealPlanRepository();

  Profile? _profile;
  CyclePhase? _cyclePhase;
  int? _cycleDay;
  bool _hasActivePeriod = false;
  DailyLog? _todayLog;
  InspirationalContent? _dailyVerse;
  InspirationalContent? _wellnessTip;
  MealPlan? _todayBreakfast;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load profile
      final profile = await _profileRepository.getCurrentUserProfile();
      if (profile == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Check for active period first
      final activeCycle = await _cycleRepository.getActiveCycle();
      final hasActivePeriod = activeCycle != null;

      // Calculate cycle phase and day
      final cycleDay = CycleCalculator.calculateCycleDay(
        profile.lastPeriodStart,
        profile.avgCycleLength,
      );

      CyclePhase? cyclePhase;
      if (cycleDay != null) {
        cyclePhase = CycleCalculator.calculatePhase(
          profile.lastPeriodStart,
          profile.avgCycleLength,
        );

        // If period just ended (no active period) and we're still in period days (1-7),
        // force root phase to show the root color scheme
        if (!hasActivePeriod && cycleDay <= 7) {
          cyclePhase = CyclePhase.root;
        }
      }

      // Calculate nutrition from completed meals
      final today = DateTime.now();
      final meals = await _mealPlanRepository.getMealsForDate(today);

      double totalCalories = 0;
      double totalProtein = 0;
      double totalFat = 0;
      double totalCarbs = 0;
      double totalFiber = 0;

      for (final meal in meals) {
        if (meal.isCompleted && meal.recipe != null) {
          final nutrition =
              meal.recipe!['nutrition_summary'] as Map<String, dynamic>?;
          if (nutrition != null) {
            totalCalories += (nutrition['calories'] as num?)?.toDouble() ?? 0;
            totalProtein += (nutrition['protein'] as num?)?.toDouble() ?? 0;
            totalFat += (nutrition['fat'] as num?)?.toDouble() ?? 0;
            totalCarbs += (nutrition['carbs'] as num?)?.toDouble() ?? 0;
            totalFiber += (nutrition['fiber'] as num?)?.toDouble() ?? 0;
          }
        }
      }

      // Update daily log with calculated nutrition
      if (totalCalories > 0 ||
          totalProtein > 0 ||
          totalFat > 0 ||
          totalCarbs > 0 ||
          totalFiber > 0) {
        await _dailyLogRepository.updateNutritionTotals(
          logDate: today,
          totalCalories: totalCalories > 0 ? totalCalories : null,
          totalProtein: totalProtein > 0 ? totalProtein : null,
          totalFat: totalFat > 0 ? totalFat : null,
          totalCarbs: totalCarbs > 0 ? totalCarbs : null,
          totalFiber: totalFiber > 0 ? totalFiber : null,
        );
      }

      // Load today's log (now with calculated nutrition)
      final todayLog = await _dailyLogRepository.getTodayLog();

      // Load daily verse (only if enabled)
      InspirationalContent? dailyVerse;
      if (profile.showBibleVerses) {
        dailyVerse = await _inspirationalContentRepository.getDailyVerse(
          targetPhase: cyclePhase,
        );
      }

      // Load wellness tip
      final wellnessTip = await _inspirationalContentRepository.getWellnessTip(
        targetPhase: cyclePhase,
      );

      // Load today's breakfast
      final todayBreakfast = await _mealPlanRepository.getTodayMeal(
        'breakfast',
      );

      setState(() {
        _profile = profile;
        _cyclePhase = cyclePhase ?? CyclePhase.root;
        _cycleDay = cycleDay;
        _hasActivePeriod = hasActivePeriod;
        _todayLog = todayLog;
        _dailyVerse = dailyVerse;
        _wellnessTip = wellnessTip;
        _todayBreakfast = todayBreakfast;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading home data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getUserName() {
    if (_profile?.email != null) {
      final email = _profile!.email!;
      return email.split('@').first;
    }
    return 'there';
  }

  String _getFlowDescription() {
    if (_cyclePhase == null) {
      return 'Track your cycle to see personalized activity recommendations.';
    }

    switch (_cyclePhase!) {
      case CyclePhase.root:
        return 'During your Root phase, focus on restorative movement — stretching, walking.';
      case CyclePhase.bloom:
        return 'During your Bloom phase, embrace moderate exercise — yoga, light cardio.';
      case CyclePhase.shine:
        return 'During your Shine phase, maximize your energy — intense workouts, dancing.';
      case CyclePhase.harvest:
        return 'During your Harvest phase, balance activity — strength training, pilates.';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final cyclePhase = _cyclePhase ?? CyclePhase.root;
    final cycleDay = _cycleDay ?? 1;
    final userName = _getUserName();
    final avgCycleLength = _profile?.avgCycleLength ?? 28;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                Center(
                  child: Text(
                    _cycleDay != null
                        ? 'Hi $userName, it\'s cycle day $cycleDay'
                        : 'Hi $userName',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF647187),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Cycle Progress Indicator
                Center(
                  child: Column(
                    children: [
                      // Circular progress indicator
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer ring (progress)
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: CircularProgressIndicator(
                                value: _cycleDay != null
                                    ? (cycleDay / avgCycleLength).clamp(
                                        0.0,
                                        1.0,
                                      )
                                    : 0.0,
                                strokeWidth: 8,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  cyclePhase.color,
                                ),
                              ),
                            ),
                            // Inner circle with icon
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: cyclePhase.color,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.eco,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Phase name
                      Text(
                        '${cyclePhase.name} | ${cyclePhase.subtitle}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.tinos(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4A4A4A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Tagline
                      Text(
                        cyclePhase.tagline,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: cyclePhase.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: cyclePhase.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: cyclePhase.color,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0E1829).withOpacity(0.05),
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              await LogSymptomsPage.show(
                                context,
                                cyclePhase: cyclePhase,
                              );
                              // Reload data after bottom sheet closes
                              if (mounted) {
                                _loadData();
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              height: 48,
                              alignment: Alignment.center,
                              child: Material(
                                color: Colors.transparent,
                                child: Text(
                                  'Log Symptoms',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: cyclePhase.color,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0E1829).withOpacity(0.05),
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              PeriodModal.show(
                                context,
                                isStartPeriod: !_hasActivePeriod,
                                onSaved: _loadData,
                                cyclePhase: cyclePhase,
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              height: 48,
                              alignment: Alignment.center,
                              child: Material(
                                color: Colors.transparent,
                                child: Text(
                                  _hasActivePeriod
                                      ? 'My Period Ended'
                                      : 'My Period Started',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: cyclePhase.color,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Weekly Wellness Section
                if (_wellnessTip != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cyclePhase.color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.spa, color: Colors.white, size: 24),
                        const SizedBox(height: 12),
                        Text(
                          'WEEKLY WELLNESS',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.gildaDisplay(
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _wellnessTip!.contentText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_wellnessTip != null) const SizedBox(height: 20),

                // Today's Verse Section
                if (_dailyVerse != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cyclePhase.color, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.favorite,
                              color: cyclePhase.color,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Today\'s Verse',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: cyclePhase.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${_dailyVerse!.contentText}${_dailyVerse!.sourceReference != null ? ' — ${_dailyVerse!.sourceReference}' : ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_dailyVerse != null) const SizedBox(height: 20),

                // Your Flow and Your Fuel (Side by Side)
                Column(
                  children: [
                    Row(
                      children: [
                        // Your Flow Title
                        Expanded(
                          child: Text(
                            'Your Flow',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.tinos(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        // Your Fuel Title
                        Expanded(
                          child: Text(
                            'Your Fuel',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.tinos(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Your Flow Card
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: cyclePhase.color,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.directions_run,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _getFlowDescription(),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: AppTheme.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Your Fuel Card
                          Expanded(
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: _todayBreakfast?.recipe != null
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Image.network(
                                                  _todayBreakfast!
                                                              .recipe!['image_url']
                                                          as String? ??
                                                      '',
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => const Icon(
                                                        Icons.restaurant,
                                                        size: 40,
                                                        color: AppTheme
                                                            .textSecondary,
                                                      ),
                                                ),
                                              )
                                            : const Icon(
                                                Icons.restaurant,
                                                size: 40,
                                                color: AppTheme.textSecondary,
                                              ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _todayBreakfast?.recipe != null
                                            ? (_todayBreakfast!.recipe!['title']
                                                      as String? ??
                                                  'Breakfast')
                                            : 'Breakfast',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _todayBreakfast?.recipe != null
                                            ? (_todayBreakfast!.recipe!['title']
                                                      as String? ??
                                                  'No meal planned')
                                            : 'No meal planned',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: cyclePhase.color,
                                            width: 1,
                                          ),
                                          color: cyclePhase.color,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF0E1829,
                                              ).withOpacity(0.05),
                                              offset: const Offset(0, 1),
                                              blurRadius: 2,
                                              spreadRadius: 0,
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {},
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                'See Recipe',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Green leaf icon in top right corner
                                if (_todayBreakfast?.recipe != null)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4CAF50),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(
                                        Icons.eco,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Your Daily Macros Section
                const Text(
                  'Your Daily Macros',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Macro Cards
                _buildMacroCard(
                  icon: Icons.set_meal,
                  label: 'Protein',
                  current: (_todayLog?.totalProtein ?? 0).toInt(),
                  target: 120,
                  unit: 'g',
                  color: cyclePhase.color,
                ),
                const SizedBox(height: 12),
                _buildMacroCard(
                  icon: Icons.grass,
                  label: 'Carbs',
                  current: (_todayLog?.totalCarbs ?? 0).toInt(),
                  target: 250,
                  unit: 'g',
                  color: cyclePhase.color,
                ),
                const SizedBox(height: 12),
                _buildMacroCard(
                  icon: Icons.local_fire_department,
                  label: 'Calories',
                  current: (_todayLog?.totalCalories ?? 0).toInt(),
                  target: 2000,
                  unit: '',
                  color: cyclePhase.color,
                ),
                const SizedBox(height: 12),
                _buildMacroCard(
                  icon: Icons.water_drop,
                  label: 'Fats',
                  current: (_todayLog?.totalFat ?? 0).toInt(),
                  target: 70,
                  unit: 'g',
                  color: cyclePhase.color,
                ),
                const SizedBox(height: 12),
                _buildMacroCard(
                  icon: Icons.eco,
                  label: 'Fiber',
                  current: (_todayLog?.totalFiber ?? 0).toInt(),
                  target: 30,
                  unit: 'g',
                  color: cyclePhase.color,
                ),
                const SizedBox(height: 80), // Space for FAB
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          QuickActionsModal.show(context);
        },
        backgroundColor: cyclePhase.color,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMacroCard({
    required IconData icon,
    required String label,
    required int current,
    required int target,
    required String unit,
    required Color color,
  }) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$current$unit / $target$unit',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
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
