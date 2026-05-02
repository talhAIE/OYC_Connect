import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/jummah_config.dart';

class JummahRepository {
  final SupabaseClient _client;

  JummahRepository(this._client);

  /// Fetches the Jummah configuration.
  ///
  /// For production, we log and rethrow failures so the caller can display
  /// an explicit error state rather than silently behaving as if no config
  /// exists.
  Future<JummahConfig?> getJummahConfig() async {
    try {
      final response = await _client
          .from('jummah_configurations')
          .select()
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return JummahConfig.fromJson(response);
    } catch (e, st) {
      debugPrint('Error fetching jummah config: $e\n$st');
      rethrow;
    }
  }

  /// Updates the Jummah configuration.
  Future<void> updateJummahConfig(JummahConfig config) async {
    await _client.from('jummah_configurations').upsert(config.toJson());
  }

  /// Realtime subscription to the config
  Stream<JummahConfig?> subscribeToJummahConfig() {
    return _client
        .from('jummah_configurations')
        .stream(primaryKey: ['id'])
        .limit(1)
        .map((data) {
          if (data.isEmpty) return null;
          return JummahConfig.fromJson(data.first);
        });
  }
}
