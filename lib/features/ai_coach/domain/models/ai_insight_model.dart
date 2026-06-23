// lib/features/ai_coach/domain/models/ai_insight_model.dart

class AIInsightModel {
  final String id;
  final String userId;
  final Map<String, dynamic> summary; // dailyBriefing, weeklyReview, productivityInsights
  final Map<String, dynamic> recommendations; // focus, goals, streaks
  final int productivityScore; // 0-100
  final DateTime generatedAt;

  const AIInsightModel({
    required this.id,
    required this.userId,
    required this.summary,
    required this.recommendations,
    required this.productivityScore,
    required this.generatedAt,
  });

  // Getters for specific AI Coach 2.0 components
  String get dailyBriefing => summary['dailyBriefing'] as String? ?? '';
  String get weeklyReview => summary['weeklyReview'] as String? ?? '';
  String get productivityInsights => summary['productivityInsights'] as String? ?? '';

  List<String> get focusRecommendations => List<String>.from(recommendations['focus'] ?? const []);
  List<String> get goalRecommendations => List<String>.from(recommendations['goals'] ?? const []);
  List<String> get streakPredictions => List<String>.from(recommendations['streaks'] ?? const []);

  // Backwards compatibility getters for existing screen references/dashboard consumption
  String get dailyAdvice => dailyBriefing;
  String get weeklyInsight => weeklyReview;
  List<String> get goalSuggestions => goalRecommendations;
  List<String> get focusImprovementTips => focusRecommendations;
  List<String> get timeManagementSuggestions => focusRecommendations;
  List<String> get productivityWarnings => streakPredictions;
  String get dailySummary => dailyBriefing;
  String get weeklySummary => weeklyReview;
  String get monthlySummary => productivityInsights;
  Map<String, dynamic> get trendComparison => const {};
  DateTime get createdAt => generatedAt;

  AIInsightModel copyWith({
    String? id,
    String? userId,
    Map<String, dynamic>? summary,
    Map<String, dynamic>? recommendations,
    int? productivityScore,
    DateTime? generatedAt,
  }) {
    return AIInsightModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      summary: summary ?? this.summary,
      recommendations: recommendations ?? this.recommendations,
      productivityScore: productivityScore ?? this.productivityScore,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'summary': summary,
      'recommendations': recommendations,
      'productivityScore': productivityScore,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory AIInsightModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      try {
        return (val as dynamic).toDate() as DateTime;
      } catch (_) {
        return DateTime.now();
      }
    }

    List<String> parseStringList(dynamic val) {
      if (val == null) return const [];
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      return const [];
    }

    // Nested summary map extraction with fallback
    Map<String, dynamic> extractedSummary;
    if (map['summary'] is Map) {
      extractedSummary = Map<String, dynamic>.from(map['summary'] as Map);
    } else {
      extractedSummary = {
        'dailyBriefing': map['dailyAdvice'] as String? ?? map['dailySummary'] as String? ?? '',
        'weeklyReview': map['weeklyInsight'] as String? ?? map['weeklySummary'] as String? ?? '',
        'productivityInsights': map['monthlySummary'] as String? ?? '',
      };
    }

    // Nested recommendations map extraction with fallback
    Map<String, dynamic> extractedRecommendations;
    if (map['recommendations'] is Map) {
      extractedRecommendations = Map<String, dynamic>.from(map['recommendations'] as Map);
    } else {
      extractedRecommendations = {
        'focus': parseStringList(map['focusImprovementTips'] ?? map['timeManagementSuggestions']),
        'goals': parseStringList(map['goalRecommendations'] ?? map['goalSuggestions']),
        'streaks': parseStringList(map['productivityWarnings']),
      };
    }

    return AIInsightModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      summary: extractedSummary,
      recommendations: extractedRecommendations,
      productivityScore: map['productivityScore'] as int? ?? 0,
      generatedAt: parseDate(map['generatedAt'] ?? map['createdAt']),
    );
  }
}
