// lib/features/activities/domain/repositories/activity_repository.dart
import '../models/activity_model.dart';

abstract class ActivityRepository {
  Stream<List<ActivityModel>> streamActivities(String userId);
  Future<ActivityModel> getActivityById(String id);
  Future<void> createActivity(ActivityModel activity);
  Future<void> updateActivity(ActivityModel activity);
  Future<void> deleteActivity(String id);
}
