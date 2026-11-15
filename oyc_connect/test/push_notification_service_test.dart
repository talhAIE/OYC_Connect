import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oyc_connect/core/notifications/push_notification_service.dart';

class FakePushGateway implements PushGateway {
  final calls = <String>[];
  bool allowed = true;
  bool opted = false;
  bool token = true;
  bool requestable = true;
  bool fail = false;
  void Function(Map<String, dynamic>)? tapped;
  bool Function()? canDisplay;
  @override
  void initialize(
    String appId,
    VoidCallback changed,
    void Function(Map<String, dynamic>) tapped,
    bool Function() canDisplay,
  ) {
    calls.add('initialize');
    this.tapped = tapped;
    this.canDisplay = canDisplay;
  }

  @override
  Future<void> login(String id) async {
    if (fail) throw StateError('native failed');
    calls.add('login:$id');
  }

  @override
  Future<void> logout() async => calls.add('logout');
  @override
  Future<void> optIn() async {
    calls.add('optIn');
    opted = true;
  }

  @override
  Future<void> optOut() async {
    calls.add('optOut');
    opted = false;
  }

  @override
  Future<bool> canRequest() async => requestable;
  @override
  Future<bool> requestPermission(bool fallbackToSettings) async {
    calls.add('permission');
    return allowed;
  }

  @override
  bool get permission => allowed;
  @override
  bool get optedIn => opted;
  @override
  bool get hasToken => token;
  @override
  String? get subscriptionId => token ? 'test-subscription' : null;
  @override
  void dispose() {}
}

void main() {
  late FakePushGateway gateway;
  late PushNotificationService service;
  setUp(() {
    gateway = FakePushGateway();
    service = PushNotificationService(gateway, supported: true)
      ..initialize('public-app-id');
  });
  tearDown(() => service.dispose());
  test('restored identity is bound and stored opt-in is restored', () async {
    await service.synchronize('restored-user', enabled: true);
    expect(
      gateway.calls,
      containsAllInOrder(['initialize', 'login:restored-user', 'optIn']),
    );
    expect(service.status, contains('registered'));
    await service.synchronize('restored-user', enabled: true);
    expect(gateway.calls.where((c) => c.startsWith('login:')).length, 1);
  });
  test(
    'logout opts out even though OneSignal logout alone keeps an anonymous subscription',
    () async {
      await service.synchronize('user', enabled: true);
      await service.synchronize(null, enabled: false);
      expect(gateway.opted, false);
      expect(gateway.calls.last, 'optOut');
      expect(gateway.calls, contains('logout'));
    },
  );
  test('persisted opt-out is never silently enabled', () async {
    await service.synchronize('user', enabled: false);
    expect(gateway.opted, false);
    expect(service.status, contains('disabled in your profile'));
  });
  test(
    'a profile reload does not temporarily opt out a registered account',
    () async {
      await service.synchronize('user', enabled: true);
      gateway.calls.clear();
      await service.synchronize('user', enabled: null);
      expect(gateway.opted, isTrue);
      expect(gateway.calls, isNot(contains('optOut')));
      expect(gateway.canDisplay!(), isTrue);
    },
  );
  test('unknown preferences cannot inherit another account opt-in', () async {
    await service.synchronize('first-user', enabled: true);
    await service.synchronize('second-user', enabled: null);
    expect(gateway.opted, isFalse);
    expect(gateway.canDisplay!(), isFalse);
  });
  test(
    'turning off blocks foreground delivery immediately and stays off on resume',
    () async {
      await service.synchronize('user', enabled: true);
      expect(gateway.canDisplay!(), true);
      final disabled = service.synchronize('user', enabled: false);
      expect(gateway.canDisplay!(), false);
      await disabled;
      await service.synchronize('user', enabled: false);
      expect(gateway.opted, false);
      expect(gateway.calls.last, 'optOut');
    },
  );
  test('denied explicit permission fails without opting in', () async {
    gateway.allowed = false;
    await expectLater(
      service.synchronize('user', enabled: true, prompt: true),
      throwsStateError,
    );
    expect(gateway.calls, isNot(contains('optIn')));
  });
  test(
    'missing push token is visible rather than claiming delivery is enabled',
    () async {
      gateway.token = false;
      await service.synchronize('user', enabled: true);
      expect(service.status, contains('registration is pending'));
    },
  );
  test('native failures are observable and a later sync can recover', () async {
    gateway.fail = true;
    await expectLater(
      service.synchronize('user', enabled: true),
      throwsStateError,
    );
    expect(service.lastError, isNotNull);
    gateway.fail = false;
    await service.synchronize('user', enabled: true);
    expect(service.lastError, isNull);
  });
  test('newer session wins over queued stale work', () async {
    final old = service.synchronize('old', enabled: true);
    final current = service.synchronize('current', enabled: true);
    await Future.wait([old, current]);
    expect(gateway.calls, isNot(contains('login:old')));
    expect(gateway.calls, contains('login:current'));
  });
  test('cold-start notification tap is held until navigation is ready', () {
    gateway.tapped!({'type': 'event'});
    Map<String, dynamic>? routed;
    service.setTapHandler((data) => routed = data);
    expect(routed, {'type': 'event'});
  });
  test('Namaz and Jummah open Home; all community types open Notices', () {
    expect(notificationDestination({'type': 'prayer'}).location, '/home');
    expect(notificationDestination({'type': 'jummah'}).location, '/home');
    expect(notificationDestination({'type': 'Namaz'}).location, '/home');
    expect(notificationDestination({'type': 'Jumuah'}).location, '/home');
    expect(notificationDestination({'type': 'event'}).tab, 1);
    expect(
      notificationDestination({'type': 'community'}).location,
      '/community?tab=notices',
    );
    expect(notificationDestination({'type': 'announcement'}).tab, 1);
  });
  test('old untyped prayer alerts still open Home', () {
    expect(
      notificationDestination({
        '_notificationTitle': 'Fajr is in 30 minutes',
      }).location,
      '/home',
    );
    expect(
      notificationDestination({'_notificationTitle': 'Jummah'}).location,
      '/home',
    );
    expect(
      notificationDestination({
        'type': 'announcement',
        '_notificationTitle': 'New Jummah venue',
      }).tab,
      1,
    );
    expect(notificationDestination({}).tab, 1);
  });
}
