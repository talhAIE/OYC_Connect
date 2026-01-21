import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../models/prayer_time_model.dart';

class MasjidalScraperService {
  static const String _targetUrl =
      'https://timing.athanplus.com/masjid/widgets/monthly?theme=3&masjid_id=keLQajLM';

  Future<List<PrayerTime>> fetchMonthlyPrayerTimes() async {
    try {
      // On Web, browsers block requests to other domains (CORS).
      // We use a CORS proxy to bypass this during development/web usage.
      final url = kIsWeb
          ? 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(_targetUrl)}'
          : _targetUrl;

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load prayer times page: ${response.statusCode}',
        );
      }

      final document = parser.parse(response.body);

      // The table is likely the main structure. We need to find the rows.
      // Based on the image, it's a standard HTML table with rows for each day.
      // Headers: JANUARY, RAJAB, FAJR, SUNRISE, DHUHR, ASR, MAGHRIB, ISHA

      final rows = document.querySelectorAll('tr'); // Get all table rows

      List<PrayerTime> prayerTimes = [];

      // Skip header rows. Usually first 1 or 2 rows.
      // We can identify data rows by checking if they convert to a date/day.

      for (var row in rows) {
        final cells = row.querySelectorAll('td');
        if (cells.isEmpty)
          continue; // Skip header rows (usually <th>) or empty rows

        // Expected columns based on image:
        // 0: Date/Day (e.g., "1, THU")
        // 1: Hijri Date (e.g., "12")
        // 2: Fajr (e.g., "4:09 | 5:00")
        // 3: Sunrise (e.g., "6:03")
        // 4: Dhuhr (e.g., "1:24 | 2:10")
        // 5: Asr (e.g., "5:17 | 5:45")
        // 6: Maghrib (e.g., "8:45 | 8:55")
        // 7: Isha (e.g., "10:30 | 10:05")

        if (cells.length < 8) continue; // Not a full data row

        final dateStr = cells[0].text.trim(); // "1, THU"
        // Need to determine current year and month.
        // The URL normally gives current month.
        // We might need to assume current month/year or extract from page title/header.
        // For simplicity, let's assume the synced data is for the "current" month being viewed.
        // Or we can try to find the month name in the page.

        // Let's look for the month header

        try {
          // Basic parsing logic
          // Prayer times are in "Azan | Iqamah" format

          final fajrParts = _parseTimeCell(cells[2].text);
          final dhuhrParts = _parseTimeCell(cells[4].text);
          final asrParts = _parseTimeCell(cells[5].text);
          final maghribParts = _parseTimeCell(cells[6].text);
          final ishaParts = _parseTimeCell(cells[7].text);

          // Construct a date.
          // Since the table only gives Day (1, 2, 3...), we need the Month and Year.
          // In a real robust scraper, we'd pull the month/year header.
          // For now, let's use DateTime.now() to get current Month/Year
          // BUT the URL might be for next month if we are near end of month?
          // The user URL is generic `widgets/monthly`, which defaults to current month.
          // So we can use DateTime.now().

          final day = int.parse(dateStr.split(',')[0].trim());
          final now = DateTime.now();
          final date = DateTime(now.year, now.month, day);

          if (date.month != now.month) {
            // If we are iterating and somehow wrap around? Unlikely for one page.
          }

          prayerTimes.add(
            PrayerTime(
              id: 0, // DB will handle ID
              date: date,
              fajr: fajrParts['azan']!,
              fajrIqama: fajrParts['iqama'],
              dhuhr: dhuhrParts['azan']!,
              dhuhrIqama: dhuhrParts['iqama'],
              asr: asrParts['azan']!,
              asrIqama: asrParts['iqama'],
              maghrib: maghribParts['azan']!,
              maghribIqama: maghribParts['iqama'],
              isha: ishaParts['azan']!,
              ishaIqama: ishaParts['iqama'],
            ),
          );
        } catch (e) {
          // Identify parsing errors for specific rows
          print('Error parsing row: $dateStr - $e');
        }
      }

      return prayerTimes;
    } catch (e) {
      throw Exception('Failed to scrap Masjidal: $e');
    }
  }

  // Helper to parse "4:09 | 5:00" -> {azan: "04:09", iqama: "05:00"}
  Map<String, String?> _parseTimeCell(String text) {
    // Text might be "4:09 | 5:00" or just "6:03" (Sunrise)
    // Clean text
    final cleanText = text.trim();
    if (!cleanText.contains('|')) {
      return {'azan': _normalizeTime(cleanText), 'iqama': null};
    }

    final parts = cleanText.split('|');
    return {
      'azan': _normalizeTime(parts[0].trim()),
      'iqama': _normalizeTime(parts[1].trim()),
    };
  }

  // Ensure HH:mm format (e.g., "4:09" -> "04:09")
  String _normalizeTime(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return time; // Fallback

    final hour = parts[0].padLeft(2, '0');
    final minute = parts[1].padLeft(2, '0');
    return '$hour:$minute';
  }
}
