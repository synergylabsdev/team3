import '../../domain/models/cycle.dart';
import '../../../../core/database/supabase_client.dart';

class CycleRepository {
  Future<Cycle?> getActiveCycle() async {
    final userId = SupabaseClient.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await SupabaseClient.from('cycles')
          .select()
          .eq('user_id', userId)
          .isFilter('end_date', null)
          .order('start_date', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        return Cycle.fromJson(response.first as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error fetching active cycle: $e');
      return null;
    }
  }

  Future<Cycle> createCycle(DateTime startDate) async {
    final userId = SupabaseClient.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await SupabaseClient.from('cycles')
        .insert({
          'user_id': userId,
          'start_date': startDate.toIso8601String().split('T')[0],
        })
        .select()
        .single();

    return Cycle.fromJson(response as Map<String, dynamic>);
  }

  Future<void> endCycle(String cycleId, DateTime endDate) async {
    // Calculate cycle length
    final cycle = await SupabaseClient.from('cycles')
        .select('start_date')
        .eq('id', cycleId)
        .single();

    final startDate = DateTime.parse(
        cycle['start_date'] as String);
    final cycleLength = endDate.difference(startDate).inDays + 1;

    await SupabaseClient.from('cycles')
        .update({
          'end_date': endDate.toIso8601String().split('T')[0],
          'cycle_length_days': cycleLength,
        })
        .eq('id', cycleId);
  }

  Future<List<Cycle>> getCycleHistory({int limit = 10}) async {
    final userId = SupabaseClient.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await SupabaseClient.from('cycles')
          .select()
          .eq('user_id', userId)
          .order('start_date', ascending: false)
          .limit(limit);

      return (response as List)
          .map((e) => Cycle.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching cycle history: $e');
      return [];
    }
  }
}
