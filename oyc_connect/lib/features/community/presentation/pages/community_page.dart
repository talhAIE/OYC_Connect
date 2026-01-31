import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/community_providers.dart';
import '../../data/models/event_model.dart';
import '../../data/models/announcement_model.dart';

class CommunityPage extends ConsumerStatefulWidget {
  const CommunityPage({super.key});

  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage> {
  int _selectedIndex = 0; // 0 for Events, 1 for Notices

  // Professional Mosque Theme Colors
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color primaryGreen = Color(0xFF006D5B);
  static const Color featuredGreen = Color(0xFF00B167);
  static const Color labelGrey = Color(0xFF94A3B8);
  static const Color borderSlate = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 25),
            _buildAnimatedSegmentControl(),
            const SizedBox(height: 25),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _selectedIndex == 0
                    ? const _EventsList(key: ValueKey(0))
                    : const _NoticesList(key: ValueKey(1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Text(
        'Discover Hub',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: primaryNavy,
          letterSpacing: -1.0,
        ),
      ),
    );
  }

  Widget _buildAnimatedSegmentControl() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 60,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 245, 245, 245),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // The Animated Sliding Background Pill
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: _selectedIndex == 0
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.42,
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          // The clickable labels
          Row(
            children: [
              _buildTabLabel("EVENTS", 0),
              _buildTabLabel("NOTICES", 1),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabLabel(String label, int index) {
    bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selectedIndex = index),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isSelected ? primaryGreen : Colors.black.withAlpha(165),
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _EventsList extends ConsumerWidget {
  const _EventsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return const Center(child: Text("No upcoming events."));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: events.length,
          itemBuilder: (context, index) => _EventCard(event: events[index]),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: _CommunityPageState.primaryGreen,
        ),
      ),
      error: (err, stack) => Center(child: Text('Sync Error: $err')),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        // Thin Highlight Border as requested
        border: Border.all(
          color: const Color.fromARGB(255, 171, 172, 173),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Professional soft shadow
            blurRadius: 20,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with Featured Badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(33.5),
                ),
                child: Image.network(
                  event.imageUrl ??
                      "https://ghrwefeyeyolszbgeqvc.supabase.co/storage/v1/object/public/app_assets/defaultoycimage.jpg",
                  height: 170,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              if (event.isFeatured)
                Positioned(
                  bottom: 15,
                  left: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _CommunityPageState.featuredGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "FEATURED",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Metadata Details Section
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _CommunityPageState.primaryNavy,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildMeta(
                      Icons.calendar_today_rounded,
                      "DATE",
                      DateFormat('MMM dd').format(event.eventDate),
                    ),
                    const SizedBox(width: 40),
                    _buildMeta(
                      Icons.access_time_rounded,
                      "TIME",
                      DateFormat('hh:mm a').format(event.eventDate),
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

  Widget _buildMeta(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _CommunityPageState.primaryGreen),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.black.withAlpha(165),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: Colors.black.withAlpha(165),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NoticesList extends ConsumerWidget {
  const _NoticesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);

    return announcementsAsync.when(
      data: (notices) {
        if (notices.isEmpty) {
          return const Center(child: Text("No notices."));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: notices.length,
          itemBuilder: (context, index) => _NoticeCard(notice: notices[index]),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: _CommunityPageState.primaryGreen,
        ),
      ),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final Announcement notice;
  const _NoticeCard({required this.notice});

  // Displays the detailed view of the notice in a popup
  void _showNoticeDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "NOTICE DETAIL",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: _CommunityPageState.primaryGreen,
                      letterSpacing: 1,
                    ),
                  ),
                  if (notice.isUrgent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 236, 8, 19),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "URGENT",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                notice.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "${DateFormat('MMM dd, yyyy').format(notice.createdAt)} at ${DateFormat('hh:mm a').format(notice.createdAt)}",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withAlpha(165),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Divider(height: 40, color: Color(0xFFF1F5F9)),
              Text(
                notice.content,
                style: TextStyle(
                  color: Colors.black.withAlpha(165),
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 236, 236, 236),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "CLOSE",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        // If urgent, show a thin colored border
        border: notice.isUrgent
            ? Border.all(
                color: const Color.fromARGB(45, 18, 165, 18).withOpacity(0.8),
                width: 1.5,
              )
            : Border.all(
                color: const Color.fromARGB(255, 225, 225, 226),
                width: 1.5,
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: notice.isUrgent
                      ? const Color(0xFFE6F7EF)
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: notice.isUrgent
                      ? _CommunityPageState.featuredGreen
                      : _CommunityPageState.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notice.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (notice.isUrgent)
                          const Icon(
                            Icons.warning_rounded,
                            color: _CommunityPageState.featuredGreen,
                            size: 26,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(notice.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withAlpha(165),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            notice.content,
            style: TextStyle(
              color: Colors.black.withAlpha(195),
              fontSize: 14,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showNoticeDetails(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 238, 237, 237),
                foregroundColor: _CommunityPageState.primaryGreen,
                elevation: 0,
                side: const BorderSide(
                  color: Color.fromARGB(255, 235, 236, 236),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                "VIEW DETAIL",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
