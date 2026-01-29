import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../prayer_times/data/models/prayer_time_model.dart';
import '../../presentation/providers/prayer_times_provider.dart';

final monthlyPrayerTimesProvider = FutureProvider.autoDispose
    .family<List<PrayerTime>, DateTime>((ref, date) async {
      final repo = ref.watch(prayerTimesRepositoryProvider);
      return repo.getMonthlyPrayerTimes(date.year, date.month);
    });

class PrayerCalendarPage extends ConsumerWidget {
  const PrayerCalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine current month in Melbourne
    final melbourne = tz.getLocation('Australia/Melbourne');
    final now = tz.TZDateTime.now(melbourne);

    // Use a stable key (stripped of time) so the provider isn't recreated on every build
    final monthKey = DateTime(now.year, now.month);

    // We could allow navigating months, but for now let's just show current month
    final prayerTimesAsync = ref.watch(monthlyPrayerTimesProvider(monthKey));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          DateFormat('MMMM yyyy').format(now),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: prayerTimesAsync.when(
        data: (prayerTimes) {
          if (prayerTimes.isEmpty) {
            return const Center(
              child: Text("No prayer times available for this month."),
            );
          }

          // Find index of today
          int initialIndex = 0;
          for (int i = 0; i < prayerTimes.length; i++) {
            final pt = prayerTimes[i];
            if (pt.date.year == now.year &&
                pt.date.month == now.month &&
                pt.date.day == now.day) {
              initialIndex = i;
              break;
            }
          }

          final itemScrollController = ItemScrollController();

          return ScrollablePositionedList.separated(
            itemScrollController: itemScrollController,
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              100,
            ), // Added 100 padding at bottom
            itemCount: prayerTimes.length,
            initialScrollIndex: initialIndex,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final pt = prayerTimes[index];
              final isToday =
                  pt.date.year == now.year &&
                  pt.date.month == now.month &&
                  pt.date.day == now.day;
              return _PrayerDayCard(prayerTime: pt, isToday: isToday);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _PrayerDayCard extends StatelessWidget {
  final PrayerTime prayerTime;
  final bool isToday;

  const _PrayerDayCard({required this.prayerTime, required this.isToday});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isToday
            ? Border.all(color: const Color(0xFF1B5E20), width: 2)
            : Border.all(
                color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.4),
              ),
        boxShadow: [
          BoxShadow(
            color: isToday
                ? const Color(0xFF1B5E20).withOpacity(0.4)
                : Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header: Date
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: isToday
                  ? const LinearGradient(
                      colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                    )
                  : null,
              color: isToday ? null : Colors.grey.withAlpha(30),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, d MMMM').format(prayerTime.date),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isToday
                        ? Colors.white
                        : const Color.fromARGB(221, 0, 0, 0),
                  ),
                ),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 12, color: Colors.amber),
                        SizedBox(width: 4),
                        Text(
                          "TODAY",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Times Grid
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildTimeItem("Fajr", prayerTime.fajr, Icons.wb_twilight),
                    _buildTimeItem("Dhuhr", prayerTime.dhuhr, Icons.wb_sunny),
                    _buildTimeItem("Asr", prayerTime.asr, Icons.wb_cloudy),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(color: Colors.grey[100], height: 1),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildTimeItem(
                      "Maghrib",
                      prayerTime.maghrib,
                      Icons.wb_twilight,
                    ),
                    _buildTimeItem("Isha", prayerTime.isha, Icons.nights_stay),
                    _buildTimeItem(
                      "Jumuah",
                      (prayerTime.date.weekday == DateTime.friday)
                          ? (prayerTime.jumuah ?? '-')
                          : '-',
                      Icons.mosque,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeItem(String label, String time, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.black.withAlpha(125)),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black.withAlpha(125),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black.withAlpha(185),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
