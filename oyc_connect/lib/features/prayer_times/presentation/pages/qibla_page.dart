import 'dart:math' show cos, sin;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:timezone/timezone.dart' as tz;
import '../../../prayer_times/presentation/providers/prayer_times_provider.dart';

class QiblaPage extends ConsumerStatefulWidget {
  const QiblaPage({super.key});

  @override
  ConsumerState<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends ConsumerState<QiblaPage> {
  bool _hasPermissions = false;
  bool _isChecking = true;
  String _locationName = "Location";

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final status = await FlutterQiblah.checkLocationStatus();
    if (status.enabled && status.status == LocationPermission.always || status.status == LocationPermission.whileInUse) {
      _getCurrentLocation();
      setState(() {
        _hasPermissions = true;
        _isChecking = false;
      });
    } else {
      final requestStatus = await FlutterQiblah.requestPermissions();
      if (requestStatus == LocationPermission.always || requestStatus == LocationPermission.whileInUse) {
        _getCurrentLocation();
        setState(() {
          _hasPermissions = true;
          _isChecking = false;
        });
      } else {
        setState(() {
          _hasPermissions = false;
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      
      try {
        final geocoding = Geocoding();
        List<Placemark> placemarks = await geocoding.placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          setState(() {
            _locationName = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea ?? "Location";
          });
        }
      } catch (e) {
        debugPrint("Error reverse geocoding: $e");
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final ptAsync = ref.watch(todayPrayerTimeProvider);
    final pt = ptAsync.asData?.value;
    final jcAsync = ref.watch(jummahConfigProvider);
    final jc = jcAsync.asData?.value;

    String nextName = "Fajar";
    String nextTime = "04:33 AM";
    
    if (pt != null) {
      final melbourne = tz.getLocation('Australia/Melbourne');
      final now = tz.TZDateTime.now(melbourne);
      
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
          return tz.TZDateTime(melbourne, now.year, now.month, now.day, hour, minute);
        } catch (_) { return null; }
      }

      final prayers = [
        {"name": "Fajr", "time": parseTime(pt.fajr)},
        {"name": "Dhuhr", "time": parseTime(pt.dhuhr)},
        {"name": "Asr", "time": parseTime(pt.asr)},
        {"name": "Maghrib", "time": parseTime(pt.maghrib)},
        {"name": "Isha", "time": parseTime(pt.isha)},
      ];

      if (now.weekday == DateTime.friday && jc != null) {
        prayers[1] = {"name": "Jummah", "time": parseTime(jc.khutbahTime) ?? parseTime(pt.dhuhr)};
      }

      bool found = false;
      for (var p in prayers) {
        final t = p["time"] as tz.TZDateTime?;
        if (t != null && now.isBefore(t)) {
          nextName = p["name"] as String;
          nextTime = DateFormat.jm().format(t);
          found = true;
          break;
        }
      }
      if (!found) {
        nextName = "Fajr";
        final t = parseTime(pt.fajr);
        if (t != null) {
          nextTime = DateFormat.jm().format(t.add(const Duration(days: 1)));
        }
      }
    }

    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_hasPermissions) {
      return Scaffold(
        appBar: AppBar(title: const Text('Qibla Direction')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Location permission is required to calculate Qibla.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkPermissions,
                child: const Text('Grant Permission'),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF194025), // Dark Green
              Color(0xFF0F2516), // Very Dark Green
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Mosque Silhouette Background
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 400,
                child: CustomPaint(
                  painter: _MosqueSilhouettePainter(),
                ),
              ),

              // Main Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Location Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                _locationName,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                        const SizedBox(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Main Compass & Qibla Widget
                  Expanded(
                    child: StreamBuilder<QiblahDirection>(
                      stream: FlutterQiblah.qiblahStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Colors.white));
                        }
                        if (snapshot.hasError) {
                          return Center(child: Icon(Icons.error, color: Colors.white));
                        }

                        final qiblahDirection = snapshot.data!;
                        final direction = qiblahDirection.direction; // Heading
                        final offset = qiblahDirection.offset; // Absolute Qibla angle from North
                        
                        final diff = (direction - offset) % 360;
                        final isAligned = diff < 2.0 || diff > 358.0;
                        if (isAligned) HapticFeedback.lightImpact();

                        // Determine Qibla direction text (N, S, E, W, etc) from absolute offset
                        String qiblaDirText = "North";
                        final qAngle = offset % 360;
                        if (qAngle >= 337.5 || qAngle < 22.5) {
                          qiblaDirText = 'North';
                        } else if (qAngle >= 22.5 && qAngle < 67.5) qiblaDirText = 'Northeast';
                        else if (qAngle >= 67.5 && qAngle < 112.5) qiblaDirText = 'East';
                        else if (qAngle >= 112.5 && qAngle < 157.5) qiblaDirText = 'Southeast';
                        else if (qAngle >= 157.5 && qAngle < 202.5) qiblaDirText = 'South';
                        else if (qAngle >= 202.5 && qAngle < 247.5) qiblaDirText = 'Southwest';
                        else if (qAngle >= 247.5 && qAngle < 292.5) qiblaDirText = 'West';
                        else if (qAngle >= 292.5 && qAngle < 337.5) qiblaDirText = 'Northwest';

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Big Compass Stack
                            SizedBox(
                              width: 300,
                              height: 300,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Dial: Rotates with device heading (N/S/E/W move as user rotates)
                                  Transform.scale(
                                    scale: 300 / 280,
                                    child: Transform.rotate(
                                      angle: (direction * (pi / 180) * -1),
                                      child: CustomPaint(
                                        size: const Size(280, 280),
                                        painter: _SilverCompassDialPainter(),
                                      ),
                                    ),
                                  ),
                                  // Needle: Fixed to phone heading (points straight UP). User aligns this needle with the Kaaba.
                                  Transform.scale(
                                    scale: 300 / 280,
                                    child: CustomPaint(
                                      size: const Size(20, 200),
                                      painter: _ClassicNeedlePainter(),
                                    ),
                                  ),
                                  // Kaaba icon: Rotates to always point toward Qibla
                                  Transform.scale(
                                    scale: 300 / 280,
                                    child: Transform.rotate(
                                      angle: ((offset - direction) * (pi / 180)),
                                      child: Container(
                                        height: 280,
                                        alignment: Alignment.topCenter,
                                        child: Transform.translate(
                                          offset: const Offset(0, -18),
                                          child: Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.4),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                )
                                              ],
                                            ),
                                            alignment: Alignment.center,
                                            child: const Text('🕋', style: TextStyle(fontSize: 24)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 40),
                            
                            // Qibla Direction Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                borderRadius: BorderRadius.circular(30),
                                color: Colors.black.withValues(alpha: 0.1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.mosque, color: Colors.white, size: 28),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Qibla Direction",
                                        style: TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                      Text(
                                        qiblaDirText,
                                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Bottom Prayer Card
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            // Soft glow inside the card
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.1),
                                      Colors.transparent,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Mosque Icon Circle
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                                    ),
                                    child: const Icon(Icons.mosque, color: Colors.white, size: 28),
                                  ),
                                  const SizedBox(width: 16),
                                  // Prayer Text
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Next prayer - $nextName",
                                          style: const TextStyle(color: Colors.white, fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          nextTime,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(Icons.access_time, color: Colors.white, size: 14),
                                              SizedBox(width: 6),
                                              Text(
                                                "View time",
                                                style: TextStyle(color: Colors.white, fontSize: 12),
                                              ),
                                              Icon(Icons.chevron_right, color: Colors.white, size: 16),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.white, size: 24),
                                ],
                              ),
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
      ),
    );
  }
}

class _MosqueSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
      
    final path = Path();
    path.moveTo(0, size.height);
    
    // Left side curve
    path.lineTo(0, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.1, size.height * 0.7, size.width * 0.2, size.height * 0.8);
    
    // Big Minaret
    path.lineTo(size.width * 0.22, size.height * 0.8);
    path.lineTo(size.width * 0.22, size.height * 0.2);
    path.lineTo(size.width * 0.24, size.height * 0.15); // Tip
    path.lineTo(size.width * 0.26, size.height * 0.2);
    path.lineTo(size.width * 0.26, size.height * 0.8);
    
    // Big Center Dome
    path.lineTo(size.width * 0.35, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.3, size.width * 0.65, size.height * 0.8);
    
    // Right smaller minaret
    path.lineTo(size.width * 0.7, size.height * 0.8);
    path.lineTo(size.width * 0.7, size.height * 0.4);
    path.lineTo(size.width * 0.72, size.height * 0.35); // Tip
    path.lineTo(size.width * 0.74, size.height * 0.4);
    path.lineTo(size.width * 0.74, size.height * 0.8);
    
    // Right dome
    path.lineTo(size.width * 0.8, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.9, size.height * 0.65, size.width, size.height * 0.8);
    
    path.lineTo(size.width, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SilverCompassDialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer Silver Bezel gradient
    final bezelPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFE0E0E0),
          Color(0xFFFFFFFF),
          Color(0xFF9E9E9E),
          Color(0xFFFFFFFF),
          Color(0xFFE0E0E0),
        ],
        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    
    // Outer shadow
    canvas.drawCircle(center, radius, Paint()..color = Colors.black.withValues(alpha: 0.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawCircle(center, radius, bezelPaint);

    // Inner Bezel Edge
    canvas.drawCircle(center, radius - 15, Paint()..color = Colors.grey.shade400);

    // Inner White Dial
    canvas.drawCircle(center, radius - 16, Paint()..color = Colors.white);

    // Ticks and Text
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final tickPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.0;
    
    for (int i = 0; i < 360; i += 2) {
      final angle = i * pi / 180;
      final isMajor = i % 10 == 0;
      final isCardinal = i % 90 == 0;
      final isIntercardinal = i % 45 == 0 && !isCardinal;
      
      final tickLength = isCardinal ? 12.0 : (isMajor ? 8.0 : 4.0);
      tickPaint.strokeWidth = isMajor ? 2.0 : 1.0;
      tickPaint.color = isMajor ? Colors.black87 : Colors.grey.shade600;

      final p1 = Offset(
        center.dx + (radius - 18) * cos(angle),
        center.dy + (radius - 18) * sin(angle),
      );
      final p2 = Offset(
        center.dx + (radius - 18 - tickLength) * cos(angle),
        center.dy + (radius - 18 - tickLength) * sin(angle),
      );
      canvas.drawLine(p1, p2, tickPaint);

      // Draw degrees every 20 degrees, rotated to follow the circle
      if (i % 20 == 0) {
        int compassDegree = (i + 90) % 360; // 270 (Top) -> 0
        canvas.save();
        canvas.translate(
          center.dx + (radius - 38) * cos(angle),
          center.dy + (radius - 38) * sin(angle),
        );
        canvas.rotate(angle + pi / 2); // Rotate text so bottom faces center
        
        textPainter.text = TextSpan(
          text: '$compassDegree',
          style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
        
        canvas.restore();
      }

      // Draw N, E, S, W, NE, NW, SE, SW
      if (isIntercardinal || isCardinal) {
        String label = '';
        if (i == 270) {
          label = 'N';
        } else if (i == 0) label = 'E';
        else if (i == 90) label = 'S';
        else if (i == 180) label = 'W';
        else if (i == 315) label = 'NE';
        else if (i == 45) label = 'SE';
        else if (i == 135) label = 'SW';
        else if (i == 225) label = 'NW';

        if (label.isNotEmpty) {
          canvas.save();
          canvas.translate(
            center.dx + (radius - 65) * cos(angle),
            center.dy + (radius - 65) * sin(angle),
          );
          
          textPainter.text = TextSpan(
            text: label,
            style: TextStyle(
              color: Colors.black87,
              fontSize: isCardinal ? 24 : 14,
              fontWeight: FontWeight.bold,
            ),
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
          canvas.restore();
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ClassicNeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final width = 16.0;
    
    // North Needle (Red) - Points UP
    final northPaintRight = Paint()..color = Colors.red.shade700;
    final northPaintLeft = Paint()..color = Colors.red.shade900;
    
    final northLeftPath = Path()
      ..moveTo(center.dx, 0)
      ..lineTo(center.dx, center.dy)
      ..lineTo(center.dx - width / 2, center.dy)
      ..close();
    canvas.drawPath(northLeftPath, northPaintLeft);
    
    final northRightPath = Path()
      ..moveTo(center.dx, 0)
      ..lineTo(center.dx + width / 2, center.dy)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(northRightPath, northPaintRight);

    // South Needle (Blue) - Points DOWN
    final southPaintRight = Paint()..color = Colors.blue.shade700;
    final southPaintLeft = Paint()..color = Colors.blue.shade900;

    final southLeftPath = Path()
      ..moveTo(center.dx, size.height)
      ..lineTo(center.dx, center.dy)
      ..lineTo(center.dx - width / 2, center.dy)
      ..close();
    canvas.drawPath(southLeftPath, southPaintLeft);

    final southRightPath = Path()
      ..moveTo(center.dx, size.height)
      ..lineTo(center.dx + width / 2, center.dy)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(southRightPath, southPaintRight);

    // Center Pivot
    canvas.drawCircle(center, 6, Paint()..color = Colors.grey.shade300);
    canvas.drawCircle(center, 3, Paint()..color = Colors.grey.shade600);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
