import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../services/stripe_service.dart';

class AndroidDonationPage extends ConsumerStatefulWidget {
  const AndroidDonationPage({super.key});

  @override
  ConsumerState<AndroidDonationPage> createState() =>
      _AndroidDonationPageState();
}

class _AndroidDonationPageState extends ConsumerState<AndroidDonationPage> {
  final _customAmount = TextEditingController();
  int? _selectedAmount = 50;
  bool _paying = false;
  bool _awaitingConfirmation = false;

  double get _amount => _customAmount.text.isEmpty
      ? (_selectedAmount ?? 0).toDouble()
      : double.tryParse(_customAmount.text) ?? 0;

  String? get _amountError {
    final amount = _amount;
    if (!amount.isFinite || amount < 1 || amount > 10000) {
      return 'Enter a donation from AUD 1.00 to AUD 10,000.00.';
    }
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(
      _customAmount.text.isEmpty
          ? amount.toStringAsFixed(2)
          : _customAmount.text,
    )) {
      return 'Use up to two decimal places.';
    }
    return null;
  }

  @override
  void dispose() {
    _customAmount.dispose();
    super.dispose();
  }

  Future<void> _donate() async {
    if (_paying || _awaitingConfirmation || _amountError != null) return;
    final amount = _amount;
    FocusScope.of(context).unfocus();
    setState(() => _paying = true);
    try {
      final result = await ref.read(stripeServiceProvider).donate(amount);
      if (!mounted) return;
      if (result.status == DonationStatus.canceled) {
        _showMessage('Payment cancelled. Your donation was not completed.');
      } else if (result.status == DonationStatus.pending) {
        setState(() => _awaitingConfirmation = true);
        _showMessage(
          'Your payment is awaiting confirmation. Please check with OYC before donating again.',
        );
      } else {
        setState(() {
          _customAmount.clear();
          _selectedAmount = 50;
        });
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Jazak Allah Khair!'),
            content: Text(
              result.historySaved
                  ? 'Your AUD ${amount.toStringAsFixed(2)} donation was received. Thank you for supporting your community.'
                  : 'Your AUD ${amount.toStringAsFixed(2)} donation was paid, but we could not update the donation history. Please contact OYC if you need help; do not pay again for this donation.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } on StripeException catch (error) {
      if (mounted) {
        _showMessage(
          error.error.localizedMessage ??
              'Payment could not be completed. Please try again.',
        );
      }
    } catch (_) {
      if (mounted)
        _showMessage(
          'Could not start the donation. Please try again or contact OYC.',
        );
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final disabled = _paying || _awaitingConfirmation;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Invest in your\nCommunity',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF006D5B),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your Sadaqah builds a brighter future for generations to come.',
              ),
              const SizedBox(height: 32),
              const Text(
                'SELECT AMOUNT (AUD)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [20, 50, 100]
                    .map(
                      (amount) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text('\$$amount'),
                            selected:
                                _selectedAmount == amount &&
                                _customAmount.text.isEmpty,
                            onSelected: disabled
                                ? null
                                : (_) => setState(() {
                                    _customAmount.clear();
                                    _selectedAmount = amount;
                                  }),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _customAmount,
                enabled: !disabled,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                onChanged: (_) => setState(() => _selectedAmount = null),
                decoration: InputDecoration(
                  labelText: 'Custom amount',
                  prefixText: 'AUD ',
                  errorText: _customAmount.text.isNotEmpty
                      ? _amountError
                      : null,
                ),
              ),
              const SizedBox(height: 28),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.credit_card, color: Color(0xFF1B5E20)),
                title: Text('Secure payment'),
                subtitle: Text('Pay by card or Google Pay where available.'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: disabled || _amountError != null ? null : _donate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF57C00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  icon: _paying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_outline),
                  label: Text(
                    _paying
                        ? 'Processing...'
                        : _awaitingConfirmation
                        ? 'Awaiting payment confirmation'
                        : _amountError != null
                        ? 'Enter amount'
                        : 'Donate AUD ${_amount.toStringAsFixed(2)}',
                  ),
                ),
              ),
              if (_awaitingConfirmation) ...[
                const SizedBox(height: 16),
                const Text(
                  'Please check with OYC before making another payment. Your payment may already have been received.',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
