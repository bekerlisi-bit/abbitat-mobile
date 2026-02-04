import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<void> signInWithOtp(String email) async {
    await _supabase.auth.signInWithOtp(
      email: email,
      emailRedirectTo: 'com.abbitat.app://callback',
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<bool> isOnboardingCompleted() async {
    final user = currentUser;
    if (user == null) return false;

    final profile = await _supabase
        .from('profiles')
        .select('onboarding_completed')
        .eq('id', user.id)
        .single();

    return profile['onboarding_completed'] == true;
  }
}
