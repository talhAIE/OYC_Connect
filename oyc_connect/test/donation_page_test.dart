import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oyc_connect/features/donation/presentation/pages/donation_page.dart';
import 'package:oyc_connect/features/donation/services/stripe_service.dart';

class FakeStripeService extends StripeService {
  final completer = Completer<DonationResult>();
  final amounts = <double>[];

  @override
  Future<DonationResult> donate(double amount) {
    amounts.add(amount);
    return completer.future;
  }
}

void platformTest(String name, WidgetTesterCallback callback) {
  testWidgets(
    name,
    callback,
    variant: TargetPlatformVariant.only(
      name.startsWith('iPhone') ? TargetPlatform.iOS : TargetPlatform.android,
    ),
  );
}

void main() {
  Future<void> openPage(
    WidgetTester tester,
    TargetPlatform platform, {
    FakeStripeService? service,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (service != null) stripeServiceProvider.overrideWithValue(service),
        ],
        child: const MaterialApp(home: DonationPage()),
      ),
    );
  }

  platformTest('iPhone keeps the existing external website screen', (
    tester,
  ) async {
    await openPage(tester, TargetPlatform.iOS);
    expect(find.text('Open donation website'), findsOneWidget);
    expect(find.text('External website'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  platformTest('Android offers preset and custom AUD checkout', (tester) async {
    await openPage(tester, TargetPlatform.android);
    expect(find.text('Open donation website'), findsNothing);
    expect(find.text('Donate AUD 50.00'), findsOneWidget);
    await tester.tap(find.text('\$100'));
    await tester.pump();
    expect(find.text('Donate AUD 100.00'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '12.34');
    await tester.pump();
    expect(find.text('Donate AUD 12.34'), findsOneWidget);
  });

  for (final amount in ['0.50', '10000.01', '1.234', '1.2.3']) {
    platformTest('invalid amount $amount cannot start checkout', (
      tester,
    ) async {
      final service = FakeStripeService();
      await openPage(tester, TargetPlatform.android, service: service);
      await tester.enterText(find.byType(TextField), amount);
      await tester.pump();
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
      expect(service.amounts, isEmpty);
    });
  }

  platformTest(
    'checkout prevents duplicate taps and cancellation allows retry',
    (tester) async {
      final service = FakeStripeService();
      await openPage(tester, TargetPlatform.android, service: service);
      final button = find.byType(ElevatedButton);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      expect(service.amounts, [50]);
      expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
      service.completer.complete(const DonationResult(DonationStatus.canceled));
      await tester.pumpAndSettle();
      expect(
        find.text('Payment cancelled. Your donation was not completed.'),
        findsOneWidget,
      );
      expect(tester.widget<ElevatedButton>(button).onPressed, isNotNull);
    },
  );

  platformTest('paid but unsaved history does not claim payment failed', (
    tester,
  ) async {
    final service = FakeStripeService();
    await openPage(tester, TargetPlatform.android, service: service);
    await tester.ensureVisible(find.byType(ElevatedButton));
    await tester.tap(find.byType(ElevatedButton));
    service.completer.complete(
      const DonationResult(DonationStatus.succeeded, historySaved: false),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.textContaining('donation was paid'), findsOneWidget);
    expect(find.textContaining('do not pay again'), findsOneWidget);
    expect(service.amounts, [50]);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });

  platformTest('uncertain confirmation prevents another donation', (
    tester,
  ) async {
    final service = FakeStripeService();
    await openPage(tester, TargetPlatform.android, service: service);
    await tester.ensureVisible(find.byType(ElevatedButton));
    await tester.tap(find.byType(ElevatedButton));
    service.completer.complete(const DonationResult(DonationStatus.pending));
    await tester.pumpAndSettle();
    expect(find.text('Awaiting payment confirmation'), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
  });
}
