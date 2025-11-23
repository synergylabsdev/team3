import '../../domain/models/inspirational_content.dart';
import '../../../../core/database/supabase_client.dart';
import '../../../../core/enums/cycle_phase.dart';

class InspirationalContentRepository {
  Future<InspirationalContent?> getDailyVerse({CyclePhase? targetPhase}) async {
    try {
      var query = SupabaseClient.from(
        'inspirational_content',
      ).select().eq('content_type', 'bible_verse').eq('is_active', true);

      // Prefer phase-specific verses, but also allow general ones
      if (targetPhase != null) {
        query = query.or(
          'target_phase.is.null,target_phase.eq.${targetPhase.toDbString()}',
        );
      } else {
        query = query.isFilter('target_phase', null);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        return InspirationalContent.fromJson(
          response.first as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      print('Error fetching daily verse: $e');
      return null;
    }
  }

  Future<InspirationalContent?> getWellnessTip({
    CyclePhase? targetPhase,
  }) async {
    try {
      var query = SupabaseClient.from(
        'inspirational_content',
      ).select().eq('content_type', 'wellness_tip').eq('is_active', true);

      if (targetPhase != null) {
        query = query.or(
          'target_phase.is.null,target_phase.eq.${targetPhase.toDbString()}',
        );
      } else {
        query = query.isFilter('target_phase', null);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        return InspirationalContent.fromJson(
          response.first as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      print('Error fetching wellness tip: $e');
      return null;
    }
  }
}
