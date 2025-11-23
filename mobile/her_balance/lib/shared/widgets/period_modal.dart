import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/enums/cycle_phase.dart';
import '../../core/utils/cycle_calculator.dart';
import '../../features/cycle/data/repositories/cycle_repository.dart';
import '../../features/profile/data/repositories/profile_repository.dart';

class PeriodModal extends StatefulWidget {
  final bool isStartPeriod;
  final DateTime? initialDate;
  final VoidCallback? onSaved;
  final CyclePhase? cyclePhase;

  const PeriodModal({
    super.key,
    required this.isStartPeriod,
    this.initialDate,
    this.onSaved,
    this.cyclePhase,
  });

  @override
  State<PeriodModal> createState() => _PeriodModalState();

  static void show(BuildContext context,
      {required bool isStartPeriod, VoidCallback? onSaved, CyclePhase? cyclePhase}) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => PeriodModal(
        isStartPeriod: isStartPeriod,
        onSaved: onSaved,
        cyclePhase: cyclePhase,
      ),
    );
  }
}

class _PeriodModalState extends State<PeriodModal> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  final _cycleRepository = CycleRepository();
  final _profileRepository = ProfileRepository();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  Future<void> _selectDate() async {
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
  }

  Future<void> _savePeriod() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.isStartPeriod) {
        // Create new cycle and update profile
        await _cycleRepository.createCycle(_selectedDate);
        await _profileRepository.updateLastPeriodStart(_selectedDate);
      } else {
        // End current cycle
        final activeCycle = await _cycleRepository.getActiveCycle();
        if (activeCycle != null) {
          await _cycleRepository.endCycle(activeCycle.id, _selectedDate);
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isStartPeriod
                  ? 'Period start logged successfully'
                  : 'Period end logged successfully',
            ),
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
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFEAECF1),
                borderRadius: BorderRadius.circular(55),
              ),
            ),
            // Leaf icon
            Image.asset(
              'assets/leaf.png',
              width: 56,
              height: 56,
            ),
            const SizedBox(height: 16),
            // Question text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Material(
                color: Colors.transparent,
                child: Text(
                  widget.isStartPeriod
                      ? 'When did your Period start?'
                      : 'When did your Period end?',
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.visible,
                  style: GoogleFonts.gildaDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF4A4A4A),
                    height: 1.5, // 150% line-height (30px / 20px)
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          // Date input field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                        CycleCalculator.formatDate(_selectedDate),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_today,
                    color: phaseColor,
                    size: 20,
                  ),
                ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Log Period button
          Padding(
            padding: const EdgeInsets.all(20),
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
                  onTap: _isLoading ? null : _savePeriod,
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
                              'Log Period',
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
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    ),
    );
  }
}
