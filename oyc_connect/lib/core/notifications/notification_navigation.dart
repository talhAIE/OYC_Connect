import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'push_notification_service.dart';

final notificationNavigationProvider = Provider<NotificationNavigation>((ref) {
  final navigation = NotificationNavigation();
  ref.onDispose(navigation.dispose);
  return navigation;
});

/// Retain the latest tapped notification until startup/auth checks allow it.
/// The router consumes it only after normal login, never during recovery.
class NotificationNavigation extends ChangeNotifier {
  String? _pendingLocation;
  int _sequence = 0;

  void open(Map<String, dynamic> data) {
    final uri = Uri.parse(notificationDestination(data).location);
    _pendingLocation = uri
        .replace(
          queryParameters: {
            ...uri.queryParameters,
            // A fresh route also resets a cached Community page if the member
            // manually switched back to Events after a previous notice tap.
            'notification': '${++_sequence}',
          },
        )
        .toString();
    notifyListeners();
  }

  String? takePendingLocation() {
    final location = _pendingLocation;
    _pendingLocation = null;
    return location;
  }
}
