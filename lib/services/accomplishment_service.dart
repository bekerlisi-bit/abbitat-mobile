import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/accomplishment.dart';

class AccomplishmentService {
  final _supabase = Supabase.instance.client;

  Future<List<Accomplishment>> getTodaysAccomplishments() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final userId = _supabase.auth.currentUser?.id;
    
    if (userId == null) return [];

    final response = await _supabase
        .from('accomplishments')
        .select()
        .eq('user_id', userId)
        .eq('logged_date', today)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Accomplishment.fromJson(json))
        .toList();
  }

  Future<List<Accomplishment>> getAllAccomplishments({int limit = 100}) async {
    final userId = _supabase.auth.currentUser?.id;
    
    if (userId == null) return [];

    final response = await _supabase
        .from('accomplishments')
        .select()
        .eq('user_id', userId)
        .order('logged_date', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => Accomplishment.fromJson(json))
        .toList();
  }

  Future<Map<String, dynamic>> createAccomplishment(String text) async {
    final userId = _supabase.auth.currentUser?.id;
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    if (userId == null) throw Exception('Not authenticated');

    // For now, create without AI scoring (we'll call the web API for scoring)
    // In production, you'd want to call a Supabase Edge Function for AI scoring
    final response = await _supabase
        .from('accomplishments')
        .insert({
          'user_id': userId,
          'raw_text': text,
          'score': 50, // Default score, should be replaced by AI
          'logged_date': today,
        })
        .select()
        .single();

    return response;
  }

  Future<Map<String, int>> getWeeklyStats() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return {'count': 0, 'totalScore': 0};

    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final weekAgoStr = weekAgo.toIso8601String().split('T')[0];

    final response = await _supabase
        .from('accomplishments')
        .select('score')
        .eq('user_id', userId)
        .gte('logged_date', weekAgoStr);

    final list = response as List;
    final totalScore = list.fold<int>(0, (sum, item) => sum + (item['score'] as int));

    return {
      'count': list.length,
      'totalScore': totalScore,
    };
  }

  Future<int> calculateStreak() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;

    final response = await _supabase
        .from('accomplishments')
        .select('logged_date')
        .eq('user_id', userId)
        .order('logged_date', ascending: false);

    final dates = (response as List)
        .map((item) => item['logged_date'] as String)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (dates.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.now();

    for (final date in dates) {
      final checkStr = checkDate.toIso8601String().split('T')[0];
      if (date == checkStr) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (date.compareTo(checkStr) < 0) {
        break;
      }
    }

    return streak;
  }
}
