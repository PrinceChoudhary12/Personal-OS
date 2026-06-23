// lib/features/scheduler/domain/repositories/scheduler_repository.dart

import '../models/scheduler_model.dart';

abstract class SchedulerRepository {
  Stream<List<SchedulerModel>> streamSchedules(String userId);
  Future<void> createSchedule(SchedulerModel schedule);
  Future<void> updateSchedule(SchedulerModel schedule);
  Future<void> deleteSchedule(String id);
}
