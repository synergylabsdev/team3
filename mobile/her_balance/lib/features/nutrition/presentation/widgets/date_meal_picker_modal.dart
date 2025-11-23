import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/recipes/domain/models/recipe.dart';
import '../../../../features/meal_planning/data/repositories/meal_plan_repository.dart';

class DateMealPickerModal extends StatefulWidget {
  final Recipe recipe;

  const DateMealPickerModal({super.key, required this.recipe});

  @override
  State<DateMealPickerModal> createState() => _DateMealPickerModalState();
}

class _DateMealPickerModalState extends State<DateMealPickerModal> {
  final _mealPlanRepository = MealPlanRepository();
  DateTime _selectedDate = DateTime.now();
  String? _selectedMealType;

  Future<void> _addToMealPlan() async {
    if (_selectedMealType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a meal type')),
      );
      return;
    }

    try {
      await _mealPlanRepository.addMealPlan(
        recipeId: widget.recipe.id,
        plannedDate: _selectedDate,
        mealType: _selectedMealType!,
      );

      if (mounted) {
        Navigator.pop(context, {
          'date': _selectedDate,
          'mealType': _selectedMealType,
        });
      }
    } catch (e) {
      print('Error adding to meal plan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error adding to meal plan')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.inactiveColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add to Meal Plan',
                        style: GoogleFonts.tinos(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Date Picker
                      Text(
                        'Select Date',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.chevron_left, color: AppTheme.primaryColor),
                                  onPressed: () {
                                    setState(() {
                                      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.chevron_right, color: AppTheme.primaryColor),
                                  onPressed: () {
                                    setState(() {
                                      _selectedDate = _selectedDate.add(const Duration(days: 1));
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Meal Type Selection
                      Text(
                        'Select Meal',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMealTypeButton('breakfast', 'Breakfast'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMealTypeButton('lunch', 'Lunch'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMealTypeButton('dinner', 'Dinner'),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.bloomColor,
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
                              onTap: () => Navigator.pop(context),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: double.infinity,
                                height: 48,
                                alignment: Alignment.center,
                                child: Material(
                                  color: Colors.transparent,
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.bloomColor,
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
                              onTap: _addToMealPlan,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: double.infinity,
                                height: 48,
                                alignment: Alignment.center,
                                child: Material(
                                  color: Colors.transparent,
                                  child: Text(
                                    'Confirm',
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
          ),
        ],
      ),
    );
  }

  Widget _buildMealTypeButton(String mealType, String label) {
    final isSelected = _selectedMealType == mealType;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMealType = mealType;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.inactiveColor,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

