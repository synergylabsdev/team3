import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../data/repositories/daily_log_repository.dart';
import '../../../../core/enums/cycle_phase.dart';
import '../../../../core/utils/cycle_calculator.dart';
import '../../../../features/profile/data/repositories/profile_repository.dart';

class LogSymptomsPage extends StatefulWidget {
  final CyclePhase? cyclePhase;
  
  const LogSymptomsPage({super.key, this.cyclePhase});

  @override
  State<LogSymptomsPage> createState() => _LogSymptomsPageState();

  static Future<void> show(BuildContext context, {CyclePhase? cyclePhase}) {
    return showCupertinoModalPopup(
      context: context,
      builder: (context) => LogSymptomsPage(cyclePhase: cyclePhase),
    ).then((_) {});
  }
}

class _LogSymptomsPageState extends State<LogSymptomsPage> {
  final Map<String, Set<String>> selectedSymptoms = {};
  final _dailyLogRepository = DailyLogRepository();
  final _profileRepository = ProfileRepository();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  CyclePhase? _currentPhase;

  final Map<String, List<String>> symptoms = {
    'Physical': [
      'Cramps',
      'Headache',
      'Bloating',
      'Breast tenderness',
      'Fatigue',
      'Back pain',
    ],
    'Energy': [
      'Low energy',
      'High energy',
      'Restless',
      'Motivated',
      'Sluggish',
    ],
    'Mood': [
      'Anxious',
      'Irritable',
      'Happy',
      'Calm',
      'Emotional',
      'Focused',
    ],
    'Sleep': [
      'Insomnia',
      'Restful sleep',
      'Disrupted sleep',
      'Vivid dreams',
    ],
    'Digestion': [
      'Nausea',
      'Constipation',
      'Diarrhea',
      'Food cravings',
      'Loss of appetite',
    ],
    'Other': [
      'Acne',
      'Hot flashes',
      'Dizziness',
      'Joint pain',
    ],
  };

  final Map<String, IconData> categoryIcons = {
    'Physical': Icons.favorite_border,
    'Energy': Icons.bolt,
    'Mood': Icons.sentiment_dissatisfied,
    'Sleep': Icons.bedtime_outlined,
    'Digestion': Icons.restaurant_menu,
    'Other': Icons.water_drop_outlined,
  };

  Color _getCategoryColor(String category) {
    final cyclePhase = widget.cyclePhase ?? CyclePhase.root;
    final phaseColor = cyclePhase.color;
    
    switch (category) {
      case 'Physical':
        return AppTheme.primaryColor; // Reddish-brown
      case 'Energy':
        return const Color(0xFFFAB177); // Orange-brown
      case 'Mood':
        return const Color(0xFFA1B69C); // Muted green
      case 'Sleep':
        return AppTheme.primaryColor; // Reddish-brown
      default:
        return phaseColor;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeSymptoms();
    _loadCurrentPhase();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _initializeSymptoms() {
    for (var category in symptoms.keys) {
      selectedSymptoms[category] = <String>{};
    }
  }

  Future<void> _loadCurrentPhase() async {
    final profile = await _profileRepository.getCurrentUserProfile();
    if (profile != null) {
      setState(() {
        _currentPhase = CycleCalculator.calculatePhase(
          profile.lastPeriodStart,
          profile.avgCycleLength,
        );
      });
    }
  }

  void _toggleSymptom(String category, String symptom) {
    setState(() {
      if (selectedSymptoms[category]!.contains(symptom)) {
        selectedSymptoms[category]!.remove(symptom);
      } else {
        selectedSymptoms[category]!.add(symptom);
      }
    });
  }

  Future<void> _saveSymptoms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Flatten all selected symptoms into a single list
      final allSymptoms = <String>[];
      for (var categorySymptoms in selectedSymptoms.values) {
        allSymptoms.addAll(categorySymptoms);
      }

      final today = DateTime.now();
      await _dailyLogRepository.upsertDailyLog(
        logDate: today,
        recordedPhase: _currentPhase,
        symptoms: allSymptoms,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Symptoms saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cyclePhase = widget.cyclePhase ?? CyclePhase.root;
    final phaseColor = cyclePhase.color;
    
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
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
            // Drag handle / Notch
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFEAECF1),
                borderRadius: BorderRadius.circular(55),
              ),
            ),
            // Title with close button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Close button on the left
                  Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Color(0xFF4A4A4A),
                        size: 24,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  // Title centered
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        'Log symptoms',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.visible,
                        style: GoogleFonts.gildaDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF4A4A4A),
                          height: 1.5, // 150% line-height
                        ),
                      ),
                    ),
                  ),
                  // Spacer to balance the close button
                  const SizedBox(width: 40),
                ],
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
            ...symptoms.entries.map((entry) {
              final category = entry.key;
              final categorySymptoms = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        categoryIcons[category],
                        color: AppTheme.textPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            category,
                            overflow: TextOverflow.visible,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categorySymptoms.map((symptom) {
                      final isSelected =
                          selectedSymptoms[category]!.contains(symptom);
                      final categoryColor = _getCategoryColor(category);
                      return GestureDetector(
                        onTap: () => _toggleSymptom(category, symptom),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? categoryColor
                                : AppTheme.backgroundColor,
                            border: Border.all(
                              color: isSelected
                                  ? categoryColor
                                  : Colors.grey[300]!,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              symptom,
                              overflow: TextOverflow.visible,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }).toList(),
            const SizedBox(height: 20),
            // Additional Notes
            Text(
              'Additional Notes (Optional)',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Any other symptoms or observations...',
                hintStyle: GoogleFonts.inter(
                  color: const Color(0xFF9B9B9B),
                ),
                filled: true,
                fillColor: AppTheme.backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
    // Bottom button
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
          child: Container(
            decoration: BoxDecoration(
              color: _isLoading ? phaseColor.withOpacity(0.6) : phaseColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: phaseColor,
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
                onTap: _isLoading ? null : _saveSymptoms,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  alignment: Alignment.center,
                  child: _isLoading
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
                            'Save Symptoms',
                            overflow: TextOverflow.visible,
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              height: 1.5, // 150% line-height (24px / 16px)
                            ),
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
      ),
    );
  }
}
