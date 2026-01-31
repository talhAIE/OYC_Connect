import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/teacher_model.dart';

part 'teachers_repository.g.dart';

class TeachersRepository {
  final SupabaseClient _supabase;

  TeachersRepository(this._supabase);

  // Helper to retry request on JWT expiry (fallback to Anon)
  Future<T> _safeExecute<T>(Future<T> Function() apiCall) async {
    try {
      return await apiCall();
    } on PostgrestException catch (e) {
      // PGRST303 is the code for JWT expired
      if (e.message.contains('JWT expired') || e.code == 'PGRST303') {
        // Token expired? Sign out to use Anon key for public access.
        await _supabase.auth.signOut();
        return await apiCall(); // Retry
      }
      rethrow;
    }
  }

  // Fetch all teachers
  Future<List<TeacherModel>> getAllTeachers() async {
    return _safeExecute(() async {
      final response = await _supabase
          .from('teachers')
          .select()
          .order('name', ascending: true);

      return (response as List)
          .map((json) => TeacherModel.fromJson(json))
          .toList();
    });
  }

  // Add new teacher
  Future<void> addTeacher(String name, {String? bio}) async {
    await _supabase.from('teachers').insert({'name': name, 'bio': bio});
  }

  // Delete teacher
  Future<void> deleteTeacher(int id) async {
    await _supabase.from('teachers').delete().eq('id', id);
  }

  // Update teacher
  Future<void> updateTeacher(int id, {String? name, String? bio}) async {
    final Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    if (bio != null) updates['bio'] = bio;

    await _supabase.from('teachers').update(updates).eq('id', id);
  }
}

@riverpod
TeachersRepository teachersRepository(TeachersRepositoryRef ref) {
  return TeachersRepository(Supabase.instance.client);
}
