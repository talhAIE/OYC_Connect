import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/donation_constants.dart';

/// Opens the official donation page in the external browser only.
class DonationPage extends ConsumerStatefulWidget {
  const DonationPage({super.key});

  @override
  ConsumerState<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends ConsumerState<DonationPage> {
  bool _opening = false;

  Future<void> _openDonationWebsite() async {
    final uri = DonationConstants.generalDonationUri;
    setState(() => _opening = true);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the website. Try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the website. Try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
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
              const SizedBox(height: 28),
              _buildInfoCard(),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _opening ? null : _openDonationWebsite,
                  icon: _opening
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.open_in_browser_rounded),
                  label: Text(
                    _opening ? 'Opening browser...' : 'Open donation website',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF57C00),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[400],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'ouryouthcenter.com.au',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
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

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.volunteer_activism_rounded,
                  color: Color(0xFF1B5E20),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'External website',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Colors.grey[900],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'This app does not process payments. Tapping the button opens our official website in your device browser, where donations are completed.',
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
