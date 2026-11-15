import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationDeliveryPage extends StatefulWidget {
  const NotificationDeliveryPage({super.key});
  @override
  State<NotificationDeliveryPage> createState() =>
      _NotificationDeliveryPageState();
}

class _NotificationDeliveryPageState extends State<NotificationDeliveryPage> {
  late Future<List<Map<String, dynamic>>> _records;
  @override
  void initState() {
    super.initState();
    _records = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final data = await Supabase.instance.client.rpc(
      'notification_delivery_status',
    );
    return List<Map<String, dynamic>>.from(data as List);
  }

  void _refresh() => setState(() => _records = _load());
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notification delivery'),
      actions: [
        IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
      ],
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _records,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(
            child: TextButton(
              onPressed: _refresh,
              child: const Text(
                'Could not load delivery records. Tap to retry.',
              ),
            ),
          );
        final rows = snapshot.data ?? [];
        if (rows.isEmpty)
          return const Center(
            child: Text('No new notification requests have been recorded yet.'),
          );
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Accepted means OneSignal accepted the request. It does not confirm a banner was shown on every phone.',
              ),
            ),
            ...rows.map(
              (row) => Card(
                child: ListTile(
                  title: Text(row['title'] as String? ?? 'Notification'),
                  subtitle: Text(
                    '${row['status'] == 'accepted' ? 'Accepted by OneSignal' : row['status']} · attempts: ${row['attempts']}\n${row['created_at']}\n${row['last_error'] ?? ''}',
                  ),
                  isThreeLine: true,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
