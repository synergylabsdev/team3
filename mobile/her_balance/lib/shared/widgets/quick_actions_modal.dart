import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../features/activity/presentation/pages/insights_page.dart';
import '../../presentation/main_navigation_page.dart';
import '../../features/nutrition/presentation/pages/meal_plan_page.dart';
import '../../features/activity/presentation/widgets/log_steps_modal.dart';
import '../../features/daily_logs/data/repositories/daily_log_repository.dart';

class QuickActionsModal extends StatefulWidget {
  const QuickActionsModal({super.key});

  @override
  State<QuickActionsModal> createState() => _QuickActionsModalState();

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickActionsModal(),
    );
  }
}

class _QuickActionsModalState extends State<QuickActionsModal> {
  final _dailyLogRepository = DailyLogRepository();

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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$steps steps added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging steps: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showLogStepsModal() async {
    final todayLog = await _dailyLogRepository.getTodayLog();
    final currentSteps = todayLog?.stepCount ?? 0;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LogStepsModal(
        currentSteps: currentSteps,
        onConfirm: _logSteps,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Map<String, dynamic>>[
      {
        'title': 'Log Meal',
        'description': 'Track what you ate today',
        'icon': Icons.restaurant,
        'color': AppTheme.primaryColor,
        'onTap': () {
          Navigator.of(context).pop();
          MainNavigationPage.switchToTab(2);
        },
      },
      {
        'title': 'Plan Week',
        'description': 'Build your weekly meal plan',
        'icon': Icons.calendar_today,
        'color': AppTheme.primaryColor,
        'onTap': () {
          Navigator.of(context).pop();
          MainNavigationPage.switchToTab(2);
          Future.delayed(const Duration(milliseconds: 100), () {
            if (context.mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MealPlanPage()),
              );
            }
          });
        },
      },
      {
        'title': 'Log Steps',
        'description': 'Record your daily activity',
        'icon': Icons.directions_walk,
        'color': const Color(0xFF4CAF50),
        'onTap': () async {
          Navigator.of(context).pop();
          await _showLogStepsModal();
        },
      },
      {
        'title': 'View Insights',
        'description': 'See your health trends',
        'icon': Icons.trending_up,
        'color': const Color(0xFFFFB74D),
        'onTap': () {
          Navigator.of(context).pop();
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => const InsightsPage()));
        },
      },
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Text(
            'Quick Actions',
            style: GoogleFonts.tinos(
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          // Action items
          ...actions.map((action) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: InkWell(
                onTap: () {
                  final onTap = action['onTap'] as VoidCallback?;
                  if (onTap != null) {
                    onTap();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          action['icon'] as IconData,
                          color: action['color'] as Color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              action['title'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              action['description'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
            );
          }),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }
}
