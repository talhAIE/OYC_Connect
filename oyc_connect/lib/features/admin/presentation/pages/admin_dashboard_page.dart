import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Admin Console",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildAdminTile(
              context,
              title: "Manage Prayer Times",
              subtitle: "Update Azan and Iqamah times",
              icon: Icons.access_time_filled,
              color: Colors.orange,
              onTap: () {
                context.push('/profile/admin/prayer-times');
              },
            ),
            const SizedBox(height: 16),
            _buildAdminTile(
              context,
              title: "Manage Events",
              subtitle: "Add or remove community events",
              icon: Icons.event,
              color: Colors.blue,
              onTap: () {
                context.push('/profile/admin/events');
              },
            ),
            const SizedBox(height: 16),
            _buildAdminTile(
              context,
              title: "Manage Announcements",
              subtitle: "Post updates to the notice board",
              icon: Icons.campaign,
              color: Colors.red,
              onTap: () {
                context.push('/profile/admin/announcements');
              },
            ),
            const SizedBox(height: 16),
            _buildAdminTile(
              context,
              title: "Manage Jummah Settings",
              subtitle: "Update Khutbah time and Friday details",
              icon: Icons.mosque,
              color: Colors.teal,
              onTap: () {
                context.push('/profile/admin/jummah-settings');
              },
            ),

            const SizedBox(height: 16),
            const SizedBox(height: 16),
            _buildAdminTile(
              context,
              title: "Manage Weekly Classes",
              subtitle: "Update classes, teachers & schedules",
              icon: Icons.school,
              color: Colors.purple,
              onTap: () {
                context.push('/profile/admin/schedule');
              },
            ),
            const SizedBox(height: 16),
            _buildAdminTile(
              context,
              title: "Donation History",
              subtitle: "View all member donations",
              icon: Icons.attach_money,
              color: Colors.green,
              onTap: () {
                context.push('/profile/admin/donations');
              },
            ),
            const SizedBox(height: 100), // Padding to clear floating nav bar
          ],
        ),
      ),
    );
  }

  Widget _buildAdminTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}
