class Accomplishment {
  final String id;
  final String userId;
  final String rawText;
  final String? normalizedText;
  final String? category;
  final int score;
  final String? scoreReasoning;
  final Map<String, dynamic>? scoringFactors;
  final int? estimatedTimeMinutes;
  final bool flagged;
  final String? flagReason;
  final String loggedDate;
  final DateTime createdAt;

  Accomplishment({
    required this.id,
    required this.userId,
    required this.rawText,
    this.normalizedText,
    this.category,
    required this.score,
    this.scoreReasoning,
    this.scoringFactors,
    this.estimatedTimeMinutes,
    this.flagged = false,
    this.flagReason,
    required this.loggedDate,
    required this.createdAt,
  });

  factory Accomplishment.fromJson(Map<String, dynamic> json) {
    return Accomplishment(
      id: json['id'],
      userId: json['user_id'],
      rawText: json['raw_text'],
      normalizedText: json['normalized_text'],
      category: json['category'],
      score: json['score'] ?? 0,
      scoreReasoning: json['score_reasoning'],
      scoringFactors: json['scoring_factors'],
      estimatedTimeMinutes: json['estimated_time_minutes'],
      flagged: json['flagged'] ?? false,
      flagReason: json['flag_reason'],
      loggedDate: json['logged_date'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get displayText => normalizedText ?? rawText;
}
