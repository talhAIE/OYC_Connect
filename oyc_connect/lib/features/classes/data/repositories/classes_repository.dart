import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/class_model.dart';

part 'classes_repository.g.dart';

class ClassesRepository {
  final SupabaseClient _supabase;

  ClassesRepository(this._supabase);

  // Fetch all classes
  Future<List<ClassModel>> getAllClasses() async {
    final response = await _supabase
        .from('classes')
        .select()
        .order('name', ascending: true);

    return (response as List).map((json) => ClassModel.fromJson(json)).toList();
  }

  // Add new class
  Future<void> addClass(String name, {String? description}) async {
    await _supabase.from('classes').insert({
      'name': name,
      'description': description,
    });
  }

  // Delete class
  Future<void> deleteClass(int id) async {
    await _supabase.from('classes').delete().eq('id', id);
  }

  // Update class
  Future<void> updateClass(int id, {String? name, String? description}) async {
    final Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;

    await _supabase.from('classes').update(updates).eq('id', id);
  }
}

@riverpod
ClassesRepository classesRepository(ClassesRepositoryRef ref) {
  return ClassesRepository(Supabase.instance.client);
}
