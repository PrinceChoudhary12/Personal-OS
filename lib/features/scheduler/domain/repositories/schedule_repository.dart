// lib/features/scheduler/domain/repositories/schedule_repository.dart

import '../models/schedule_model.dart';

abstract class ScheduleRepository {
  Future<ScheduleModel?> getSchedule(String userId, DateTime date);
  Future<void> saveSchedule(ScheduleModel schedule);
  Future<ScheduleModel> generateSchedule(String userId, DateTime date);
  Stream<ScheduleModel?> streamSchedule(String userId, DateTime date);
  Future<void> updateTaskCompletion(String userId, DateTime date, String taskId, bool completed);
}
