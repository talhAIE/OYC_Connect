import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/khateeb_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider
final khateebRepositoryProvider = Provider<KhateebRepository>((ref) {
  return KhateebRepository(Supabase.instance.client);
});

final khateebsStreamProvider = StreamProvider<List<Khateeb>>((ref) {
  return ref.watch(khateebRepositoryProvider).getKhateebsStream();
});

class KhateebRepository {
  final SupabaseClient _client;

  KhateebRepository(this._client);

  /// Fetch all khateebs
  Future<List<Khateeb>> getKhateebs() async {
    final data = await _client
        .from('khateebs')
        .select()
        .order('name', ascending: true); // Alphabetical

    return (data as List).map((e) => Khateeb.fromJson(e)).toList();
  }

  /// Stream khateebs for realtime updates
  Stream<List<Khateeb>> getKhateebsStream() {
    return _client
        .from('khateebs')
        .stream(primaryKey: ['id'])
        .order('name', ascending: true)
        .map((data) => data.map((json) => Khateeb.fromJson(json)).toList());
  }

  /// Add a new khateeb
  Future<void> addKhateeb(String name) async {
    await _client.from('khateebs').insert({'name': name});
  }

  /// Delete a khateeb
  Future<void> deleteKhateeb(int id) async {
    await _client.from('khateebs').delete().eq('id', id);
  }
}
