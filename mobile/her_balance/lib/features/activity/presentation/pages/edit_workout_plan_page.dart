import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/workout_planning/data/repositories/workout_plan_repository.dart';
import '../../../../features/workout_planning/domain/models/workout_plan.dart';

class EditWorkoutPlanPage extends StatefulWidget {
  const EditWorkoutPlanPage({super.key});

  @override
  State<EditWorkoutPlanPage> createState() => _EditWorkoutPlanPageState();
}

class _EditWorkoutPlanPageState extends State<EditWorkoutPlanPage> {
  final _workoutPlanRepository = WorkoutPlanRepository();
  DateTime _selectedWeekStart = _getWeekStart(DateTime.now());
  Map<DateTime, WorkoutPlanData> _workoutPlans = {};
  bool _isLoading = true;
  bool _isSaving = false;

  static DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final workouts = await _workoutPlanRepository.getWorkoutsForWeek(_selectedWeekStart);
      
      // Initialize all days of the week
      _workoutPlans = {};
      for (int i = 0; i < 7; i++) {
        final date = _selectedWeekStart.add(Duration(days: i));
        final workout = workouts.firstWhere(
          (w) => w.plannedDate.year == date.year &&
                 w.plannedDate.month == date.month &&
                 w.plannedDate.day == date.day,
          orElse: () => WorkoutPlan(
            id: '',
            userId: '',
            plannedDate: date,
            isRestDay: false,
            isCompleted: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        
        _workoutPlans[date] = WorkoutPlanData(
          activity: workout.activity ?? '',
          durationMinutes: workout.durationMinutes?.toString() ?? '',
          videoLink: workout.videoLink ?? '',
          isRestDay: workout.isRestDay,
        );
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading workouts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateWeek(int weeks) async {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.add(Duration(days: weeks * 7));
    });
    await _loadWorkouts();
  }

  Future<void> _saveWorkoutPlan() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final plans = <WorkoutPlan>[];
      
      for (int i = 0; i < 7; i++) {
        final date = _selectedWeekStart.add(Duration(days: i));
        final data = _workoutPlans[date]!;
        
        if (data.isRestDay || data.activity.isNotEmpty) {
          plans.add(WorkoutPlan(
            id: '',
            userId: '',
            plannedDate: date,
            activity: data.isRestDay ? null : data.activity.isEmpty ? null : data.activity,
            durationMinutes: data.isRestDay || data.durationMinutes.isEmpty
                ? null
                : int.tryParse(data.durationMinutes),
            videoLink: data.isRestDay || data.videoLink.isEmpty
                ? null
                : data.videoLink,
            isRestDay: data.isRestDay,
            isCompleted: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }
      }

      await _workoutPlanRepository.saveWeekWorkoutPlans(plans);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout plan saved successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving workout plan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving workout plan')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
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
          'Edit Workout Plan',
          style: GoogleFonts.gildaDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: AppTheme.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Week Navigation
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.chevron_left, color: AppTheme.primaryColor),
                        onPressed: () => _navigateWeek(-1),
                      ),
                      Text(
                        'Week of ${DateFormat('MMMM d, yyyy').format(_selectedWeekStart)}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_right, color: AppTheme.primaryColor),
                        onPressed: () => _navigateWeek(1),
                      ),
                    ],
                  ),
                ),

                // Workout Plans List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      for (int i = 0; i < 7; i++)
                        _buildDayCard(_selectedWeekStart.add(Duration(days: i))),
                    ],
                  ),
                ),

                // Confirm Button
                Container(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isSaving ? AppTheme.primaryColor.withOpacity(0.6) : AppTheme.primaryColor,
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
                          onTap: _isSaving ? null : _saveWorkoutPlan,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            height: 48,
                            alignment: Alignment.center,
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Material(
                                    color: Colors.transparent,
                                    child: Text(
                                      'Confirm Plan',
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
                ),
              ],
            ),
    );
  }

  Widget _buildDayCard(DateTime date) {
    final data = _workoutPlans[date]!;
    final dayName = DateFormat('EEEE').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header with rest day checkbox
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dayName,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Row(
                children: [
                  Text(
                    'Rest Day',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        data.isRestDay = !data.isRestDay;
                        if (data.isRestDay) {
                          data.activity = '';
                          data.durationMinutes = '';
                          data.videoLink = '';
                        }
                      });
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: data.isRestDay
                              ? AppTheme.primaryColor
                              : AppTheme.inactiveColor,
                          width: 2,
                        ),
                        color: data.isRestDay
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                      ),
                      child: data.isRestDay
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
            ],
          ),
          const SizedBox(height: 16),

          if (data.isRestDay)
            Row(
              children: [
                Icon(
                  Icons.nightlight_round,
                  color: const Color(0xFFA1B69C),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recovery day — your body will thank you',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFFA1B69C),
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                // Activity and Duration row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Activity',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: TextEditingController(text: data.activity)
                              ..selection = TextSelection.collapsed(
                                offset: data.activity.length,
                              ),
                            onChanged: (value) {
                              data.activity = value;
                            },
                            decoration: InputDecoration(
                              hintText: 'Walk',
                              hintStyle: GoogleFonts.inter(
                                color: const Color(0xFF9B9B9B),
                              ),
                              filled: true,
                              fillColor: AppTheme.backgroundColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Duration (mins)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: TextEditingController(text: data.durationMinutes)
                              ..selection = TextSelection.collapsed(
                                offset: data.durationMinutes.length,
                              ),
                            onChanged: (value) {
                              data.durationMinutes = value;
                            },
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '30',
                              hintStyle: GoogleFonts.inter(
                                color: const Color(0xFF9B9B9B),
                              ),
                              filled: true,
                              fillColor: AppTheme.backgroundColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Video Link
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.attach_file,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Video Link (optional)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: TextEditingController(text: data.videoLink)
                        ..selection = TextSelection.collapsed(
                          offset: data.videoLink.length,
                        ),
                      onChanged: (value) {
                        data.videoLink = value;
                      },
                      decoration: InputDecoration(
                        hintText: 'YouTube or Instagram link, etc link',
                        hintStyle: GoogleFonts.inter(
                          color: const Color(0xFF9B9B9B),
                        ),
                        filled: true,
                        fillColor: AppTheme.backgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class WorkoutPlanData {
  String activity;
  String durationMinutes;
  String videoLink;
  bool isRestDay;

  WorkoutPlanData({
    required this.activity,
    required this.durationMinutes,
    required this.videoLink,
    required this.isRestDay,
  });
}

