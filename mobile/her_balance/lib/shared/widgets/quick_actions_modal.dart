import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../features/activity/presentation/pages/insights_page.dart';

class QuickActionsModal extends StatelessWidget {
  const QuickActionsModal({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      {
        'title': 'Log Meal',
        'description': 'Track what you ate today',
        'icon': Icons.restaurant,
        'color': AppTheme.primaryColor,
        'onTap': () {
          // TODO: Navigate to log meal page
        },
      },
      {
        'title': 'Plan Week',
        'description': 'Build your weekly meal plan',
        'icon': Icons.calendar_today,
        'color': AppTheme.primaryColor,
        'onTap': () {
          // TODO: Navigate to meal planning page
        },
      },
      {
        'title': 'Log Steps',
        'description': 'Record your daily activity',
        'icon': Icons.directions_walk,
        'color': const Color(0xFF4CAF50),
        'onTap': () {
          // TODO: Navigate to log steps page
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

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickActionsModal(),
    );
  }
}
