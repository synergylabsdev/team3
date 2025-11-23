import 'package:intl/intl.dart';
import '../enums/cycle_phase.dart';

class CycleCalculator {
  /// Calculate the current cycle day based on last period start date
  /// Returns null if no period start date is set
  static int? calculateCycleDay(DateTime? lastPeriodStart, int avgCycleLength) {
    if (lastPeriodStart == null) return null;
    
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final periodStartDate = DateTime(
      lastPeriodStart.year,
      lastPeriodStart.month,
      lastPeriodStart.day,
    );
    
    final difference = todayDate.difference(periodStartDate).inDays;
    
    // If we're past the average cycle length, we might be in a new cycle
    // For now, we'll use modulo to wrap around
    if (difference < 0) return null;
    
    final cycleDay = (difference % avgCycleLength) + 1;
    return cycleDay;
  }

  /// Calculate the current cycle phase
  static CyclePhase? calculatePhase(DateTime? lastPeriodStart, int avgCycleLength) {
    final cycleDay = calculateCycleDay(lastPeriodStart, avgCycleLength);
    if (cycleDay == null) return null;
    return CyclePhase.calculatePhase(cycleDay);
  }

  /// Check if user is currently on their period
  /// Assumes period lasts for avgPeriodLength days starting from lastPeriodStart
  static bool isOnPeriod(DateTime? lastPeriodStart, int avgPeriodLength) {
    if (lastPeriodStart == null) return false;
    
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final periodStartDate = DateTime(
      lastPeriodStart.year,
      lastPeriodStart.month,
      lastPeriodStart.day,
    );
    
    final difference = todayDate.difference(periodStartDate).inDays;
    return difference >= 0 && difference < avgPeriodLength;
  }

  /// Format date for display
  static String formatDate(DateTime date) {
    return DateFormat('MM/dd/yyyy').format(date);
  }

  /// Parse date from string
  static DateTime? parseDate(String dateString) {
    try {
      return DateFormat('MM/dd/yyyy').parse(dateString);
    } catch (e) {
      return null;
    }
  }
}

