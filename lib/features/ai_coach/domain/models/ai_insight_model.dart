// lib/features/ai_coach/domain/models/ai_insight_model.dart

class AIInsightModel {
  final String id;
  final String userId;
  final int productivityScore; // 0-100
  final String dailySummary;
  final String weeklySummary;
  final String monthlySummary;
  final List<String> goalRecommendations;
  final List<String> focusImprovementTips;
  final List<String> timeManagementSuggestions;
  final List<String> productivityWarnings;
  final String dailyAdvice;
  final String weeklyInsight;
  final List<String> goalSuggestions;
  final Map<String, dynamic> trendComparison; // compares this week vs last week, this month vs last month
  final DateTime createdAt;

  const AIInsightModel({
    required this.id,
    required this.userId,
    required this.productivityScore,
    required this.dailySummary,
    required this.weeklySummary,
    required this.monthlySummary,
    required this.goalRecommendations,
    required this.focusImprovementTips,
    required this.timeManagementSuggestions,
    required this.productivityWarnings,
    required this.dailyAdvice,
    required this.weeklyInsight,
    required this.goalSuggestions,
    required this.trendComparison,
    required this.createdAt,
  });

  AIInsightModel copyWith({
    String? id,
    String? userId,
    int? productivityScore,
    String? dailySummary,
    String? weeklySummary,
    String? monthlySummary,
    List<String>? goalRecommendations,
    List<String>? focusImprovementTips,
    List<String>? timeManagementSuggestions,
    List<String>? productivityWarnings,
    String? dailyAdvice,
    String? weeklyInsight,
    List<String>? goalSuggestions,
    Map<String, dynamic>? trendComparison,
    DateTime? createdAt,
  }) {
    return AIInsightModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productivityScore: productivityScore ?? this.productivityScore,
      dailySummary: dailySummary ?? this.dailySummary,
      weeklySummary: weeklySummary ?? this.weeklySummary,
      monthlySummary: monthlySummary ?? this.monthlySummary,
      goalRecommendations: goalRecommendations ?? this.goalRecommendations,
      focusImprovementTips: focusImprovementTips ?? this.focusImprovementTips,
      timeManagementSuggestions: timeManagementSuggestions ?? this.timeManagementSuggestions,
      productivityWarnings: productivityWarnings ?? this.productivityWarnings,
      dailyAdvice: dailyAdvice ?? this.dailyAdvice,
      weeklyInsight: weeklyInsight ?? this.weeklyInsight,
      goalSuggestions: goalSuggestions ?? this.goalSuggestions,
      trendComparison: trendComparison ?? this.trendComparison,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productivityScore': productivityScore,
      'dailySummary': dailySummary,
      'weeklySummary': weeklySummary,
      'monthlySummary': monthlySummary,
      'goalRecommendations': goalRecommendations,
      'focusImprovementTips': focusImprovementTips,
      'timeManagementSuggestions': timeManagementSuggestions,
      'productivityWarnings': productivityWarnings,
      'dailyAdvice': dailyAdvice,
      'weeklyInsight': weeklyInsight,
      'goalSuggestions': goalSuggestions,
      'trendComparison': trendComparison,
      'createdAt': createdAt.toIso8601String(),
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

    return AIInsightModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      productivityScore: map['productivityScore'] as int? ?? 0,
      dailySummary: map['dailySummary'] as String? ?? '',
      weeklySummary: map['weeklySummary'] as String? ?? '',
      monthlySummary: map['monthlySummary'] as String? ?? '',
      goalRecommendations: parseStringList(map['goalRecommendations']),
      focusImprovementTips: parseStringList(map['focusImprovementTips']),
      timeManagementSuggestions: parseStringList(map['timeManagementSuggestions']),
      productivityWarnings: parseStringList(map['productivityWarnings']),
      dailyAdvice: map['dailyAdvice'] as String? ?? '',
      weeklyInsight: map['weeklyInsight'] as String? ?? '',
      goalSuggestions: parseStringList(map['goalSuggestions']),
      trendComparison: Map<String, dynamic>.from(map['trendComparison'] ?? const {}),
      createdAt: parseDate(map['createdAt']),
    );
  }
}
