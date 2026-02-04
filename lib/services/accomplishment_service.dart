import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/accomplishment.dart';
import 'api_service.dart';

class AccomplishmentService {
  final _supabase = Supabase.instance.client;
  final _api = ApiService();

  Future<List<Accomplishment>> getTodaysAccomplishments() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    try {
      final data = await _api.getAccomplishments(date: today);
      return data.map((json) => Accomplishment.fromJson(_transformApiResponse(json))).toList();
    } catch (e) {
      // Fallback to direct Supabase if API fails
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
  }

  Future<List<Accomplishment>> getAllAccomplishments({int limit = 100}) async {
    try {
      final data = await _api.getAccomplishments(limit: limit);
      return data.map((json) => Accomplishment.fromJson(_transformApiResponse(json))).toList();
    } catch (e) {
      // Fallback to direct Supabase
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
  }

  Future<Map<String, dynamic>> createAccomplishment(String text) async {
    // Use API service for AI scoring
    return await _api.createAccomplishment(text);
  }

  // Transform camelCase API response to snake_case for model
  Map<String, dynamic> _transformApiResponse(Map<String, dynamic> json) {
    return {
      'id': json['id'],
      'user_id': json['userId'],
      'raw_text': json['rawText'],
      'normalized_text': json['normalizedText'],
      'category': json['category'],
      'score': json['score'],
      'score_reasoning': json['scoreReasoning'],
      'scoring_factors': json['scoringFactors'],
      'estimated_time_minutes': json['estimatedTimeMinutes'],
      'flagged': json['flagged'],
      'flag_reason': json['flagReason'],
      'logged_date': json['loggedDate'],
      'created_at': json['createdAt'],
    };
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
