class Profile {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final String timezone;
  final bool onboardingCompleted;
  final String tier;
  final double dailyFreeTimeHours;
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    this.timezone = 'UTC',
    this.onboardingCompleted = false,
    this.tier = 'free',
    this.dailyFreeTimeHours = 4,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      avatarUrl: json['avatar_url'],
      timezone: json['timezone'] ?? 'UTC',
      onboardingCompleted: json['onboarding_completed'] ?? false,
      tier: json['tier'] ?? 'free',
      dailyFreeTimeHours: (json['daily_free_time_hours'] ?? 4).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
