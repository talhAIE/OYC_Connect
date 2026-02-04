import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      final paymentIntentData = await _createPaymentIntent(amount, currency);
      final clientSecret = paymentIntentData['clientSecret'];

      if (clientSecret == null) {
        throw Exception("Failed to get client secret");
      }

      // 2. Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'OYC Connect',
        ),
      );

      // 3. Present Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      // 4. Save Payment to Database
      await _savePaymentToSupabase(amount, currency, clientSecret);

      onResult(true); // Success
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        // User canceled, ensure UI stops loading
        print("Payment canceled");
        onResult(false);
      } else {
        print("Stripe Error: $e");
        onResult(false);
      }
    } catch (e) {
      print("Error: $e");
      onResult(false);
    }
  }

  Future<Map<String, dynamic>> _createPaymentIntent(
    double amount,
    String currency,
  ) async {
    try {
      final response = await _supabase.functions.invoke(
        'stripe-payment-intent',
        body: {'amount': amount, 'currency': currency},
      );

      return response.data;
    } catch (e) {
      throw Exception('Failed to create payment intent: $e');
    }
  }

  Future<void> _savePaymentToSupabase(
    double amount,
    String currency,
    String paymentIntentId,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Extract payment intent ID properly if possible, but clientSecret is usually pi_..._secret_...
      // The true ID is the first part before _secret
      final intentId = paymentIntentId.split('_secret')[0];

      await _supabase.from('payments').insert({
        'user_id': userId,
        'amount': amount,
        'currency': currency,
        'status':
            'succeeded', // We assume success if presentPaymentSheet didn't throw
        'payment_intent_id': intentId,
      });
    } catch (e) {
      print("Error saving payment: $e");
    }
  }
}
