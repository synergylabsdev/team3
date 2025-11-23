import '../../domain/models/profile.dart';
import '../../../../core/database/supabase_client.dart';

class ProfileRepository {
  Future<Profile?> getCurrentUserProfile() async {
    final userId = SupabaseClient.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await SupabaseClient.from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return Profile.fromJson(response);
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final userId = SupabaseClient.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await SupabaseClient.from('profiles')
        .update(updates)
        .eq('id', userId);
  }

  Future<void> updateLastPeriodStart(DateTime date) async {
    await updateProfile({
      'last_period_start': date.toIso8601String().split('T')[0],
    });
  }
}
