import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/stripe_service.dart';

class DonationPage extends ConsumerStatefulWidget {
  const DonationPage({super.key});

  @override
  ConsumerState<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends ConsumerState<DonationPage> {
  // State for chip selection (nullable to allow deselection when typing custom amount)
  int? _selectedChipAmount = 50;
  late TextEditingController _customAmountController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _customAmountController = TextEditingController();
    _customAmountController.addListener(_onCustomAmountChanged);
  }

  @override
  void dispose() {
    _customAmountController.removeListener(_onCustomAmountChanged);
    _customAmountController.dispose();
    super.dispose();
  }

  void _onCustomAmountChanged() {
    // If user types something, deselect chips
    if (_customAmountController.text.isNotEmpty &&
        _selectedChipAmount != null) {
      setState(() {
        _selectedChipAmount = null;
      });
    }
    // Force rebuild to update button text
    setState(() {});
  }

  void _selectChip(int amount) {
    setState(() {
      _selectedChipAmount = amount;
      _customAmountController.clear(); // Clear custom field when chip selected
    });
  }

  double get _effectiveAmount {
    if (_customAmountController.text.isNotEmpty) {
      return double.tryParse(_customAmountController.text) ?? 0;
    }
    return _selectedChipAmount?.toDouble() ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              const Text(
                "SELECT AMOUNT",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 16),
              _buildAmountSelectors(),
              const SizedBox(height: 16),
              _buildCustomAmountField(),
              const SizedBox(height: 32),
              const Text(
                "SECURE PAYMENT",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 16),
              _buildPaymentMethod(),
              const SizedBox(height: 40),
              _buildDonateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              height: 1.2,
              letterSpacing: -0.5,
            ),
            children: [
              TextSpan(text: "Invest in your\n"),
              TextSpan(
                text: "Community",
                style: TextStyle(color: Color(0xFF006D5B)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Your Sadaqah builds a brighter future for generations to come.",
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountSelectors() {
    return Row(
      children: [
        _buildAmountChip(20),
        const SizedBox(width: 16),
        _buildAmountChip(50),
        const SizedBox(width: 16),
        _buildAmountChip(100),
      ],
    );
  }

  Widget _buildAmountChip(int amount) {
    final isSelected = _selectedChipAmount == amount;
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectChip(amount),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1B5E20) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: isSelected
                ? Border.all(color: Colors.transparent)
                : Border.all(color: Colors.transparent),
          ),
          child: Center(
            child: Text(
              "\$$amount",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAmountField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border:
            _selectedChipAmount == null &&
                _customAmountController.text.isNotEmpty
            ? Border.all(color: const Color(0xFF1B5E20), width: 2)
            : null,
      ),
      child: TextField(
        controller: _customAmountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          icon: Icon(Icons.attach_money, color: Colors.grey),
          hintText: "Custom Amount",
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.credit_card, color: Color(0xFF1B5E20)),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Apple Pay / Credit Card",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "SECURE STRIPE PAYMENT",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.radio_button_checked, color: Color(0xFF1B5E20)),
        ],
      ),
    );
  }

  Widget _buildDonateButton() {
    // Disable button if amount is 0 or invalid
    final bool isEnabled = _effectiveAmount > 0;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isLoading || !isEnabled) ? null : _handleDonation,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF57C00), // Orange/Gold
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Processing...",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isEnabled
                        ? "Donate \$${_effectiveAmount.toStringAsFixed(2)}"
                        : "Enter Amount",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _handleDonation() async {
    final amount = _effectiveAmount;
    if (amount <= 0) return;

    // Validate amount bounds
    if (amount < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum donation is \$1.00'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (amount > 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum donation is \$10,000.00'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Unfocus keyboard
    FocusScope.of(context).unfocus();

    await StripeService.instance.makePayment(
      amount: amount,
      currency: 'AUD',
      onResult: (success) {
        if (!mounted) return;
        setState(() => _isLoading = false);

        if (success) {
          // Reset form on success
          setState(() {
            _selectedChipAmount = 50; // Reset to default
            _customAmountController.clear();
          });

          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 50),
                  SizedBox(height: 10),
                  Text("Jazak Allah Khair!"),
                ],
              ),
              content: const Text(
                "Your donation has been received successfully. May Allah reward you abundantly.",
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    "OK",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment cancelled or failed'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }
}
