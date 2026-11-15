import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum DonationStatus { succeeded, canceled, pending }

class DonationResult {
  const DonationResult(this.status, {this.historySaved = true});

  final DonationStatus status;
  final bool historySaved;
}

final stripeServiceProvider = Provider<StripeService>((ref) => StripeService());

/// Native checkout is initialized lazily, exclusively by the Android screen.
class StripeService {
  Future<DonationResult> donate(double amount) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw StateError('Native donations are available on Android only.');
    }
    if (!amount.isFinite ||
        amount < 1 ||
        amount > 10000 ||
        (amount * 100 - (amount * 100).round()).abs() > 0.000001) {
      throw ArgumentError(
        'Enter an amount from AUD 1 to 10,000 with up to two decimal places.',
      );
    }

    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw StateError('Please log in before donating.');
    final key = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
    if (!key.startsWith('pk_')) {
      throw StateError('Donations are not configured. Please contact OYC.');
    }

    Stripe.publishableKey = key;
    Stripe.urlScheme = 'oycconnect';
    await Stripe.instance.applySettings();

    final response = await client.functions.invoke(
      'stripe-payment-intent',
      body: {'amount': amount, 'currency': 'aud'},
    );
    final data = response.data;
    if (response.status != 200 ||
        data is! Map ||
        data['clientSecret'] is! String ||
        (data['clientSecret'] as String).isEmpty) {
      throw StateError('Could not start checkout. Please try again.');
    }
    final clientSecret = data['clientSecret'] as String;

    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'OYC Connect',
          returnURL: 'oycconnect://stripe-redirect',
          googlePay: PaymentSheetGooglePay(
            merchantCountryCode: 'AU',
            currencyCode: 'AUD',
            testEnv: key.startsWith('pk_test_'),
          ),
        ),
      );
      await Stripe.instance.presentPaymentSheet();
    } on StripeException catch (error) {
      if (error.error.code == FailureCode.Canceled) {
        return const DonationResult(DonationStatus.canceled);
      }
      rethrow;
    }

    // Once the sheet completes, a network/history error must never invite the
    // donor to pay again for a transaction that may already have succeeded.
    PaymentIntent intent;
    try {
      intent = await Stripe.instance.retrievePaymentIntent(clientSecret);
    } catch (error, stack) {
      await _reportError(error, stack);
      return const DonationResult(DonationStatus.pending);
    }
    if (intent.status != PaymentIntentsStatus.Succeeded) {
      return const DonationResult(DonationStatus.pending);
    }

    try {
      await client
          .from('payments')
          .upsert(
            {
              'user_id': userId,
              'amount': amount,
              'currency': 'AUD',
              'status': 'succeeded',
              'payment_intent_id': intent.id,
            },
            onConflict: 'payment_intent_id',
            ignoreDuplicates: true,
          );
      return const DonationResult(DonationStatus.succeeded);
    } catch (error, stack) {
      await _reportError(error, stack);
      return const DonationResult(
        DonationStatus.succeeded,
        historySaved: false,
      );
    }
  }

  Future<void> _reportError(Object error, StackTrace stack) async {
    try {
      await Sentry.captureException(error, stackTrace: stack);
    } catch (_) {
      // Reporting must not turn an already paid donation into a retry prompt.
    }
  }
}
