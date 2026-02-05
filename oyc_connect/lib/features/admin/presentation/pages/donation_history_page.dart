import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class DonationHistoryPage extends ConsumerStatefulWidget {
  const DonationHistoryPage({super.key});

  @override
  ConsumerState<DonationHistoryPage> createState() =>
      _DonationHistoryPageState();
}

class _DonationHistoryPageState extends ConsumerState<DonationHistoryPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _donations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDonations();
  }

  Future<void> _fetchDonations() async {
    try {
      // Fetch payments and join with profiles to get user names
      final response = await _supabase
          .from('payments')
          .select('*, profiles:user_id(full_name, email)')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _donations = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching donations: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Donation History",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchDonations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _donations.isEmpty
          ? const Center(child: Text("No donations found."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _donations.length,
              itemBuilder: (context, index) {
                final donation = _donations[index];
                final amount = donation['amount'];
                final currency = donation['currency'] ?? 'AUD';
                final date = DateTime.parse(donation['created_at']);
                final formattedDate = DateFormat(
                  'MMM d, yyyy h:mm a',
                ).format(date);

                // Extract profile info safely
                final profile = donation['profiles'] as Map<String, dynamic>?;
                final donorName = profile?['full_name'] ?? 'Anonymous';
                final donorEmail = profile?['email'] ?? 'No Email';

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green[100],
                      child: const Icon(
                        Icons.attach_money,
                        color: Colors.green,
                      ),
                    ),
                    title: Text(
                      donorName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(donorEmail),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    trailing: Text(
                      '\$${amount.toString()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
