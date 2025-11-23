import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/enums/cycle_phase.dart';
import '../../../../core/utils/cycle_calculator.dart';
import '../../../../features/profile/data/repositories/profile_repository.dart';
import '../../../../features/daily_logs/data/repositories/daily_log_repository.dart';
import '../../../../features/workout_planning/data/repositories/workout_plan_repository.dart';
import '../../../../features/workout_planning/domain/models/workout_plan.dart';
import '../widgets/log_steps_modal.dart';
import '../widgets/edit_goal_modal.dart';
import 'edit_workout_plan_page.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final _profileRepository = ProfileRepository();
  final _dailyLogRepository = DailyLogRepository();
  final _workoutPlanRepository = WorkoutPlanRepository();

  CyclePhase? _currentPhase;
  int _currentSteps = 0;
  int _dailyStepGoal = 10000;
  List<WorkoutPlan> _weekWorkouts = [];
  DateTime _currentWeekStart = _getWeekStart(DateTime.now());
  bool _isLoading = true;

  static DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

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
      // Get current phase
      final profile = await _profileRepository.getCurrentUserProfile();
      if (profile != null) {
        final cyclePhase = CycleCalculator.calculatePhase(
          profile.lastPeriodStart,
          profile.avgCycleLength,
        );
        _currentPhase = cyclePhase ?? CyclePhase.root;
        _dailyStepGoal = profile.dailyStepGoal;
      }

      // Get today's steps
      final todayLog = await _dailyLogRepository.getTodayLog();
      _currentSteps = todayLog?.stepCount ?? 0;

      // Get week workouts and sort by date (Monday to Sunday)
      _weekWorkouts = await _workoutPlanRepository.getWorkoutsForWeek(_currentWeekStart);
      _weekWorkouts.sort((a, b) => a.plannedDate.compareTo(b.plannedDate));

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading activity data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getActivityFocusText(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.root:
        return 'During your Root phase, focus on restorative movement and low intensity — stretching, walking, yoga, or skipping workouts entirely. Listen inward.';
      case CyclePhase.bloom:
        return 'During your Bloom phase, embrace moderate exercise — yoga, light cardio, and gentle movement. Build your energy gradually.';
      case CyclePhase.shine:
        return 'During your Shine phase, maximize your energy — intense workouts, dancing, and challenging activities. This is your peak performance time.';
      case CyclePhase.harvest:
        return 'During your Harvest phase, balance activity — strength training, pilates, and mindful movement. Support your body as it prepares.';
    }
  }

  Future<void> _logSteps(int steps) async {
    try {
      final today = DateTime.now();
      final todayLog = await _dailyLogRepository.getTodayLog();
      final currentSteps = todayLog?.stepCount ?? 0;
      final newTotal = currentSteps + steps;

      await _dailyLogRepository.upsertDailyLog(
        logDate: today,
        stepCount: newTotal,
      );

      setState(() {
        _currentSteps = newTotal;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Steps logged successfully!')),
        );
      }
    } catch (e) {
      print('Error logging steps: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error logging steps')),
        );
      }
    }
  }

  Future<void> _updateStepGoal(int goal) async {
    try {
      await _profileRepository.updateProfile({'daily_step_goal': goal});
      setState(() {
        _dailyStepGoal = goal;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal updated successfully!')),
        );
      }
    } catch (e) {
      print('Error updating step goal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating goal')),
        );
      }
    }
  }

  Future<void> _toggleWorkoutCompleted(WorkoutPlan workout) async {
    if (workout.id.isEmpty) return;

    try {
      final newStatus = !workout.isCompleted;
      await _workoutPlanRepository.markWorkoutCompleted(
        workout.id,
        newStatus,
      );

      // Update in week workouts list
      setState(() {
        final index = _weekWorkouts.indexWhere((w) => w.id == workout.id);
        if (index != -1) {
          _weekWorkouts[index] = WorkoutPlan(
            id: workout.id,
            userId: workout.userId,
            plannedDate: workout.plannedDate,
            activity: workout.activity,
            durationMinutes: workout.durationMinutes,
            videoLink: workout.videoLink,
            isRestDay: workout.isRestDay,
            isCompleted: newStatus,
            createdAt: workout.createdAt,
            updatedAt: DateTime.now(),
          );
        }
      });
    } catch (e) {
      print('Error toggling workout completion: $e');
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

    final progress = _dailyStepGoal > 0
        ? (_currentSteps / _dailyStepGoal).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    // Leaf icon
                    Image.asset(
                      'assets/leaf.png',
                      width: 56,
                      height: 56,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'YOUR FLOW',
                      style: GoogleFonts.tinos(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Activity Focus Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.directions_run,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _getActivityFocusText(_currentPhase ?? CyclePhase.root),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Steps Tracker Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Circular progress
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 12,
                              backgroundColor: AppTheme.backgroundColor,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                                Icons.directions_walk,
                                color: AppTheme.primaryColor,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'steps today',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_currentSteps',
                                style: GoogleFonts.inter(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              Text(
                                'of $_dailyStepGoal steps',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.primaryColor,
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
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => LogStepsModal(
                                      currentSteps: _currentSteps,
                                      onConfirm: _logSteps,
                                    ),
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
                                      'Log Steps',
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
                              color: const Color(0xFFA1B69C),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFA1B69C),
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
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => EditGoalModal(
                                      currentGoal: _dailyStepGoal,
                                      onSave: _updateStepGoal,
                                    ),
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
                                      'Edit Goal',
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
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Workout Plan Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Workout Plan',
                    style: GoogleFonts.gildaDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryColor,
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditWorkoutPlanPage(),
                            ),
                          ).then((_) => _loadData());
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit, size: 16, color: AppTheme.primaryColor),
                              const SizedBox(width: 8),
                              Material(
                                color: Colors.transparent,
                                child: Text(
                                  'Edit Plan',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.primaryColor,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Week Navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: AppTheme.primaryColor),
                    onPressed: () {
                      setState(() {
                        _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
                      });
                      _loadData();
                    },
                  ),
                  Text(
                    'Week of ${DateFormat('MMMM d, yyyy').format(_currentWeekStart)}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: AppTheme.primaryColor),
                    onPressed: () {
                      setState(() {
                        _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
                      });
                      _loadData();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Weekly Workouts
              if (_weekWorkouts.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'No workouts planned for this week',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                )
              else
                ..._weekWorkouts.map((workout) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildWorkoutCard(workout),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(WorkoutPlan workout) {
    return GestureDetector(
      onTap: () => _toggleWorkoutCompleted(workout),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: workout.isRestDay
                ? const Color(0xFFA1B69C)
                : AppTheme.primaryColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Day circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: workout.isRestDay
                    ? const Color(0xFFA1B69C)
                    : AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getDayAbbreviation(workout.plannedDate),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (workout.isRestDay)
                    Row(
                      children: [
                        Icon(
                          Icons.nightlight_round,
                          color: const Color(0xFFA1B69C),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Rest',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Icon(
                          _getActivityIcon(workout.activity ?? ''),
                          color: AppTheme.primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                    Text(
                          workout.activity ?? 'Activity',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  if (workout.isRestDay)
                    Text(
                      'Recovery day',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFFA1B69C),
                      ),
                    )
                  else if (workout.durationMinutes != null)
                    Text(
                      '${workout.durationMinutes} mins',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            // Completion checkbox
            GestureDetector(
              onTap: () => _toggleWorkoutCompleted(workout),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: workout.isCompleted
                        ? AppTheme.primaryColor
                        : AppTheme.inactiveColor,
                    width: 2,
                  ),
                  color: workout.isCompleted
                      ? AppTheme.primaryColor
                      : Colors.transparent,
                ),
                child: workout.isCompleted
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayAbbreviation(DateTime date) {
    final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return days[date.weekday - 1];
  }

  IconData _getActivityIcon(String activity) {
    final lower = activity.toLowerCase();
    if (lower.contains('walk')) {
      return Icons.directions_walk;
    } else if (lower.contains('yoga')) {
      return Icons.self_improvement;
    } else if (lower.contains('run')) {
      return Icons.directions_run;
    }
    return Icons.fitness_center;
  }
}
