import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:timezone/timezone.dart' as tz;
import '../../../../core/theme/app_theme.dart';
import '../../../../features/prayer_times/data/models/prayer_time_model.dart';
import '../../../../features/prayer_times/presentation/providers/prayer_times_provider.dart';

class ManagePrayerTimesPage extends ConsumerStatefulWidget {
  const ManagePrayerTimesPage({super.key});

  @override
  ConsumerState<ManagePrayerTimesPage> createState() =>
      _ManagePrayerTimesPageState();
}

class _ManagePrayerTimesPageState extends ConsumerState<ManagePrayerTimesPage> {
  late DateTime _selectedDate;
  bool _isLoading = false;

  // Controllers
  final _fajrController = TextEditingController();
  final _fajrIqamaController = TextEditingController();
  final _dhuhrController = TextEditingController();
  final _dhuhrIqamaController = TextEditingController();
  final _asrController = TextEditingController();
  final _asrIqamaController = TextEditingController();
  final _maghribController = TextEditingController();
  final _maghribIqamaController = TextEditingController();
  final _ishaController = TextEditingController();
  final _ishaIqamaController = TextEditingController();
  final _jumuahController = TextEditingController();

  @override
  void initState() {
    super.initState();
    try {
      final melbourne = tz.getLocation('Australia/Melbourne');
      _selectedDate = tz.TZDateTime.now(melbourne);
    } catch (e) {
      // Fallback if timezone not found (though initialized in main)
      _selectedDate = DateTime.now();
    }
    _fetchData();
  }

  @override
  void dispose() {
    _fajrController.dispose();
    _fajrIqamaController.dispose();
    _dhuhrController.dispose();
    _dhuhrIqamaController.dispose();
    _asrController.dispose();
    _asrIqamaController.dispose();
    _maghribController.dispose();
    _maghribIqamaController.dispose();
    _ishaController.dispose();
    _ishaIqamaController.dispose();
    _jumuahController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    // We need to fetch data for the selected date specifically
    // Assuming the provider has a method or we use the repo directly for specific date
    // For now, let's assume we can use the repository provider exposed or similar
    // Actually, let's access the repository via the provider used in riverpod

    // We'll read the repository directly here for simplicity as we are managing loading state manually
    try {
      // Note: We need to access the repository.
      // Currently existing provider might be stream based.
      // Let's use the repo provider if available or create a simple one if not.
      // Based on previous steps, we have `prayerTimesRepositoryProvider` (implied or need to import/create)

      // Note: I will use the ref to read the repository.
      // I assume `prayerTimesRepositoryProvider` exists in `prayer_times_provider.dart`
      // If not, I'll need to fix imports later.

      final repo = ref.read(prayerTimesRepositoryProvider);
      final data = await repo.getPrayerTimes(_selectedDate);

      if (data != null) {
        _fajrController.text = data.fajr;
        _fajrIqamaController.text = data.fajrIqama ?? '';
        _dhuhrController.text = data.dhuhr;
        _dhuhrIqamaController.text = data.dhuhrIqama ?? '';
        _asrController.text = data.asr;
        _asrIqamaController.text = data.asrIqama ?? '';
        _maghribController.text = data.maghrib;
        _maghribIqamaController.text = data.maghribIqama ?? '';
        _ishaController.text = data.isha;
        _ishaIqamaController.text = data.ishaIqama ?? '';
        _jumuahController.text = data.jumuah ?? '';
      } else {
        _clearFields();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearFields() {
    _fajrController.clear();
    _fajrIqamaController.clear();
    _dhuhrController.clear();
    _dhuhrIqamaController.clear();
    _asrController.clear();
    _asrIqamaController.clear();
    _maghribController.clear();
    _maghribIqamaController.clear();
    _ishaController.clear();
    _ishaIqamaController.clear();
    _jumuahController.clear();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(prayerTimesRepositoryProvider);

      final newTime = PrayerTime(
        id: 0, // 0 will be removed in repo logic or ignored by upsert/conflict
        date: _selectedDate,
        fajr: _fajrController.text.trim(),
        fajrIqama: _fajrIqamaController.text.trim(),
        dhuhr: _dhuhrController.text.trim(),
        dhuhrIqama: _dhuhrIqamaController.text.trim(),
        asr: _asrController.text.trim(),
        asrIqama: _asrIqamaController.text.trim(),
        maghrib: _maghribController.text.trim(),
        maghribIqama: _maghribIqamaController.text.trim(),
        isha: _ishaController.text.trim(),
        ishaIqama: _ishaIqamaController.text.trim(),
        jumuah: _jumuahController.text.trim(),
      );

      await repo.upsertPrayerTimes(newTime);

      // Force refresh of the home page provider
      ref.invalidate(todayPrayerTimeProvider);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchData();
    }
  }

  Future<void> _syncFromMasjidal() async {
    setState(() => _isLoading = true);
    try {
      // 0-indexed month (0=Jan, 11=Dec) as per widget API
      final year = _selectedDate.year;
      final monthIndex = _selectedDate.month - 1;
      final monthStr = monthIndex.toString().padLeft(2, '0');

      final url = Uri.parse(
        'https://timing.athanplus.com/masjid/widgets/monthly?theme=3&masjid_id=keLQajLM&action=next&date=$year-$monthStr-01',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load page: ${response.statusCode}');
      }

      final document = parser.parse(response.body);
      final rows = document.querySelectorAll('#time-table3 tr');

      final repo = ref.read(prayerTimesRepositoryProvider);

      // Use the selected date year/month directly
      final targetYear = _selectedDate.year;
      final targetMonth = _selectedDate.month;

      int count = 0;

      for (var row in rows) {
        final cells = row.querySelectorAll('.regCell');
        // We expect: Date, Islamic Date, Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha
        // Index: 0=Date, 1=Islamic, 2=Fajr, 3=Sunrise, 4=Dhuhr, 5=Asr, 6=Maghrib, 7=Isha
        if (cells.length < 8) continue;

        final dayText = cells[0].text
            .trim()
            .split(',')
            .first
            .trim(); // "1, THU" -> "1"
        final day = int.tryParse(dayText);

        if (day == null) continue;

        final date = DateTime(targetYear, targetMonth, day);

        // Helper to parse "4:09 | 5:00" -> Adhan, Iqamah
        // Also handling AM/PM rule.
        // Fajr: AM
        // Sunrise: AM
        // Dhuhr: PM (Need to check if 11am, usually PM except early)
        // Asr, Maghrib, Isha: PM

        String parseAdhan(String text, {required bool isAm}) {
          final time = text.split('|').first.trim();
          return _formatTime(time, isAm: isAm);
        }

        String parseIqamah(String text, {required bool isAm}) {
          final parts = text.split('|');
          if (parts.length < 2) return '';
          final time = parts.last.trim();
          // Sometimes iqamah is empty or bolded
          return _formatTime(time, isAm: isAm);
        }

        final fajrText = cells[2].text.trim();

        final dhuhrText = cells[4].text.trim();
        final asrText = cells[5].text.trim();
        final maghribText = cells[6].text.trim();
        final ishaText = cells[7].text.trim();

        final prayerTime = PrayerTime(
          id: 0,
          date: date,
          fajr: parseAdhan(fajrText, isAm: true),
          fajrIqama: parseIqamah(fajrText, isAm: true),
          dhuhr: parseAdhan(dhuhrText, isAm: false), // Mostly PM
          dhuhrIqama: parseIqamah(dhuhrText, isAm: false),
          asr: parseAdhan(asrText, isAm: false),
          asrIqama: parseIqamah(asrText, isAm: false),
          maghrib: parseAdhan(maghribText, isAm: false),
          maghribIqama: parseIqamah(maghribText, isAm: false),
          isha: parseAdhan(ishaText, isAm: false),
          ishaIqama: parseIqamah(ishaText, isAm: false),
          jumuah: "1:00 PM", // Default or fetch if available
        );

        await repo.upsertPrayerTimes(prayerTime);
        count++;
      }

      // Force refresh of the home page provider
      ref.invalidate(todayPrayerTimeProvider);

      if (mounted) {
        final dateStr = DateFormat('MMMM yyyy').format(_selectedDate);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Synced $count days for $dateStr successfully from Masjidal',
            ),
          ),
        );
        _fetchData(); // Refresh current view
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTime(String raw, {required bool isAm}) {
    if (raw.isEmpty) return '';
    // cleanup spaces, newlines, bold tags if any remaining (parser handles tags mostly)
    String clean = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) return '';

    // Check if aleady has AM/PM
    if (clean.toUpperCase().contains('AM') ||
        clean.toUpperCase().contains('PM')) {
      return clean;
    }

    return '$clean ${isAm ? "AM" : "PM"}';
  }

  Future<void> _pickTime(TextEditingController controller) async {
    // Parse initial time from controller if possible, else use current time
    TimeOfDay initialTime = TimeOfDay.now();
    if (controller.text.isNotEmpty) {
      try {
        final format = DateFormat.jm(); // "5:08 PM"
        final dt = format.parse(controller.text);
        initialTime = TimeOfDay.fromDateTime(dt);
      } catch (_) {}
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: AppTheme.lightTheme.copyWith(
            timePickerTheme: const TimePickerThemeData(
              dialHandColor: Color(0xFF1B5E20),
              dialBackgroundColor: Color(0xFFE8F5E9),
            ),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1B5E20), // Header text color
              onSurface: Colors.black, // Body text color
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Format back to string
      final localizations = MaterialLocalizations.of(context);
      final formattedTime = localizations.formatTimeOfDay(
        picked,
        alwaysUse24HourFormat: false,
      );
      controller.text = formattedTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Prayer Times"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selectDate,
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync from Masjidal',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sync from Masjidal?'),
                  content: const Text(
                    'This will fetch the latest monthly data from Masjidal.com and overwrite existing database entries for this month. Continue?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCEL'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _syncFromMasjidal();
                      },
                      child: const Text('SYNC'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildRow("Fajr", _fajrController, _fajrIqamaController),
                  _buildRow("Dhuhr", _dhuhrController, _dhuhrIqamaController),
                  _buildRow("Asr", _asrController, _asrIqamaController),
                  _buildRow(
                    "Maghrib",
                    _maghribController,
                    _maghribIqamaController,
                  ),
                  _buildRow("Isha", _ishaController, _ishaIqamaController),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _jumuahController,
                    readOnly: true,
                    onTap: () => _pickTime(_jumuahController),
                    decoration: const InputDecoration(
                      labelText: "Jumuah Time (Optional)",
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("SAVE CHANGES"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRow(
    String label,
    TextEditingController azanCtrl,
    TextEditingController iqamaCtrl,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: TextField(
              controller: azanCtrl,
              readOnly: true,
              onTap: () => _pickTime(azanCtrl),
              decoration: const InputDecoration(
                labelText: "Azan",
                isDense: true,
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: iqamaCtrl,
              readOnly: true,
              onTap: () => _pickTime(iqamaCtrl),
              decoration: const InputDecoration(
                labelText: "Iqamah",
                isDense: true,
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
