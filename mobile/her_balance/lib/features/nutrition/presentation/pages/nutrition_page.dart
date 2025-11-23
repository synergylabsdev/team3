import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import 'tabs/nutrition_overview_tab.dart';
import 'tabs/nutrition_cookbook_tab.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  int _selectedIndex = 0;
  final GlobalKey _overviewTabKey = GlobalKey();
  final GlobalKey _cookbookTabKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Your Fuel',
                  textAlign: TextAlign.left,
                  style: GoogleFonts.gildaDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF4A4A4A),
                  ),
                ),
              ),
            ),
            // iOS Style Segmented Control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _buildSegmentedControl(),
            ),
            // Tab Views
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  NutritionOverviewTab(key: _overviewTabKey),
                  NutritionCookbookTab(key: _cookbookTabKey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildSegmentButton(label: 'Overview', index: 0)),
          Expanded(child: _buildSegmentButton(label: 'Cookbook', index: 1)),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({required String label, required int index}) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        final previousIndex = _selectedIndex;
        setState(() {
          _selectedIndex = index;
        });
        // Refresh the newly selected tab
        if (previousIndex != index) {
          _refreshTab(index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Futura PT',
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  void _refreshTab(int index) {
    if (index == 0) {
      final state = _overviewTabKey.currentState;
      if (state != null) {
        (state as dynamic).refresh();
      }
    } else if (index == 1) {
      final state = _cookbookTabKey.currentState;
      if (state != null) {
        (state as dynamic).refresh();
      }
    }
  }
}
