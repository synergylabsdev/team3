import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';

class EditPeriodModal extends StatefulWidget {
  const EditPeriodModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EditPeriodModal(),
    );
  }

  @override
  State<EditPeriodModal> createState() => _EditPeriodModalState();
}

class _EditPeriodModalState extends State<EditPeriodModal> {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  int _avgCycleLength = 28;
  bool _syncWithLunar = false;
  bool _showLunarInfo = false;

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.inactiveColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Edit period',
              style: GoogleFonts.gildaDisplay(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period Duration Input
                  Text(
                    'What\'s your average period duration?',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('MM/dd/yyyy').format(_selectedDate),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Cycle Length Input
                  Text(
                    'What\'s your average cycle length?',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: TextEditingController(text: '$_avgCycleLength'),
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (value) {
                              final length = int.tryParse(value);
                              if (length != null) {
                                setState(() {
                                  _avgCycleLength = length;
                                });
                              }
                            },
                          ),
                        ),
                        Text(
                          'days',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Calendar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Month Navigation
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(Icons.chevron_left, color: AppTheme.primaryColor),
                              onPressed: _previousMonth,
                            ),
                            Text(
                              DateFormat('MMMM yyyy').format(_currentMonth),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.chevron_right, color: AppTheme.primaryColor),
                              onPressed: _nextMonth,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Days of week
                        Row(
                          children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                              .map((day) => Expanded(
                                    child: Center(
                                      child: Text(
                                        day,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        // Calendar Grid
                        _buildCalendarGrid(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sync with Lunar Cycle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Sync with Lunar Cycle',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('🌙', style: TextStyle(fontSize: 20)),
                        ],
                      ),
                      Switch(
                        value: _syncWithLunar,
                        onChanged: (value) {
                          setState(() {
                            _syncWithLunar = value;
                            if (value) {
                              _showLunarInfo = true;
                            }
                          });
                        },
                        activeColor: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                  if (_syncWithLunar) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your data now follows lunar rhythm (auto-sync daily).',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Current: Waxing Moon 🌑 • Day 8 of 29.5',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Don't have a regular cycle?
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showLunarInfo = !_showLunarInfo;
                      });
                    },
                    child: Text(
                      'Don\'t have a regular cycle?',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  if (_showLunarInfo) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'If you\'re not currently menstruating - or your cycle is irregular - we suggest following the lunar cycle as your guide. Even during pregnancy, while using hormonal birth control, or throughout peri/menopause, syncing your nutrition with natural rhythms can still support hormone balance and overall well-being. Toggle on "Follow the Lunar Cycle" to sync your phases with the moon instead of your period.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Save Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Save period data
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Save Period Data',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    final previousMonthDays = firstWeekday - 1;
    final previousMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    final daysInPreviousMonth = DateTime(previousMonth.year, previousMonth.month + 1, 0).day;

    final List<Widget> dayWidgets = [];

    // Previous month days
    for (int i = previousMonthDays - 1; i >= 0; i--) {
      final day = daysInPreviousMonth - i;
      dayWidgets.add(_buildDateCell(day, false));
    }

    // Current month days
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final isSelected = date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;
      dayWidgets.add(_buildDateCell(day, true, isSelected: isSelected));
    }

    // Next month days
    final totalCells = dayWidgets.length;
    final remainingCells = 42 - totalCells;
    for (int day = 1; day <= remainingCells; day++) {
      dayWidgets.add(_buildDateCell(day, false));
    }

    return Column(
      children: [
        for (int i = 0; i < 6; i++)
          Row(
            children: [
              for (int j = 0; j < 7; j++)
                Expanded(
                  child: dayWidgets[i * 7 + j],
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildDateCell(int day, bool isCurrentMonth, {bool isSelected = false}) {
    return GestureDetector(
      onTap: isCurrentMonth
          ? () {
              setState(() {
                _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, day);
              });
            }
          : null,
      child: Container(
        margin: const EdgeInsets.all(2),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withOpacity(0.2)
                : (isCurrentMonth ? AppTheme.backgroundColor : Colors.transparent),
            shape: BoxShape.circle,
            border: isSelected
                ? Border.all(color: AppTheme.primaryColor, width: 2)
                : null,
          ),
          child: Center(
            child: Text(
              '$day',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isCurrentMonth
                    ? (isSelected ? AppTheme.primaryColor : AppTheme.textPrimary)
                    : AppTheme.inactiveColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

