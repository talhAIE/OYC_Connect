import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/jummah_config.dart';

class JummahRepository {
  final SupabaseClient _client;

  JummahRepository(this._client);

  /// Fetches the Jummah configuration.
  /// Since we only have one row, we fetch the first one.
  Future<JummahConfig?> getJummahConfig() async {
    try {
      final response = await _client
          .from('jummah_configurations')
          .select()
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return JummahConfig.fromJson(response);
    } catch (e) {
      // TODO: Handle error properly
      print('Error fetching jummah config: $e');
      return null;
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
