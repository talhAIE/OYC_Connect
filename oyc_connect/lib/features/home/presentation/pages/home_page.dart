import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../prayer_times/presentation/providers/prayer_times_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerTimeAsync = ref.watch(todayPrayerTimeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              prayerTimeAsync.when(
                data: (prayerTime) {
                  if (prayerTime == null) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text("No prayer times found for today."),
                      ),
                    );
                  }
                  return _PrayerContent(prayerTime: prayerTime);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MASJID AL-RAWDAH',
              style: TextStyle(
                color: Colors.teal[700],
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Assalamu Alaikum,',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.notifications_outlined, color: Colors.grey),
        ),
      ],
    );
  }
}

class _PrayerContent extends StatelessWidget {
  final dynamic
  prayerTime; // Typed as dynamic because generated model might be finicky with imports, but valid in context
  const _PrayerContent({required this.prayerTime});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _NextPrayerCard(prayerTime: prayerTime),
        const SizedBox(height: 24),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Today's Times",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _PrayerList(prayerTime: prayerTime),
      ],
    );
  }
}

class _NextPrayerCard extends StatelessWidget {
  final dynamic prayerTime;
  const _NextPrayerCard({required this.prayerTime});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement actual countdown logic
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B5E20), // Dark Green
            Color(0xFF2E7D32), // Light Green
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.amber),
                    SizedBox(width: 8),
                    Text(
                      "NEXT: ASR PRAYER",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                "15 Shaban, 1446",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              prayerTime.asr ?? "--:--",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
          ),
          const Center(
            child: Text(
              "IQAMAH IN 14M 22S",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                "VIEW FULL CALENDAR",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerList extends StatelessWidget {
  final dynamic prayerTime;
  const _PrayerList({required this.prayerTime});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildPrayerItem("Fajr", prayerTime.fajr, prayerTime.fajrIqama, false),
        const SizedBox(height: 12),
        _buildPrayerItem(
          "Dhuhr",
          prayerTime.dhuhr,
          prayerTime.dhuhrIqama,
          false,
        ),
        const SizedBox(height: 12),
        _buildPrayerItem("Asr", prayerTime.asr, prayerTime.asrIqama, true),
        const SizedBox(height: 12),
        _buildPrayerItem(
          "Maghrib",
          prayerTime.maghrib,
          prayerTime.maghribIqama,
          false,
        ),
        const SizedBox(height: 12),
        _buildPrayerItem("Isha", prayerTime.isha, prayerTime.ishaIqama, false),
      ],
    );
  }

  Widget _buildPrayerItem(
    String name,
    String adhan,
    String? iqamah,
    bool isActive,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isActive
            ? Border.all(color: const Color(0xFF1B5E20), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF1B5E20) : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.access_time,
              color: isActive ? Colors.white : Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isActive ? const Color(0xFF1B5E20) : Colors.black87,
                  ),
                ),
                Text(
                  "ADHAN $adhan",
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive
                        ? const Color(0xFF1B5E20).withOpacity(0.7)
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                (iqamah != null && iqamah.isNotEmpty) ? iqamah : adhan,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isActive ? const Color(0xFF1B5E20) : Colors.black87,
                ),
              ),
              Text(
                "IQAMAH",
                style: TextStyle(
                  fontSize: 10,
                  color: isActive
                      ? const Color(0xFF1B5E20).withOpacity(0.7)
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
