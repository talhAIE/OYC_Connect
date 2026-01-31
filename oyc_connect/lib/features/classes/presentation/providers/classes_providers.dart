import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/classes_repository.dart';
import '../../data/repositories/teachers_repository.dart';
import '../../data/repositories/schedule_repository.dart';
import '../../data/models/class_model.dart';
import '../../data/models/teacher_model.dart';
import '../../data/models/weekly_schedule_model.dart';

part 'classes_providers.g.dart';

// Providers for fetching data

@Riverpod(keepAlive: false)
Future<List<ClassModel>> allClasses(AllClassesRef ref) async {
  final repository = ref.watch(classesRepositoryProvider);
  return repository.getAllClasses();
}

@Riverpod(keepAlive: false)
Future<List<TeacherModel>> allTeachers(AllTeachersRef ref) async {
  final repository = ref.watch(teachersRepositoryProvider);
  return repository.getAllTeachers();
}

@Riverpod(keepAlive: false)
Future<List<WeeklyScheduleModel>> allSchedules(AllSchedulesRef ref) async {
  final repository = ref.watch(scheduleRepositoryProvider);
  return repository.getAllSchedules();
}

@Riverpod(keepAlive: false)
Future<List<WeeklyScheduleModel>> weeklySchedules(
  WeeklySchedulesRef ref,
) async {
  final repository = ref.watch(scheduleRepositoryProvider);
  return repository.getSchedulesByType('weekly');
}

@Riverpod(keepAlive: false)
Future<List<WeeklyScheduleModel>> quranSchedules(QuranSchedulesRef ref) async {
  final repository = ref.watch(scheduleRepositoryProvider);
  return repository.getSchedulesByType('quran');
}
