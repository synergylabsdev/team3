import 'package:flutter/material.dart';

enum CyclePhase {
  root('ROOT', 'MENSTRUAL', 'Go deep. Restore your energy.', Color(0xFFE68A6D)),
  bloom('BLOOM', 'FOLLICULAR', 'Create. Rise. Renew.', Color(0xFFA1B69C)),
  shine('SHINE', 'OVULATION', 'Radiate. Connect. Thrive.', Color(0xFFFAB177)),
  harvest('HARVEST', 'LUTEAL', 'Reflect. Ground. Prepare.', Color(0xFFE2A49A));

  final String name;
  final String subtitle;
  final String tagline;
  final Color color;

  const CyclePhase(this.name, this.subtitle, this.tagline, this.color);

  // Convert from database enum string
  static CyclePhase fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'root':
        return CyclePhase.root;
      case 'bloom':
        return CyclePhase.bloom;
      case 'shine':
        return CyclePhase.shine;
      case 'harvest':
        return CyclePhase.harvest;
      default:
        return CyclePhase.root;
    }
  }

  // Convert to database enum string
  String toDbString() {
    return name.toLowerCase();
  }

  // Calculate phase based on cycle day
  static CyclePhase calculatePhase(int cycleDay) {
    if (cycleDay >= 1 && cycleDay <= 5) {
      return CyclePhase.root;
    } else if (cycleDay >= 6 && cycleDay <= 13) {
      return CyclePhase.bloom;
    } else if (cycleDay >= 14 && cycleDay <= 16) {
      return CyclePhase.shine;
    } else {
      return CyclePhase.harvest;
    }
  }
}
