// lib/features/analytics/domain/models/analytics_model.dart

class AnalyticsModel {
  final String id;
  final String userId;
  final int totalActivities;
  final int totalFocusTime; // in minutes
  final double averageSessionDuration; // in minutes
  final double goalCompletionRate; // percentage
  final Map<String, int> categoryBreakdown;
  final List<double> dailyProductivity; // list of focus minutes for the last 7 days
  final List<double> weeklyProductivity; // list of focus minutes for the last 4 weeks
  final List<double> monthlyProductivity; // list of focus minutes for the last 6 months
  final DateTime createdAt;

  const AnalyticsModel({
    required this.id,
    required this.userId,
    required this.totalActivities,
    required this.totalFocusTime,
    required this.averageSessionDuration,
    required this.goalCompletionRate,
    required this.categoryBreakdown,
    required this.dailyProductivity,
    required this.weeklyProductivity,
    required this.monthlyProductivity,
    required this.createdAt,
  });

  AnalyticsModel copyWith({
    String? id,
    String? userId,
    int? totalActivities,
    int? totalFocusTime,
    double? averageSessionDuration,
    double? goalCompletionRate,
    Map<String, int>? categoryBreakdown,
    List<double>? dailyProductivity,
    List<double>? weeklyProductivity,
    List<double>? monthlyProductivity,
    DateTime? createdAt,
  }) {
    return AnalyticsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      totalActivities: totalActivities ?? this.totalActivities,
      totalFocusTime: totalFocusTime ?? this.totalFocusTime,
      averageSessionDuration: averageSessionDuration ?? this.averageSessionDuration,
      goalCompletionRate: goalCompletionRate ?? this.goalCompletionRate,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      dailyProductivity: dailyProductivity ?? this.dailyProductivity,
      weeklyProductivity: weeklyProductivity ?? this.weeklyProductivity,
      monthlyProductivity: monthlyProductivity ?? this.monthlyProductivity,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'totalActivities': totalActivities,
      'totalFocusTime': totalFocusTime,
      'averageSessionDuration': averageSessionDuration,
      'goalCompletionRate': goalCompletionRate,
      'categoryBreakdown': categoryBreakdown,
      'dailyProductivity': dailyProductivity,
      'weeklyProductivity': weeklyProductivity,
      'monthlyProductivity': monthlyProductivity,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AnalyticsModel.fromMap(Map<String, dynamic> map, String docId) {
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

    List<double> parseDoubleList(dynamic val) {
      if (val == null) return const [];
      if (val is List) {
        return val.map((e) => (e as num).toDouble()).toList();
      }
      return const [];
    }

    return AnalyticsModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      totalActivities: map['totalActivities'] as int? ?? 0,
      totalFocusTime: map['totalFocusTime'] as int? ?? 0,
      averageSessionDuration: (map['averageSessionDuration'] as num?)?.toDouble() ?? 0.0,
      goalCompletionRate: (map['goalCompletionRate'] as num?)?.toDouble() ?? 0.0,
      categoryBreakdown: Map<String, int>.from(map['categoryBreakdown'] ?? const {}),
      dailyProductivity: parseDoubleList(map['dailyProductivity']),
      weeklyProductivity: parseDoubleList(map['weeklyProductivity']),
      monthlyProductivity: parseDoubleList(map['monthlyProductivity']),
      createdAt: parseDate(map['createdAt']),
    );
  }
}
