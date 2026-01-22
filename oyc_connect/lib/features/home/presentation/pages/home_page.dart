import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:ntp/ntp.dart';
import 'dart:async';
import '../../../prayer_times/presentation/providers/prayer_times_provider.dart';
import '../../../prayer_times/data/models/prayer_time_model.dart';

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
            const SizedBox(height: 4),
            const _MelbourneClock(),
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
  final dynamic prayerTime;
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
        // We need next prayer info to highlight the list, but for now let's just highlight based on time
        _PrayerList(prayerTime: prayerTime),
      ],
    );
  }
}

class _NextPrayerCard extends StatefulWidget {
  final PrayerTime? prayerTime;
  const _NextPrayerCard({required this.prayerTime});

  @override
  State<_NextPrayerCard> createState() => _NextPrayerCardState();
}

class _NextPrayerCardState extends State<_NextPrayerCard> {
  Timer? _timer;
  String _nextPrayerName = "--";
  String _nextPrayerTime = "--:--";
  String _countdown = "--";

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _NextPrayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.prayerTime != oldWidget.prayerTime) {
      _updateCalculation();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _updateCalculation();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCalculation();
    });
  }

  void _updateCalculation() {
    if (widget.prayerTime == null) return;

    final melbourne = tz.getLocation('Australia/Melbourne');
    final now = tz.TZDateTime.now(melbourne);
    final pt = widget.prayerTime!;

    // Robust Parser using Regex to avoid format/locale issues
    // Matches "4:39" or "4:39 AM" or "4:39AM" etc.
    tz.TZDateTime? parseTime(String? timeStr) {
      if (timeStr == null || timeStr.isEmpty) return null;
      try {
        final re = RegExp(r'(\d+):(\d+)\s*(AM|PM)?', caseSensitive: false);
        final match = re.firstMatch(timeStr);
        if (match == null) return null;

        int hour = int.parse(match.group(1)!);
        int minute = int.parse(match.group(2)!);
        String? period = match.group(3)?.toUpperCase();

        // Handle 12-hour format if AM/PM is present
        if (period != null) {
          if (period == 'PM' && hour != 12) hour += 12;
          if (period == 'AM' && hour == 12) hour = 0;
        }

        return tz.TZDateTime(
          melbourne,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );
      } catch (e) {
        return null;
      }
    }

    final prayers = {
      "FAJR": parseTime(pt.fajr),
      "DHUHR": parseTime(pt.dhuhr),
      "ASR": parseTime(pt.asr),
      "MAGHRIB": parseTime(pt.maghrib),
      "ISHA": parseTime(pt.isha),
    };

    // Check if we didn't get any valid times
    if (prayers.values.every((v) => v == null)) {
      if (mounted)
        setState(() {
          _countdown = "Error Parsing";
        });
      return;
    }

    // Sort
    final sortedKeys = prayers.keys.toList()
      ..sort((a, b) {
        final tA = prayers[a];
        final tB = prayers[b];
        if (tA == null) return 1;
        if (tB == null) return -1;
        return tA.compareTo(tB);
      });

    String? nextName;
    tz.TZDateTime? nextTime;

    for (var key in sortedKeys) {
      final t = prayers[key];
      if (t != null && t.isAfter(now)) {
        nextName = key;
        nextTime = t;
        break;
      }
    }

    // Fallback: Tomorrow Fajr
    if (nextName == null) {
      nextName = "FAJR (TOMORROW)";
      final t = prayers["FAJR"];
      if (t != null) {
        nextTime = t.add(const Duration(days: 1));
      }
    }

    if (mounted) {
      setState(() {
        _nextPrayerName = nextName ?? "NONE";

        // Show Adhan Time
        _nextPrayerTime = nextTime != null
            ? DateFormat.jm().format(nextTime)
            : "--:--";

        if (nextTime != null) {
          final diff = nextTime.difference(now);
          if (diff.isNegative) {
            _countdown = "NOW";
          } else {
            final hours = diff.inHours;
            final minutes = diff.inMinutes % 60;
            final seconds = diff.inSeconds % 60;
            _countdown = "${hours}H ${minutes}M ${seconds}S";
          }
        } else {
          _countdown = "--";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Formatted Date
    final melbourne = tz.getLocation('Australia/Melbourne');
    final now = tz.TZDateTime.now(melbourne);
    final dateStr = DateFormat('d MMMM, yyyy').format(now);

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
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      "NEXT: $_nextPrayerName",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                dateStr, // Using Melbourne date
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              _nextPrayerTime,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
          ),
          Center(
            child: Text(
              "STARTS IN $_countdown",
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/home/prayer-calendar'),
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
    // We re-calculate current prayer here simply to highlight
    final melbourne = tz.getLocation('Australia/Melbourne');
    final now = tz.TZDateTime.now(melbourne);

    // Robust Parser (duplicated for now for simplicity in stateless widget)
    tz.TZDateTime? parseTime(String? timeStr) {
      if (timeStr == null || timeStr.isEmpty) return null;
      try {
        final re = RegExp(r'(\d+):(\d+)\s*(AM|PM)?', caseSensitive: false);
        final match = re.firstMatch(timeStr);
        if (match == null) return null;
        int hour = int.parse(match.group(1)!);
        int minute = int.parse(match.group(2)!);
        String? period = match.group(3)?.toUpperCase();
        if (period != null) {
          if (period == 'PM' && hour != 12) hour += 12;
          if (period == 'AM' && hour == 12) hour = 0;
        }
        return tz.TZDateTime(
          melbourne,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );
      } catch (e) {
        return null;
      }
    }

    final prayers = {
      "Fajr": parseTime(prayerTime.fajr),
      "Dhuhr": parseTime(prayerTime.dhuhr),
      "Asr": parseTime(prayerTime.asr),
      "Maghrib": parseTime(prayerTime.maghrib),
      "Isha": parseTime(prayerTime.isha),
    };

    // Let's reuse logic: Find first prayer > now.
    String? nextName;
    final sortedKeys = prayers.keys.toList()
      ..sort((a, b) => (prayers[a]?.compareTo(prayers[b]!) ?? 0));

    for (var key in sortedKeys) {
      final t = prayers[key];
      if (t != null && t.isAfter(now)) {
        nextName = key;
        break;
      }
    }

    // If nextName is null (after Isha), usually we highlight Fajr (tomorrow) or keep Isha?
    // Let's highlight Fajr if it's tomorrow.
    final target = nextName ?? "Fajr";

    return Column(
      children: [
        _buildPrayerItem(
          "Fajr",
          prayerTime.fajr,
          prayerTime.fajrIqama,
          target == "Fajr",
        ),
        const SizedBox(height: 12),
        _buildPrayerItem(
          "Dhuhr",
          prayerTime.dhuhr,
          prayerTime.dhuhrIqama,
          target == "Dhuhr",
        ),
        const SizedBox(height: 12),
        _buildPrayerItem(
          "Asr",
          prayerTime.asr,
          prayerTime.asrIqama,
          target == "Asr",
        ),
        const SizedBox(height: 12),
        _buildPrayerItem(
          "Maghrib",
          prayerTime.maghrib,
          prayerTime.maghribIqama,
          target == "Maghrib",
        ),
        const SizedBox(height: 12),
        _buildPrayerItem(
          "Isha",
          prayerTime.isha,
          prayerTime.ishaIqama,
          target == "Isha",
        ),
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

class _MelbourneClock extends StatefulWidget {
  const _MelbourneClock();

  @override
  State<_MelbourneClock> createState() => _MelbourneClockState();
}

class _MelbourneClockState extends State<_MelbourneClock> {
  Timer? _timer;
  String _timeStr = "--:--:--";
  int _ntpOffset = 0;

  @override
  void initState() {
    super.initState();
    _syncNtp();
    // Start timer immediately, updateTime will use 0 offset until sync completes
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  Future<void> _syncNtp() async {
    try {
      _ntpOffset = await NTP.getNtpOffset(localTime: DateTime.now());
    } catch (_) {
      // Fail silently, default to device time
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final melbourne = tz.getLocation('Australia/Melbourne');
    // Adjust local device time by NTP offset to get "True" time
    final trueNow = DateTime.now().add(Duration(milliseconds: _ntpOffset));
    final nowMel = tz.TZDateTime.from(trueNow, melbourne);

    final str = DateFormat('hh:mm:ss a').format(nowMel);

    if (mounted) {
      if (_timeStr != str) {
        setState(() {
          _timeStr = str;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.access_time_filled, size: 14, color: Colors.teal),
        const SizedBox(width: 4),
        Text(
          "Melbourne: $_timeStr",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.teal[800],
          ),
        ),
      ],
    );
  }
}
