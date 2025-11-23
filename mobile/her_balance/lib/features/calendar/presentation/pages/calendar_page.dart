import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/enums/cycle_phase.dart';
import '../widgets/edit_period_modal.dart';
import '../../../../features/daily_logs/presentation/pages/log_symptoms_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  CyclePhase _currentPhase = CyclePhase.root;
  int _cycleDay = 5;
  DateTime? _nextPeriod;

  @override
  void initState() {
    super.initState();
    _loadCycleData();
  }

  void _loadCycleData() {
    // TODO: Load actual cycle data
    setState(() {
      _currentPhase = CyclePhase.root;
      _cycleDay = 5;
      _nextPeriod = DateTime.now().add(const Duration(days: 24));
    });
  }

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

  Color _getDateColor(DateTime date) {
    // TODO: Calculate actual phase colors based on cycle
    final day = date.day;
    if (day >= 1 && day <= 7) {
      return const Color(0xFFE68A6D); // Red/pink for period
    } else if (day >= 8 && day <= 14) {
      return const Color(0xFFE2A49A); // Light pink
    } else if (day >= 15 && day <= 22) {
      return const Color(0xFFFAB177); // Yellow
    } else {
      return const Color(0xFFA1B69C); // Green
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Calendar',
                  style: GoogleFonts.gildaDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Info Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        label: 'Your Phase',
                        value: _currentPhase.subtitle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCycleCard(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        label: 'Next Period',
                        value: _nextPeriod != null
                            ? DateFormat('MMM d').format(_nextPeriod!)
                            : 'N/A',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Calendar Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
                            fontSize: 18,
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
                    const SizedBox(height: 20),
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

              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
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
                              EditPeriodModal.show(context);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              height: 48,
                              alignment: Alignment.center,
                              child: Material(
                                color: Colors.transparent,
                                child: Text(
                                  'Edit Period',
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
                              LogSymptomsPage.show(context, cyclePhase: _currentPhase);
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
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleCard() {
    final progress = _cycleDay / 28.0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Your Cycle',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    backgroundColor: AppTheme.backgroundColor,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Day',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '$_cycleDay',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
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

    // Calculate days from previous month to show
    final previousMonthDays = firstWeekday - 1;
    final previousMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    final daysInPreviousMonth = DateTime(previousMonth.year, previousMonth.month + 1, 0).day;

    final List<Widget> dayWidgets = [];

    // Previous month days
    for (int i = previousMonthDays - 1; i >= 0; i--) {
      final day = daysInPreviousMonth - i;
      dayWidgets.add(_buildDateCell(
        day: day,
        isCurrentMonth: false,
        date: DateTime(previousMonth.year, previousMonth.month, day),
      ));
    }

    // Current month days
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      dayWidgets.add(_buildDateCell(
        day: day,
        isCurrentMonth: true,
        date: date,
        isSelected: date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day,
      ));
    }

    // Next month days to fill the grid
    final totalCells = dayWidgets.length;
    final remainingCells = 42 - totalCells; // 6 rows * 7 days
    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    for (int day = 1; day <= remainingCells; day++) {
      dayWidgets.add(_buildDateCell(
        day: day,
        isCurrentMonth: false,
        date: DateTime(nextMonth.year, nextMonth.month, day),
      ));
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

  Widget _buildDateCell({
    required int day,
    required bool isCurrentMonth,
    required DateTime date,
    bool isSelected = false,
  }) {
    final dateColor = isCurrentMonth ? _getDateColor(date) : AppTheme.inactiveColor;
    final isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
      },
      child: Container(
        margin: const EdgeInsets.all(4),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? null
                    : (isCurrentMonth ? dateColor.withOpacity(0.2) : Colors.transparent),
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
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                    color: isCurrentMonth
                        ? (isSelected ? AppTheme.primaryColor : AppTheme.textPrimary)
                        : AppTheme.inactiveColor,
                  ),
                ),
              ),
            ),
            // Small dot indicator (for logged symptoms/events)
            if (isCurrentMonth && day % 5 == 0)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
