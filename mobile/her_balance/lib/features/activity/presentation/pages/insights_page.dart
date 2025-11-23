import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/enums/cycle_phase.dart';
import '../../../../../core/utils/cycle_calculator.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../../profile/domain/models/profile.dart';
import '../../../daily_logs/data/repositories/daily_log_repository.dart';
import '../../../workout_planning/data/repositories/workout_plan_repository.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  final _profileRepository = ProfileRepository();
  final _dailyLogRepository = DailyLogRepository();
  final _workoutPlanRepository = WorkoutPlanRepository();

  Profile? _profile;
  CyclePhase? _cyclePhase;
  int? _cycleDay;
  bool _isLoading = true;
  List<String> _monthlySymptoms = [];
  int _avgWeeklyWorkouts = 0;
  int _avgDailySteps = 0;

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
      final profile = await _profileRepository.getCurrentUserProfile();
      if (profile == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final cycleDay = CycleCalculator.calculateCycleDay(
        profile.lastPeriodStart,
        profile.avgCycleLength,
      );
      final cyclePhase = cycleDay != null
          ? CycleCalculator.calculatePhase(
              profile.lastPeriodStart,
              profile.avgCycleLength,
            )
          : null;

      // Load recent symptoms from daily logs (last 30 days)
      final monthlySymptoms = await _dailyLogRepository.getMonthlySymptoms();

      // Load average daily steps (last 30 days)
      final avgDailySteps = await _dailyLogRepository.getAverageDailySteps();

      // Load average weekly workouts (last 30 days)
      final avgWeeklyWorkouts = await _workoutPlanRepository.getAverageWeeklyWorkouts();

      setState(() {
        _profile = profile;
        _cyclePhase = cyclePhase ?? CyclePhase.root;
        _cycleDay = cycleDay;
        _monthlySymptoms = monthlySymptoms;
        _avgDailySteps = avgDailySteps;
        _avgWeeklyWorkouts = avgWeeklyWorkouts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading insights: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  DateTime? _getLastPeriodStart() {
    return _profile?.lastPeriodStart;
  }

  DateTime? _getExpectedNextPeriod() {
    if (_profile?.lastPeriodStart == null || _cycleDay == null) {
      return null;
    }
    final lastStart = _profile!.lastPeriodStart!;
    final avgLength = _profile!.avgCycleLength;
    return lastStart.add(Duration(days: avgLength));
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Insights',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final cyclePhase = _cyclePhase ?? CyclePhase.root;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Insights',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.eco,
                        color: AppTheme.primaryColor,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'YOUR INSIGHTS',
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

                // Current Cycle Phase Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.eco,
                            color: cyclePhase.color,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${cyclePhase.name} Phase',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: cyclePhase.color,
                                ),
                              ),
                              Text(
                                cyclePhase.subtitle,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Your Cycle Day',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              Text(
                                _cycleDay?.toString() ?? '-',
                                style: GoogleFonts.inter(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: cyclePhase.color,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Average Period',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_profile?.avgPeriodLength ?? 7} days',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Average Cycle',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_profile?.avgCycleLength ?? 28} days',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Important Dates Section
                Text(
                  'Important Dates',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDateCard(
                  icon: Icons.calendar_today,
                  title: 'Last Period Started',
                  date: _formatDate(_getLastPeriodStart()),
                  color: cyclePhase.color,
                ),
                const SizedBox(height: 12),
                _buildDateCard(
                  icon: Icons.calendar_today,
                  title: 'Expected Next Period',
                  date: _formatDate(_getExpectedNextPeriod()),
                  color: cyclePhase.color,
                ),
                const SizedBox(height: 24),

                // Monthly Symptoms Logged Section
                Text(
                  'Monthly Symptoms Logged',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _monthlySymptoms.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'No symptoms logged this month. Start logging to see insights!',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _monthlySymptoms
                            .map((symptom) => _buildSymptomTag(
                                  symptom,
                                  cyclePhase.color,
                                ))
                            .toList(),
                      ),
                const SizedBox(height: 24),

                // Activity Overview Section
                Text(
                  'Activity Overview',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildActivityCard(
                  icon: Icons.fitness_center,
                  title: 'Average Weekly Workouts',
                  value: '$_avgWeeklyWorkouts days',
                  progress: _avgWeeklyWorkouts / 7.0,
                  color: cyclePhase.color,
                ),
                const SizedBox(height: 12),
                _buildActivityCard(
                  icon: Icons.directions_walk,
                  title: 'Average Daily Steps',
                  value: '$_avgDailySteps / 10,000',
                  progress: _avgDailySteps / 10000.0,
                  color: cyclePhase.color,
                ),
                const SizedBox(height: 24),

                // Phase Insights Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cyclePhase.color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.spa,
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'PHASE INSIGHTS',
                              style: GoogleFonts.gildaDisplay(
                                fontSize: 24,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'What\'s Happening',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getPhaseInsightText(cyclePhase),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getPhaseInsightText(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.root:
        return 'This is the start of your cycle. Hormones like estrogen and progesterone are at their lowest during menstruation, which is why you may feel more tired, introspective, or sensitive during this time. Your body is working hard to shed the uterine lining, and inflammation may be slightly elevated as a result. It\'s a time of natural release both physically and emotionally.';
      case CyclePhase.bloom:
        return 'During the follicular phase, estrogen levels begin to rise, bringing increased energy and a sense of renewal. This is a great time for new beginnings, creative projects, and social activities. Your body is preparing for ovulation, and you may notice improved mood and motivation.';
      case CyclePhase.shine:
        return 'Ovulation is your peak time! Estrogen and testosterone are at their highest, giving you maximum energy, confidence, and social drive. This is the ideal time for important meetings, challenging workouts, and social events. Your body is primed for peak performance.';
      case CyclePhase.harvest:
        return 'During the luteal phase, progesterone rises and estrogen begins to decline. You may feel more introspective, crave comfort, and need more rest. This is a natural time for reflection, planning, and self-care. Your body is preparing for either pregnancy or the next cycle.';
    }
  }

  Widget _buildDateCard({
    required IconData icon,
    required String title,
    required String date,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
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
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required String title,
    required String value,
    required double progress,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress > 1.0 ? 1.0 : progress,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

