import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static const String baseUrl = 'https://abbitat.vercel.app/api';
  
  final _supabase = Supabase.instance.client;

  Future<Map<String, String>> _getHeaders() async {
    final session = _supabase.auth.currentSession;
    return {
      'Content-Type': 'application/json',
      if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
    };
  }

  Future<Map<String, dynamic>> createAccomplishment(String text) async {
    final headers = await _getHeaders();
    
    final response = await http.post(
      Uri.parse('$baseUrl/accomplishments'),
      headers: headers,
      body: jsonEncode({'text': text}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Not authenticated');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to create accomplishment');
    }
  }

  Future<List<Map<String, dynamic>>> getAccomplishments({String? date, int limit = 50}) async {
    final headers = await _getHeaders();
    
    var url = '$baseUrl/accomplishments?limit=$limit';
    if (date != null) url += '&date=$date';

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['accomplishments'] ?? []);
    } else {
      throw Exception('Failed to load accomplishments');
    }
  }

  Future<Map<String, dynamic>> getLeaderboard({String? groupId}) async {
    final headers = await _getHeaders();
    
    var url = '$baseUrl/leaderboard';
    if (groupId != null) url += '?groupId=$groupId';

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load leaderboard');
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    final headers = await _getHeaders();
    
    final response = await http.get(
      Uri.parse('$baseUrl/user/profile'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load profile');
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    
    final response = await http.patch(
      Uri.parse('$baseUrl/user/profile'),
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile');
    }
  }

  Future<List<Map<String, dynamic>>> getReflections({int limit = 30}) async {
    final headers = await _getHeaders();
    
    final response = await http.get(
      Uri.parse('$baseUrl/reflections?limit=$limit'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['reflections'] ?? []);
    } else {
      throw Exception('Failed to load reflections');
    }
  }

  Future<Map<String, dynamic>> createReflection(String content, int mood) async {
    final headers = await _getHeaders();
    
    final response = await http.post(
      Uri.parse('$baseUrl/reflections'),
      headers: headers,
      body: jsonEncode({'content': content, 'mood': mood}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create reflection');
    }
  }

  Future<void> completeOnboarding(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    
    final response = await http.post(
      Uri.parse('$baseUrl/onboarding'),
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to complete onboarding');
    }
  }
}
