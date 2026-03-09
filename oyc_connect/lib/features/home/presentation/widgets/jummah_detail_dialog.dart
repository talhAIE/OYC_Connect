import 'package:flutter/material.dart';
import '../../../prayer_times/data/models/jummah_config.dart';

class JummahDetailDialog extends StatelessWidget {
  final JummahConfig config;

  const JummahDetailDialog({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: const Color(
            0xFF263238,
          ), // Dark Blue-Grey resembling the image's dark theme
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.amber,
            width: 2,
          ), // Orange/Amber accent like the image text
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Craigieburn\nHighgate\nFriday\nPrayer',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 32),

              // Khutbah Section
              // Khutbah Section
              _buildInfoText(
                "Khutbah start at ${config.khutbahTime}",
                "throughout the year",
                isHighlight: true,
              ),

              if (config.khateebName != null &&
                  config.khateebName!.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  "Khateeb",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  config.khateebName!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Address Section
              const Text(
                "Address",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                config.address,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 32),

              // Reminders
              const Text(
                "Please bring along your prayer mat\nAnd please take your wudhu from home",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 32),

              // Parking Warning
              const Text(
                "Please park your car at the designated\nparking lot",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.amber, // Orange accent
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoText(
    String line1,
    String line2, {
    bool isHighlight = false,
  }) {
    return Column(
      children: [
        Text(
          line1,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          line2,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
