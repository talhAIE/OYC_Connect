import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/supabase_constants.dart';
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

  void _showEventDetails(BuildContext context) {
    final maxDialogHeight = MediaQuery.of(context).size.height * 0.88;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxDialogHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button (fixed at top)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, right: 12),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.close, color: Colors.black),
                    ),
                    style: IconButton.styleFrom(
                      elevation: 2,
                      shadowColor: Colors.black26,
                    ),
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image: show completely (any size) with contain, max height
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxHeight: 360),
                          color: Colors.grey[200],
                          child: Image.network(
                            event.imageUrl?.isNotEmpty == true
                                ? event.imageUrl!
                                : SupabaseConstants.defaultEventImageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _eventImagePlaceholder(200),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date & Time Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.calendar_today_rounded,
                              size: 20,
                              color: _CommunityPageState.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "DATE",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black.withAlpha(150),
                                ),
                              ),
                              Text(
                                DateFormat('MMM dd, yyyy').format(event.eventDate),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.access_time_rounded,
                              size: 20,
                              color: _CommunityPageState.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "TIME",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black.withAlpha(150),
                                ),
                              ),
                              Text(
                                DateFormat('hh:mm a').format(event.eventDate),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const Divider(height: 32, color: Color(0xFFE2E8F0)),

                      const Text(
                        "About Event",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        event.description ?? "No description available.",
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.black.withAlpha(230),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _CommunityPageState.primaryNavy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showEventDetails(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          border: Border.all(
            color: const Color.fromARGB(255, 171, 172, 173),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
                    event.imageUrl?.isNotEmpty == true
                        ? event.imageUrl!
                        : SupabaseConstants.defaultEventImageUrl,
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _eventImagePlaceholder(170),
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
                  const SizedBox(height: 16),
                  const Text(
                    "Tap for details",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _CommunityPageState.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

  // Displays the detailed view of the notice in a scrollable dialog (image + full description).
  void _showNoticeDetails(BuildContext context) {
    final maxDialogHeight = MediaQuery.of(context).size.height * 0.88;
    final imageUrl = notice.imageUrl?.isNotEmpty == true
        ? notice.imageUrl!
        : SupabaseConstants.defaultAnnouncementImageUrl;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxDialogHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, right: 12),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.close, color: Colors.black),
                    ),
                    style: IconButton.styleFrom(
                      elevation: 2,
                      shadowColor: Colors.black26,
                    ),
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image: full visibility, any size (BoxFit.contain, max height)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxHeight: 360),
                          color: Colors.grey[200],
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                _eventImagePlaceholder(200),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
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
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (notice.isUrgent) const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "NOTICE",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: _CommunityPageState.primaryGreen,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        notice.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
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
                      const Divider(height: 32, color: Color(0xFFE2E8F0)),
                      const Text(
                        "Description",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        notice.content,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.black.withAlpha(230),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _CommunityPageState.primaryNavy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
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
              _buildNoticeLeading(notice),
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

  Widget _buildNoticeLeading(Announcement notice) {
    final hasImage =
        notice.imageUrl != null && notice.imageUrl!.isNotEmpty;
    if (hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          notice.imageUrl!,
          height: 56,
          width: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _noticeIconContainer(notice),
        ),
      );
    }
    return _noticeIconContainer(notice);
  }

  Widget _noticeIconContainer(Announcement notice) {
    return Container(
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
    );
  }
}

Widget _eventImagePlaceholder(double height) {
  return Container(
    height: height,
    width: double.infinity,
    color: Colors.grey[300],
    child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
  );
}
