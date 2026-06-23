// test/features/ai_coach/ai_coach_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_os/features/ai_coach/domain/models/ai_insight_model.dart';

void main() {
  group('AIInsightModel Serialization & Getters Tests', () {
    test('toMap and fromMap conversion works correctly with new schema', () {
      final now = DateTime.now();
      final model = AIInsightModel(
        id: 'user_123',
        userId: 'user_123',
        summary: {
          'dailyBriefing': 'You focused for 45 minutes today.',
          'weeklyReview': 'Weekly performance increased.',
          'productivityInsights': 'Top category is Coding.',
        },
        recommendations: {
          'focus': ['Take a break after 25 mins.'],
          'goals': ['Focus on Clean Architecture goal.'],
          'streaks': ['Streak safe for today.'],
        },
        productivityScore: 85,
        generatedAt: now,
      );

      final map = model.toMap();
      expect(map['userId'], 'user_123');
      expect(map['summary']['dailyBriefing'], 'You focused for 45 minutes today.');
      expect(map['recommendations']['goals'], ['Focus on Clean Architecture goal.']);
      expect(map['productivityScore'], 85);
      expect(map['generatedAt'], now.toIso8601String());

      final deserialized = AIInsightModel.fromMap(map, 'user_123');
      expect(deserialized.id, 'user_123');
      expect(deserialized.userId, 'user_123');
      expect(deserialized.dailyBriefing, 'You focused for 45 minutes today.');
      expect(deserialized.weeklyReview, 'Weekly performance increased.');
      expect(deserialized.productivityInsights, 'Top category is Coding.');
      expect(deserialized.focusRecommendations, ['Take a break after 25 mins.']);
      expect(deserialized.goalRecommendations, ['Focus on Clean Architecture goal.']);
      expect(deserialized.streakPredictions, ['Streak safe for today.']);
      expect(deserialized.productivityScore, 85);
      expect(deserialized.generatedAt.toIso8601String(), now.toIso8601String());
    });

    test('fromMap handles missing/null values gracefully', () {
      final deserialized = AIInsightModel.fromMap({}, 'user_null');
      expect(deserialized.id, 'user_null');
      expect(deserialized.userId, '');
      expect(deserialized.dailyBriefing, '');
      expect(deserialized.weeklyReview, '');
      expect(deserialized.productivityInsights, '');
      expect(deserialized.focusRecommendations, isEmpty);
      expect(deserialized.goalRecommendations, isEmpty);
      expect(deserialized.streakPredictions, isEmpty);
      expect(deserialized.productivityScore, 0);
      expect(deserialized.generatedAt, isA<DateTime>());
    });

    test('fromMap parses legacy flat schema fields into structured maps', () {
      final legacyMap = {
        'userId': 'legacy_user',
        'productivityScore': 72,
        'dailyAdvice': 'Finish coding task.',
        'weeklyInsight': 'Morning window is peak.',
        'monthlySummary': 'Consistent 10 hours.',
        'focusImprovementTips': ['Minimise distractions.'],
        'goalRecommendations': ['Complete Dart roadmap.'],
        'productivityWarnings': ['Streak about to break!'],
        'createdAt': '2026-06-18T10:00:00Z',
      };

      final deserialized = AIInsightModel.fromMap(legacyMap, 'legacy_user');
      expect(deserialized.userId, 'legacy_user');
      expect(deserialized.productivityScore, 72);
      expect(deserialized.dailyBriefing, 'Finish coding task.');
      expect(deserialized.weeklyReview, 'Morning window is peak.');
      expect(deserialized.productivityInsights, 'Consistent 10 hours.');
      expect(deserialized.focusRecommendations, ['Minimise distractions.']);
      expect(deserialized.goalRecommendations, ['Complete Dart roadmap.']);
      expect(deserialized.streakPredictions, ['Streak about to break!']);
      expect(deserialized.generatedAt.toIso8601String(), '2026-06-18T10:00:00.000Z');
    });

    test('compatibility getters return expected mapped properties', () {
      final model = AIInsightModel(
        id: 'user_456',
        userId: 'user_456',
        summary: {
          'dailyBriefing': 'Daily text',
          'weeklyReview': 'Weekly text',
          'productivityInsights': 'Monthly text',
        },
        recommendations: {
          'focus': ['Focus tip'],
          'goals': ['Goal tip'],
          'streaks': ['Streak tip'],
        },
        productivityScore: 90,
        generatedAt: DateTime(2026, 6, 18),
      );

      expect(model.dailyAdvice, 'Daily text');
      expect(model.weeklyInsight, 'Weekly text');
      expect(model.goalSuggestions, ['Goal tip']);
      expect(model.focusImprovementTips, ['Focus tip']);
      expect(model.timeManagementSuggestions, ['Focus tip']);
      expect(model.productivityWarnings, ['Streak tip']);
      expect(model.dailySummary, 'Daily text');
      expect(model.weeklySummary, 'Weekly text');
      expect(model.monthlySummary, 'Monthly text');
      expect(model.createdAt, DateTime(2026, 6, 18));
    });

    test('copyWith properly overrides specified values', () {
      final model = AIInsightModel(
        id: 'user_789',
        userId: 'user_789',
        summary: const {},
        recommendations: const {},
        productivityScore: 40,
        generatedAt: DateTime(2026, 6, 18),
      );

      final cloned = model.copyWith(productivityScore: 95);
      expect(cloned.id, 'user_789');
      expect(cloned.productivityScore, 95);
    });
  });
}
