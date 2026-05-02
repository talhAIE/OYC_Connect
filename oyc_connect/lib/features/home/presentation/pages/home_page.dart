import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:ntp/ntp.dart';
import 'dart:async';
import '../../../prayer_times/presentation/providers/prayer_times_provider.dart';
import '../../../prayer_times/data/models/prayer_time_model.dart';
import '../../../prayer_times/data/models/jummah_config.dart';
import '../widgets/jummah_detail_dialog.dart';
import '../../../community/presentation/providers/community_providers.dart';
import '../../../classes/presentation/providers/classes_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  Future<void> _refreshAll() async {
    // Invalidate Prayer Times
    ref.invalidate(todayPrayerTimeProvider);
    ref.invalidate(jummahConfigProvider);

    // Invalidate Community
    ref.invalidate(eventsProvider);
    ref.invalidate(announcementsProvider);

    // Invalidate Classes
    ref.invalidate(weeklySchedulesProvider);
    ref.invalidate(quranSchedulesProvider);

    // Add small delay for UI effect
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final prayerTimeAsync = ref.watch(todayPrayerTimeProvider);
    final jummahConfigAsync = ref.watch(jummahConfigProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light background
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          color: const Color(0xFF1B5E20),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                    return _PrayerContent(
                      prayerTime: prayerTime,
                      jummahConfig: jummahConfigAsync.asData?.value,
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          // 🕌 Masjid Icon
          Icon(
            Icons.mosque,
            size: 40,
            color: Color.fromARGB(255, 163, 129, 3), // Muted Gold
          ),

          SizedBox(width: 10),

          // 🏷️ Musalla Name
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '1881 MUSALLA',
                style: TextStyle(
                  color: Color.fromARGB(255, 163, 129, 3),
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerContent extends StatefulWidget {
  final PrayerTime prayerTime;
  final JummahConfig? jummahConfig;
  const _PrayerContent({required this.prayerTime, this.jummahConfig});

  @override
  State<_PrayerContent> createState() => _PrayerContentState();
}

class _PrayerContentState extends State<_PrayerContent> {
  Timer? _timer;
  String _nextPrayerName = "--";
  String _nextPrayerTime = "--:--";
  String _countdown = "--";
  String _activePrayerName = ""; // For highlighting the list
  int _ntpOffset = 0;
  String _currentClockTime = "--:--:--"; // Unified clock time
  bool _isIqamahMode = false; // New state for UI label

  @override
  void initState() {
    super.initState();
    _syncNtp();
    _startTimer();
  }

  Future<void> _syncNtp() async {
    try {
      _ntpOffset = await NTP.getNtpOffset(localTime: DateTime.now());
    } catch (_) {
      // Fail silently, default to device time
    }
  }

  @override
  void didUpdateWidget(covariant _PrayerContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.prayerTime != oldWidget.prayerTime ||
        widget.jummahConfig != oldWidget.jummahConfig) {
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
    final melbourne = tz.getLocation('Australia/Melbourne');
    // Adjust local device time by NTP offset to match the Clock widget
    final trueNow = DateTime.now().add(Duration(milliseconds: _ntpOffset));
    final now = tz.TZDateTime.from(trueNow, melbourne);

    if (mounted) {
      setState(() {
        _currentClockTime = DateFormat('hh:mm:ss a').format(now);
      });
    }

    final pt = widget.prayerTime;
    final isFriday = now.weekday == DateTime.friday;

    // Robust Parser
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

    // Helper to get limit (Iqamah ?? Adhan + 10m)
    // NOTE: User wants "Stay at Adhan time until Iqamah".
    // So we need:
    // 1. DisplayTime (Adhan)
    // 2. ThresholdTime (Iqamah)
    Map<String, dynamic> buildPrayerData(String adhanStr, String? iqamaStr) {
      final adhan = parseTime(adhanStr);
      tz.TZDateTime? limit = parseTime(iqamaStr);

      // If no iqamah, maybe fallback to adhan + 20 mins?
      // Or just use adhan if that's the data behavior.
      // Let's assume there is always ample time.
      // If limit is null, we set it to adhan to maintain safety,
      // but effectively this means it switches at Adhan.
      limit ??= adhan;

      return {"adhan": adhan, "limit": limit};
    }

    final prayersData = {
      "FAJR": buildPrayerData(pt.fajr, pt.fajrIqama),
      "DHUHR": buildPrayerData(pt.dhuhr, pt.dhuhrIqama),
      "ASR": buildPrayerData(pt.asr, pt.asrIqama),
      "MAGHRIB": buildPrayerData(pt.maghrib, pt.maghribIqama),
      "ISHA": buildPrayerData(pt.isha, pt.ishaIqama),
    };

    if (isFriday && widget.jummahConfig != null) {
      // For Jummah: Display = Khutbah, Limit = JummahTime (Jamaat)
      final khutbah = parseTime(widget.jummahConfig!.khutbahTime);
      final jamaat = parseTime(widget.jummahConfig!.jummahTime);

      prayersData["JUMMAH"] = {"adhan": khutbah, "limit": jamaat ?? khutbah};
    }

    // Sort by Display Time (Adhan)
    final sortedKeys = prayersData.keys.toList()
      ..sort((a, b) {
        final dataA = prayersData[a];
        final dataB = prayersData[b];
        if (dataA == null || dataB == null) return 0;
        final tA = dataA["adhan"] as tz.TZDateTime?;
        final tB = dataB["adhan"] as tz.TZDateTime?;
        if (tA == null) return 1;
        if (tB == null) return -1;
        return tA.compareTo(tB);
      });

    String? determinedName;
    tz.TZDateTime? determinedTime;
    bool isIqamah = false;

    // Logic: Find first prayer where Now < Limit
    for (var key in sortedKeys) {
      final data = prayersData[key];
      if (data == null) continue;
      final limit = data["limit"] as tz.TZDateTime?;
      final adhan = data["adhan"] as tz.TZDateTime?;

      if (limit != null && now.isBefore(limit)) {
        determinedName = key;

        if (adhan != null && now.isAfter(adhan)) {
          // Adhan passed, waiting for Iqamah
          determinedTime = limit;
          isIqamah = true;
        } else {
          // Before Adhan
          determinedTime = adhan;
          isIqamah = false;
        }
        break;
      }
    }

    // Fallback: Tomorrow Fajr
    if (determinedName == null) {
      determinedName = "FAJR";
      final data = prayersData["FAJR"];
      if (data != null && data["adhan"] != null) {
        // Create tomorrow's time
        final t = data["adhan"] as tz.TZDateTime;
        determinedTime = t.add(const Duration(days: 1));
        isIqamah = false;
      }
    }

    if (mounted) {
      setState(() {
        _isIqamahMode = isIqamah;
        _nextPrayerName = determinedName ?? "NONE";

        // Active Prayer Name for List (Strip " (TOMORROW)" for matching)
        _activePrayerName = _nextPrayerName
            .replaceAll(" (TOMORROW)", "")
            .trim(); // e.g. "FAJR"

        // Show Adhan Time
        _nextPrayerTime = determinedTime != null
            ? DateFormat.jm().format(determinedTime)
            : "--:--";

        if (determinedTime != null) {
          final diff = determinedTime.difference(now);
          // If diff is negative (e.g. Now is 5:10, Fajr is 5:00),
          // it means Adhan passed, but we are waiting for Iqamah.
          // User: "Stayed on that adhan time".
          // The countdown typically counts DOWN to the Adhan.
          // If Adhan passed, maybe show "IQAMAH IN..." or just "NOW"?
          // Use Case: 8:26 Adhan. 8:30 Now. 8:36 Iqamah.
          // Card shows: MAGHRIB 8:26 PM.
          // Countdown: We can show "Since 4m" or "Iqamah in 6m"?
          // Let's stick to "NOW" if adhan passed, or maybe "IQAMAH SOON".
          // User didn't specify countdown behavior, just card content.
          // Current logic: `if (diff.isNegative) "NOW"`. Keep it.

          if (diff.isNegative) {
            // We are in the grace period before Iqamah
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
    return Column(
      children: [
        // Time just above the card
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: _MelbourneClock(
              timeStr: _currentClockTime,
            ), // Pass unified time
          ),
        ),
        _NextPrayerCard(
          prayerName: _nextPrayerName,
          prayerTime: _nextPrayerTime,
          countdown: _countdown,
          isIqamah: _isIqamahMode, // Pass mode to card
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Today's Times",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black.withAlpha(175),
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _PrayerList(
          prayerTime: widget.prayerTime,
          jummahConfig: widget.jummahConfig,
          activePrayerName: _activePrayerName, // Passing state down
        ),
      ],
    );
  }
}

class _NextPrayerCard extends StatelessWidget {
  final String prayerName;
  final String prayerTime;
  final String countdown;
  final bool isIqamah; // New param

  const _NextPrayerCard({
    required this.prayerName,
    required this.prayerTime,
    required this.countdown,
    this.isIqamah = false,
  });

  @override
  Widget build(BuildContext context) {
    // Formatted Date
    final melbourne = tz.getLocation('Australia/Melbourne');
    final now = tz.TZDateTime.now(melbourne);
    final dateStr = DateFormat('EEEE, d MMM').format(now);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 22, 65, 16).withOpacity(0.7),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 1, 107, 1), // Same green as adhan time
            Color.fromARGB(255, 29, 99, 1), // Darker Teal
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background Pattern
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.mosque,
              size: 140,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Label + Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isIqamah ? "IQAMAH" : "NEXT PRAYER", // Dynamic Label
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Main Content: Name & Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Name (Flexible to avoid overflow)
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          prayerName.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white, // Amber/Gold accent
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Time
                    Text(
                      prayerTime,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Bottom Row: Countdown & Action
                Row(
                  children: [
                    // Countdown Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "In $countdown",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    Material(
                      color: const Color.fromARGB(
                        255,
                        22,
                        22,
                        18,
                      ).withOpacity(0.22), // 👈 background color
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () => context.go('/home/prayer-calendar'),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                "CALENDAR",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
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
}

class _PrayerList extends StatelessWidget {
  final dynamic prayerTime;
  final JummahConfig? jummahConfig;
  final String activePrayerName; // From parent

  const _PrayerList({
    required this.prayerTime,
    this.jummahConfig,
    required this.activePrayerName,
  });

  @override
  Widget build(BuildContext context) {
    final melbourne = tz.getLocation('Australia/Melbourne');
    final now = tz.TZDateTime.now(melbourne);
    final isFriday = now.weekday == DateTime.friday;

    IconData getPrayerIcon(String name) {
      switch (name) {
        case "Fajr":
          return Icons.wb_twilight; // Orange Sun
        case "Sunrise":
          return Icons.wb_iridescent; // Red Sun
        case "Dhuhr":
          return Icons.wb_sunny; // Yellow Sun
        case "Asr":
          return Icons.wb_cloudy; // Sun + Cloud
        case "Maghrib": // Sunset
          return Icons.wb_twilight;
        case "Isha":
          return Icons.nights_stay; // Moon
        default:
          return Icons.access_time_filled;
      }
    }

    Color getPrayerColor(String name) {
      switch (name) {
        case "Fajr":
          return Colors.orange;
        case "Sunrise":
          return Colors.redAccent;
        case "Dhuhr":
          return Colors.amber;
        case "Asr":
          return Colors.lightBlue; // Cloud color
        case "Maghrib":
          return Colors.deepOrange;
        case "Isha":
          return const Color(0xFF1A237E); // Indigo
        default:
          return const Color(0xFF1B5E20);
      }
    }

    // Match ignoring case and "JUMMAH" vs "Dhuhr" on Friday
    bool checkActive(String name) {
      if (activePrayerName.toUpperCase() == name.toUpperCase()) return true;
      // Handle JUMMAH / DHUHR alias
      if (name == "Dhuhr" && activePrayerName == "JUMMAH") return true;
      return false;
    }

    return Column(
      children: [
        _buildPrayerItem(
          "Fajr",
          prayerTime.fajr,
          prayerTime.fajrIqama,
          checkActive("Fajr"),
          getPrayerIcon("Fajr"),
          getPrayerColor("Fajr"),
        ),
        const SizedBox(height: 2),
        if (isFriday && jummahConfig != null)
          _buildJummahItem(
            context,
            jummahConfig!,
            checkActive("JUMMAH") || checkActive("Dhuhr"),
          )
        else
          _buildPrayerItem(
            "Dhuhr",
            prayerTime.dhuhr,
            prayerTime.dhuhrIqama,
            checkActive("Dhuhr"),
            getPrayerIcon("Dhuhr"),
            getPrayerColor("Dhuhr"),
          ),
        const SizedBox(height: 2),
        _buildPrayerItem(
          "Asr",
          prayerTime.asr,
          prayerTime.asrIqama,
          checkActive("Asr"),
          getPrayerIcon("Asr"),
          getPrayerColor("Asr"),
        ),
        const SizedBox(height: 2),
        _buildPrayerItem(
          "Maghrib",
          prayerTime.maghrib,
          prayerTime.maghribIqama,
          checkActive("Maghrib"),
          getPrayerIcon("Maghrib"),
          getPrayerColor("Maghrib"),
        ),
        const SizedBox(height: 2),
        _buildPrayerItem(
          "Isha",
          prayerTime.isha,
          prayerTime.ishaIqama,
          checkActive("Isha"),
          getPrayerIcon("Isha"),
          getPrayerColor("Isha"),
        ),
      ],
    );
  }

  Widget _buildPrayerItem(
    String name,
    String adhan,
    String? iqamah,
    bool isActive,
    IconData icon,
    Color iconColor,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[50] : Colors.white, // Light Green
        borderRadius: BorderRadius.circular(24),
        border: isActive
            ? Border.all(color: Colors.green.shade200, width: 1.5)
            : Border.all(
                color: const Color.fromARGB(255, 41, 41, 41).withOpacity(0.2),
                width: 1,
              ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color.fromARGB(255, 14, 61, 16).withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Icon - Always Colored
              Icon(
                icon,
                color: iconColor, // Icons colors DON'T change
                size: 28,
              ),
              const SizedBox(width: 16),

              // Texts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87, // Always Black
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Adhan $adhan",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700], // Always Grey
                      ),
                    ),
                  ],
                ),
              ),

              // Iqamah Text Only (No Box)
              if (iqamah != null)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "IQAMAH",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: isActive ? Colors.green[800] : Colors.teal,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      iqamah,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJummahItem(
    BuildContext context,
    JummahConfig config,
    bool isActive,
  ) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => JummahDetailDialog(config: config),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white, // Light theme
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.teal.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.1),
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
                color: Colors.teal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mosque, color: Colors.teal),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Jummah Prayer",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[800],
                    ),
                  ),
                  Text(
                    "Tap for details", // Helper text
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  config.khutbahTime,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800],
                  ),
                ),
                Text(
                  "KHUTBAH",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MelbourneClock extends StatelessWidget {
  final String timeStr;
  const _MelbourneClock({required this.timeStr});

  @override
  Widget build(BuildContext context) {
    return Text(
      timeStr,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w900,
        color: Colors.black.withAlpha(205), // "Just numbers in black"
        letterSpacing: 0.5,
      ),
    );
  }
}
