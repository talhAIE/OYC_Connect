import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class StripeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  StripeService._();
  static final StripeService instance = StripeService._();

  Future<void> makePayment({
    required double amount,
    required String currency,
    required Function(bool) onResult,
  }) async {
    try {
      // 1. Create Payment Intent via Supabase Edge Function
      final response = await _supabase.functions.invoke(
        'stripe-payment-intent',
        body: {'amount': amount, 'currency': currency},
      );

      final data = response.data;
      if (data == null || data['clientSecret'] == null) {
        final errorMsg = data?['error'] ?? 'Failed to create payment intent';
        throw Exception(errorMsg);
      }

      final clientSecret = data['clientSecret'];

      // 2. Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'OYC Connect',
        ),
      );

      // 3. Present Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      // 4. Payment sheet completed successfully — save to DB
      await _savePaymentToSupabase(amount, currency, 'succeeded');
      onResult(true);
    } on StripeException catch (e, st) {
      if (e.error.code == FailureCode.Canceled) {
        debugPrint("Payment canceled by user");
        onResult(false);
      } else {
        debugPrint("Stripe Error: ${e.error.localizedMessage}");
        await Sentry.captureException(e, stackTrace: st);
        onResult(false);
      }
    } catch (e, st) {
      debugPrint("Payment Error: $e");
      await Sentry.captureException(e, stackTrace: st);
      onResult(false);
    }
  }

  Future<void> _savePaymentToSupabase(
    double amount,
    String currency,
    String status,
  ) async {
    final userId = _supabase.auth.currentUser?.id;

    try {
      await _supabase.from('payments').insert({
        'user_id': userId,
        'amount': amount,
        'currency': currency,
        'status': status,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("Error saving payment to database: $e");
      // Re-throw so the caller knows the save failed
      rethrow;
    }
  }
}
